extends SceneTree

# One-off asset pipeline tool, not gameplay code.
#
# Meshy exports each animation as its own FBX (same skeleton, full duplicate
# mesh). Godot's project scan already imports each of those as its own scene.
# This tool pulls just the Animation resource out of every FBX in a
# character's animations/ folder, merges them into one AnimationLibrary under
# clean names (the FBX's filename), and rebuilds <character>.tscn from the
# base mesh with an AnimationPlayer carrying that library.
#
# Meshy's base character export and its per-animation exports don't
# necessarily use the same name for the node that holds the Skeleton3D (e.g.
# "Armature" in the base export vs "target_character" in animation exports),
# even though the bone names inside the skeleton match. Every extracted
# track's NodePath is rewritten to point at wherever the base scene's actual
# Skeleton3D lives, rather than trusting the original path.
#
# Usage (from the project root, after Godot has imported the new files via
# `godot --headless --editor --quit`):
#   godot --headless --script res://tools/build_character.gd -- <character_folder_name>


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("Usage: godot --headless --script res://tools/build_character.gd -- <character_folder_name>")
		quit(1)
		return

	var character_name: String = args[0]
	var base_dir := "res://assets/characters/%s" % character_name
	var anim_dir := "%s/animations" % base_dir
	var base_fbx_path := "%s/%s_base.fbx" % [base_dir, character_name]

	if not DirAccess.dir_exists_absolute(base_dir):
		printerr("No such character folder: ", base_dir)
		quit(1)
		return
	if not FileAccess.file_exists(base_fbx_path):
		printerr("No base mesh at ", base_fbx_path)
		quit(1)
		return

	var base_packed: PackedScene = load(base_fbx_path)
	var base_instance := base_packed.instantiate()

	var skeleton := _find_skeleton(base_instance)
	if skeleton == null:
		printerr("No Skeleton3D found in ", base_fbx_path)
		base_instance.free()
		quit(1)
		return
	var skeleton_path := base_instance.get_path_to(skeleton)

	var library := _build_animation_library(anim_dir, skeleton_path)
	if library.get_animation_list().is_empty():
		printerr("No animations found in ", anim_dir)
		base_instance.free()
		quit(1)
		return

	var library_path := "%s/%s_animations.tres" % [base_dir, character_name]
	var save_err := ResourceSaver.save(library, library_path)
	if save_err != OK:
		printerr("Failed to save animation library: ", save_err)
		base_instance.free()
		quit(1)
		return
	print("Saved animation library (%d clips) to %s" % [library.get_animation_list().size(), library_path])

	_build_character_scene(character_name, base_dir, base_instance, library)
	quit(0)


func _build_animation_library(anim_dir: String, skeleton_path: NodePath) -> AnimationLibrary:
	var library := AnimationLibrary.new()
	var dir := DirAccess.open(anim_dir)
	if dir == null:
		return library

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension().to_lower() == "fbx":
			var clip_name := file_name.get_basename()
			var anim := _extract_animation("%s/%s" % [anim_dir, file_name], skeleton_path)
			if anim != null:
				library.add_animation(clip_name, anim)
				print("Added animation: ", clip_name)
			else:
				printerr("Could not extract an animation from ", file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return library


func _extract_animation(fbx_path: String, skeleton_path: NodePath) -> Animation:
	var packed: PackedScene = load(fbx_path)
	if packed == null:
		return null
	var instance := packed.instantiate()
	var player := _find_animation_player(instance)
	if player == null:
		instance.free()
		return null
	var anim_list := player.get_animation_list()
	if anim_list.is_empty():
		instance.free()
		return null

	# Some exports (seen on custom/prompted animations, not the preset
	# library ones) bundle a trivial single-frame bind pose alongside the
	# real motion. Picking the longest clip sidesteps that reliably instead
	# of trusting clip order or naming.
	var longest_name: String = anim_list[0]
	for anim_name in anim_list:
		if player.get_animation(anim_name).length > player.get_animation(longest_name).length:
			longest_name = anim_name

	var anim: Animation = player.get_animation(longest_name).duplicate()
	instance.free()
	_retarget_skeleton_tracks(anim, skeleton_path)
	return anim


func _retarget_skeleton_tracks(anim: Animation, skeleton_path: NodePath) -> void:
	for i in anim.get_track_count():
		var old_path := anim.track_get_path(i)
		var name_count := old_path.get_name_count()
		if name_count == 0 or old_path.get_name(name_count - 1) != "Skeleton3D":
			continue
		var subnames := old_path.get_concatenated_subnames()
		var new_path := NodePath(str(skeleton_path) + (":" + subnames if subnames != "" else ""))
		anim.track_set_path(i, new_path)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result != null:
			return result
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result != null:
			return result
	return null


func _build_character_scene(character_name: String, base_dir: String, base_instance: Node, library: AnimationLibrary) -> void:
	# Meshy's base export already ships its own AnimationPlayer with a
	# trivial default clip (a single-frame bind pose) - reuse that node
	# instead of adding a second, sibling AnimationPlayer.
	var animation_player := _find_animation_player(base_instance)
	if animation_player == null:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		base_instance.add_child(animation_player)
		animation_player.owner = base_instance
	else:
		for existing_library_name in animation_player.get_animation_library_list():
			animation_player.remove_animation_library(existing_library_name)

	animation_player.add_animation_library("", library)

	var output_scene := PackedScene.new()
	var pack_err := output_scene.pack(base_instance)
	base_instance.free()
	if pack_err != OK:
		printerr("Failed to pack character scene: ", pack_err)
		return

	var output_path := "%s/%s.tscn" % [base_dir, character_name]
	var save_err := ResourceSaver.save(output_scene, output_path)
	if save_err != OK:
		printerr("Failed to save character scene: ", save_err)
	else:
		print("Saved character scene to ", output_path)
