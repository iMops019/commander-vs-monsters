extends StaticBody3D

const WORKER_SCENE := preload("res://scenes/worker.tscn")
const DEFENDER_SCENE := preload("res://scenes/monster_defender.tscn")
const ATTACKER_SCENE := preload("res://scenes/monster_attacker.tscn")

const DECISION_INTERVAL := 5.0
const WORKER_COST := {"wood": 20, "red_stone": 10}
const DEFENDER_COST := {"wood": 15, "red_stone": 25}
const ATTACKER_COST := {"wood": 25, "red_stone": 15}
const UPGRADE_COST := {"wood": 30, "red_stone": 30}

const MAX_WORKERS := 3
const MAX_DEFENDERS := 3
const MAX_ATTACKERS := 2

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var health: Health = $Health

var wood := 50
var red_stone := 30
var attacker_damage_multiplier := 1.0
var defender_damage_multiplier := 1.0

var workers: Array = []
var defenders: Array = []
var attackers: Array = []

var decision_timer := DECISION_INTERVAL


func _ready() -> void:
	add_to_group("monster_base")
	add_to_group("hostile")
	health.died.connect(_on_died)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.25, 0.05, 0.05)
	mesh_instance.material_override = material


func _on_died() -> void:
	EventBus.game_won.emit()


func deposit(resource_name: String, amount: int) -> void:
	if resource_name == "wood":
		wood += amount
	elif resource_name == "red_stone":
		red_stone += amount


func _process(delta: float) -> void:
	decision_timer -= delta
	if decision_timer <= 0.0:
		decision_timer = DECISION_INTERVAL
		_prune_dead()
		_make_decision()
	_reassign_idle_workers()


func _prune_dead() -> void:
	workers = workers.filter(func(w): return is_instance_valid(w))
	defenders = defenders.filter(func(d): return is_instance_valid(d))
	attackers = attackers.filter(func(a): return is_instance_valid(a))


func _make_decision() -> void:
	if workers.size() < MAX_WORKERS and _can_afford(WORKER_COST):
		_spend(WORKER_COST)
		_spawn_worker()
	elif attackers.size() < MAX_ATTACKERS and _can_afford(ATTACKER_COST):
		_spend(ATTACKER_COST)
		_spawn_attacker()
	elif defenders.size() < MAX_DEFENDERS and _can_afford(DEFENDER_COST):
		_spend(DEFENDER_COST)
		_spawn_defender()
	elif _can_afford(UPGRADE_COST):
		_spend(UPGRADE_COST)
		_apply_random_upgrade()


func _can_afford(cost: Dictionary) -> bool:
	return wood >= cost["wood"] and red_stone >= cost["red_stone"]


func _spend(cost: Dictionary) -> void:
	wood -= cost["wood"]
	red_stone -= cost["red_stone"]


func _apply_random_upgrade() -> void:
	if randi() % 2 == 0:
		attacker_damage_multiplier += 0.2
	else:
		defender_damage_multiplier += 0.2


func _spawn_worker() -> void:
	var worker := WORKER_SCENE.instantiate()
	worker.faction = "monster"
	worker.stockpile = self
	get_tree().current_scene.add_child(worker)
	worker.global_position = global_position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	var target := _pick_resource_node()
	if target != null:
		worker.command_gather(target)
	workers.append(worker)


func _spawn_defender() -> void:
	var defender := DEFENDER_SCENE.instantiate()
	get_tree().current_scene.add_child(defender)
	defender.global_position = global_position + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
	defender.setup(self)
	defenders.append(defender)


func _spawn_attacker() -> void:
	var stockpiles := get_tree().get_nodes_in_group("stockpile")
	if stockpiles.is_empty():
		return
	var attacker := ATTACKER_SCENE.instantiate()
	get_tree().current_scene.add_child(attacker)
	attacker.global_position = global_position
	attacker.setup(stockpiles[0], global_position)
	attackers.append(attacker)


func _pick_resource_node() -> Node:
	var nodes := get_tree().get_nodes_in_group("resource_nodes")
	if nodes.is_empty():
		return null
	var closest: Node = nodes[0]
	var closest_distance := global_position.distance_to(closest.global_position)
	for node in nodes:
		var distance := global_position.distance_to(node.global_position)
		if distance < closest_distance:
			closest = node
			closest_distance = distance
	return closest


func _reassign_idle_workers() -> void:
	for worker in workers:
		if is_instance_valid(worker) and worker.is_idle():
			var target := _pick_resource_node()
			if target != null:
				worker.command_gather(target)
