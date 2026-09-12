extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.003
const PITCH_LIMIT := deg_to_rad(80)
const ATTACK_RANGE := 3.0
const ATTACK_DAMAGE := 15
const ATTACK_COOLDOWN := 0.6

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_first: Camera3D = $CameraPivot/Camera3DFirst
@onready var camera_third: Camera3D = $CameraPivot/Camera3DThird
@onready var health: Health = $Health

var active := false
var first_person := false
var attack_cooldown_remaining := 0.0
var spawn_position: Vector3


func _ready() -> void:
	GameState.hero = self
	spawn_position = global_position
	health.max_health = GameState.hero_max_health
	health.reset()
	health.died.connect(_on_died)
	EventBus.view_mode_changed.connect(_on_view_mode_changed)
	_on_view_mode_changed(GameState.view_mode)


func on_max_health_increased(new_max: int) -> void:
	var gained := new_max - health.max_health
	health.max_health = new_max
	health.heal(gained)


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
	elif event.is_action_pressed("primary_action"):
		_try_attack()


func _update_camera() -> void:
	camera_first.current = active and first_person
	camera_third.current = active and not first_person


func _try_attack() -> void:
	if attack_cooldown_remaining > 0.0:
		return
	attack_cooldown_remaining = ATTACK_COOLDOWN
	var cam := camera_first if first_person else camera_third
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * ATTACK_RANGE
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var collider: Object = result["collider"]
	if collider.is_in_group("hostile"):
		var target_health: Node = collider.get_node_or_null("Health")
		if target_health != null:
			target_health.apply_damage(ATTACK_DAMAGE + GameState.hero_damage_bonus)


func _on_died() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	health.reset()


func _physics_process(delta: float) -> void:
	if attack_cooldown_remaining > 0.0:
		attack_cooldown_remaining -= delta

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
