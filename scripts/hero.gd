extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.003
const PITCH_LIMIT := deg_to_rad(80)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_first: Camera3D = $CameraPivot/Camera3DFirst
@onready var camera_third: Camera3D = $CameraPivot/Camera3DThird

var active := false
var first_person := false


func _ready() -> void:
	GameState.hero = self
	EventBus.view_mode_changed.connect(_on_view_mode_changed)
	_on_view_mode_changed(GameState.view_mode)


func _on_view_mode_changed(mode: int) -> void:
	active = mode == GameState.ViewMode.HERO
	set_physics_process(active)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, -PITCH_LIMIT, PITCH_LIMIT)
	elif event.is_action_pressed("toggle_camera"):
		first_person = not first_person
		_update_camera()


func _update_camera() -> void:
	camera_first.current = active and first_person
	camera_third.current = active and not first_person


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
