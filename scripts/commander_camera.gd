extends Camera3D

const PAN_SPEED := 12.0
const ZOOM_STEP := 1.5
const MIN_HEIGHT := 6.0
const MAX_HEIGHT := 30.0

var active := false
var selected_worker: Node = null


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


func _unhandled_input(event: InputEvent) -> void:
	if not active:
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


func _raycast(screen_pos: Vector2) -> Dictionary:
	var from := project_ray_origin(screen_pos)
	var to := from + project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	return get_world_3d().direct_space_state.intersect_ray(query)


func _select_at(screen_pos: Vector2) -> void:
	var result := _raycast(screen_pos)
	var hit: Object = result.get("collider")
	_set_selected(hit if hit != null and hit.is_in_group("workers") else null)


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


func _set_selected(worker: Object) -> void:
	if selected_worker == worker:
		return
	if is_instance_valid(selected_worker):
		selected_worker.set_selected(false)
	selected_worker = worker
	if is_instance_valid(selected_worker):
		selected_worker.set_selected(true)
