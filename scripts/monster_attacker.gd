extends CharacterBody3D

enum State { RAIDING, LINGERING, RETURNING }

const SPEED := 4.0
const ARRIVE_DISTANCE := 1.5
const LINGER_TIME := 6.0

@onready var health: Health = $Health
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var raid_target: Node3D = null
var home_position: Vector3
var state: State = State.RAIDING
var linger_timer := 0.0


func _ready() -> void:
	add_to_group("hostile")
	health.died.connect(_on_died)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.05, 0.55)
	mesh_instance.material_override = material


func setup(target: Node3D, home: Vector3) -> void:
	raid_target = target
	home_position = home
	state = State.RAIDING


func _on_died() -> void:
	GameState.add_hero_xp(15)
	GameState.add_resource("gold", 15)
	queue_free()


func _physics_process(delta: float) -> void:
	match state:
		State.RAIDING:
			if not is_instance_valid(raid_target):
				state = State.RETURNING
			else:
				_move_toward(raid_target.global_position, delta)
				if global_position.distance_to(raid_target.global_position) <= ARRIVE_DISTANCE:
					linger_timer = LINGER_TIME
					state = State.LINGERING
		State.LINGERING:
			velocity.x = 0
			velocity.z = 0
			linger_timer -= delta
			if linger_timer <= 0.0:
				state = State.RETURNING
		State.RETURNING:
			_move_toward(home_position, delta)
			if global_position.distance_to(home_position) <= ARRIVE_DISTANCE:
				queue_free()
				return

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	move_and_slide()


func _move_toward(destination: Vector3, _delta: float) -> void:
	var to_target := destination - global_position
	to_target.y = 0
	if to_target.length() > ARRIVE_DISTANCE:
		var direction := to_target.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0
