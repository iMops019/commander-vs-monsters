extends Camera3D

const PAN_SPEED := 12.0
const ZOOM_STEP := 1.5
const MIN_HEIGHT := 6.0
const MAX_HEIGHT := 30.0

var active := false


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
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			position.y = clampf(position.y - ZOOM_STEP, MIN_HEIGHT, MAX_HEIGHT)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			position.y = clampf(position.y + ZOOM_STEP, MIN_HEIGHT, MAX_HEIGHT)
