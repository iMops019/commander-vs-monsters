extends CharacterBody3D

enum State { GUARDING, CHASING, ATTACKING, RETURNING }

const SPEED := 3.5
const ARRIVE_DISTANCE := 1.2
const AGGRO_RANGE := 8.0
const ATTACK_RANGE := 1.8
const ATTACK_DAMAGE := 10
const ATTACK_COOLDOWN := 1.0
const LEASH_RANGE := 14.0

@onready var health: Health = $Health
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var commander: Node = null
var guard_position: Vector3
var attack_timer := 0.0
var state: State = State.GUARDING


func _ready() -> void:
	add_to_group("hostile")
	guard_position = global_position
	health.died.connect(_on_died)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.5, 0.15)
	mesh_instance.material_override = material


func setup(monster_commander: Node) -> void:
	commander = monster_commander


func _on_died() -> void:
	GameState.add_hero_xp(20)
	GameState.add_resource("gold", 10)
	queue_free()


func _physics_process(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	var hero: Node3D = GameState.hero

	match state:
		State.GUARDING:
			velocity.x = 0
			velocity.z = 0
			if _hero_in_range(hero, AGGRO_RANGE):
				state = State.CHASING
		State.CHASING:
			if not _hero_valid(hero) or global_position.distance_to(guard_position) > LEASH_RANGE:
				state = State.RETURNING
			else:
				_move_toward(hero.global_position, delta)
				if global_position.distance_to(hero.global_position) <= ATTACK_RANGE:
					state = State.ATTACKING
		State.ATTACKING:
			velocity.x = 0
			velocity.z = 0
			if not _hero_valid(hero) or global_position.distance_to(hero.global_position) > ATTACK_RANGE * 1.5:
				state = State.CHASING
			elif attack_timer <= 0.0:
				attack_timer = ATTACK_COOLDOWN
				var damage := ATTACK_DAMAGE
				if commander != null and is_instance_valid(commander):
					damage = int(damage * commander.defender_damage_multiplier)
				hero.health.apply_damage(damage)
		State.RETURNING:
			_move_toward(guard_position, delta)
			if global_position.distance_to(guard_position) <= ARRIVE_DISTANCE:
				velocity.x = 0
				velocity.z = 0
				state = State.GUARDING

	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	move_and_slide()


func _hero_valid(hero) -> bool:
	return hero != null and is_instance_valid(hero) and hero.health.current > 0


func _hero_in_range(hero, aggro_range: float) -> bool:
	return _hero_valid(hero) and global_position.distance_to(hero.global_position) <= aggro_range


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
