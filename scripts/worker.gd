extends CharacterBody3D

enum State { IDLE, MOVING, GATHERING, RETURNING }

const SPEED := 3.5
const ARRIVE_DISTANCE := 1.2
const GATHER_INTERVAL := 0.5
const GATHER_AMOUNT := 1
const CARRY_CAPACITY := 10

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var selection_ring: MeshInstance3D = $SelectionRing

var state: State = State.IDLE
var move_target: Vector3
var target_resource: Node = null
var resource_type: String = ""
var carrying: int = 0
var gather_timer: float = 0.0
var stockpile: Node3D = null


func _ready() -> void:
	add_to_group("workers")

	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = Color(0.85, 0.7, 0.1)
	mesh_instance.material_override = body_material

	var ring_material := StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.2, 1.0, 0.3)
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.2, 1.0, 0.3)
	selection_ring.material_override = ring_material

	var stockpiles := get_tree().get_nodes_in_group("stockpile")
	if not stockpiles.is_empty():
		stockpile = stockpiles[0]


func set_selected(value: bool) -> void:
	selection_ring.visible = value


func command_move(destination: Vector3) -> void:
	target_resource = null
	move_target = destination
	state = State.MOVING


func command_gather(node: Node) -> void:
	target_resource = node
	move_target = node.global_position
	state = State.MOVING


func _physics_process(delta: float) -> void:
	match state:
		State.MOVING:
			_move_toward(move_target, delta)
			if global_position.distance_to(move_target) <= ARRIVE_DISTANCE:
				velocity.x = 0
				velocity.z = 0
				if is_instance_valid(target_resource):
					resource_type = target_resource.resource_type
					state = State.GATHERING
					gather_timer = 0.0
				else:
					state = State.IDLE
		State.GATHERING:
			velocity.x = 0
			velocity.z = 0
			if not is_instance_valid(target_resource):
				state = State.RETURNING if carrying > 0 else State.IDLE
			else:
				gather_timer += delta
				if gather_timer >= GATHER_INTERVAL:
					gather_timer = 0.0
					var taken: int = target_resource.harvest(GATHER_AMOUNT)
					carrying += taken
					if taken == 0 or carrying >= CARRY_CAPACITY:
						state = State.RETURNING
		State.RETURNING:
			if stockpile == null:
				state = State.IDLE
			else:
				_move_toward(stockpile.global_position, delta)
				if global_position.distance_to(stockpile.global_position) <= ARRIVE_DISTANCE:
					velocity.x = 0
					velocity.z = 0
					if carrying > 0:
						GameState.add_resource(resource_type, carrying)
						carrying = 0
					if is_instance_valid(target_resource):
						move_target = target_resource.global_position
						state = State.MOVING
					else:
						state = State.IDLE
		State.IDLE:
			velocity.x = 0
			velocity.z = 0

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
		var speed := SPEED * GameState.worker_speed_multiplier
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0
