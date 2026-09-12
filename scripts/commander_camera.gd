extends Camera3D

const PAN_SPEED := 40.0
const ZOOM_STEP := 4.0
const MIN_HEIGHT := 10.0
const MAX_HEIGHT := 100.0

var active := false
var selected_worker: Node = null
var selected_building: Node = null

var placing_scene: PackedScene = null
var placing_wood_cost: int = 0
var placing_red_stone_cost: int = 0
var ghost: Node3D = null

var pending_command: String = ""


func _ready() -> void:
	GameState.commander_camera = self
	EventBus.view_mode_changed.connect(_on_view_mode_changed)
	_on_view_mode_changed(GameState.view_mode)


func _on_view_mode_changed(mode: int) -> void:
	active = mode == GameState.ViewMode.COMMANDER
	current = active
	set_process(active)


func _process(delta: float) -> void:
	var pan := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		pan.y -= 1
	if Input.is_action_pressed("move_back"):
		pan.y += 1
	if Input.is_action_pressed("move_left"):
		pan.x -= 1
	if Input.is_action_pressed("move_right"):
		pan.x += 1
	if pan != Vector2.ZERO:
		position += Vector3(pan.x, 0, pan.y).normalized() * PAN_SPEED * delta
	if ghost != null:
		_update_ghost_position()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if ghost != null:
		if event.is_action_pressed("primary_action"):
			_confirm_placement()
		elif event.is_action_pressed("secondary_action") or event.is_action_pressed("ui_cancel"):
			_cancel_placement()
		return
	if pending_command != "":
		if event.is_action_pressed("primary_action"):
			_execute_pending_command(get_viewport().get_mouse_position())
		elif event.is_action_pressed("secondary_action") or event.is_action_pressed("ui_cancel"):
			pending_command = ""
		return
	if event.is_action_pressed("primary_action"):
		_select_at(get_viewport().get_mouse_position())
	elif event.is_action_pressed("secondary_action"):
		_command_at(get_viewport().get_mouse_position())
	elif event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			position.y = clampf(position.y - ZOOM_STEP, MIN_HEIGHT, MAX_HEIGHT)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			position.y = clampf(position.y + ZOOM_STEP, MIN_HEIGHT, MAX_HEIGHT)


func start_placement(scene: PackedScene, wood_cost: int, red_stone_cost: int) -> void:
	_cancel_placement()
	placing_scene = scene
	placing_wood_cost = wood_cost
	placing_red_stone_cost = red_stone_cost
	ghost = scene.instantiate()
	if ghost is CollisionObject3D:
		ghost.collision_layer = 0
		ghost.collision_mask = 0
	_make_ghost_transparent(ghost)
	get_tree().current_scene.add_child(ghost)


func _make_ghost_transparent(node: Node) -> void:
	if node is MeshInstance3D:
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.3, 1.0, 0.3, 0.5)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node.material_override = material
	for child in node.get_children():
		_make_ghost_transparent(child)


func _update_ghost_position() -> void:
	var result := _raycast(get_viewport().get_mouse_position())
	if result.has("position"):
		ghost.global_position = result["position"]


func _confirm_placement() -> void:
	if GameState.wood < placing_wood_cost or GameState.red_stone < placing_red_stone_cost:
		return
	GameState.spend_resources(placing_wood_cost, placing_red_stone_cost)
	var building := placing_scene.instantiate()
	get_tree().current_scene.add_child(building)
	building.global_position = ghost.global_position
	_cancel_placement()


func _cancel_placement() -> void:
	if ghost != null:
		ghost.queue_free()
		ghost = null
	placing_scene = null


func _raycast(screen_pos: Vector2) -> Dictionary:
	var from := project_ray_origin(screen_pos)
	var to := from + project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _select_at(screen_pos: Vector2) -> void:
	var result := _raycast(screen_pos)
	var hit: Object = result.get("collider")
	if hit != null and hit.is_in_group("player_workers"):
		_set_selected(hit)
		_set_selected_building(null)
	elif hit != null and hit.is_in_group("tech_buildings"):
		_set_selected(null)
		_set_selected_building(hit)
	else:
		_set_selected(null)
		_set_selected_building(null)


func _command_at(screen_pos: Vector2) -> void:
	if not is_instance_valid(selected_worker):
		return
	var result := _raycast(screen_pos)
	if result.is_empty():
		return
	var collider: Object = result["collider"]
	if collider.is_in_group("resource_nodes"):
		selected_worker.command_gather(collider)
	else:
		selected_worker.command_move(result["position"])


func arm_move_command() -> void:
	if is_instance_valid(selected_worker):
		pending_command = "move"


func command_gather_nearest(resource_type: String) -> bool:
	if not is_instance_valid(selected_worker):
		return false
	var closest: Node = null
	var closest_distance := INF
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if node.resource_type != resource_type:
			continue
		var distance: float = selected_worker.global_position.distance_to(node.global_position)
		if distance < closest_distance:
			closest = node
			closest_distance = distance
	if closest == null:
		return false
	selected_worker.command_gather(closest)
	return true


func _execute_pending_command(screen_pos: Vector2) -> void:
	var command := pending_command
	pending_command = ""
	if not is_instance_valid(selected_worker):
		return
	if command == "move":
		var result := _raycast(screen_pos)
		if result.has("position"):
			selected_worker.command_move(result["position"])


func _set_selected(worker: Object) -> void:
	if selected_worker == worker:
		return
	if is_instance_valid(selected_worker):
		selected_worker.set_selected(false)
	selected_worker = worker
	if is_instance_valid(selected_worker):
		selected_worker.set_selected(true)
	EventBus.worker_selected.emit(selected_worker)


func _set_selected_building(building: Object) -> void:
	if selected_building == building:
		return
	selected_building = building
	EventBus.building_selected.emit(building)
