extends StaticBody3D

@export var display_name: String = "Tech Building"
@export var wood_cost: int = 30
@export var red_stone_cost: int = 40

const UPGRADES := {
	"worker_speed": {"wood": 20, "red_stone": 10, "time": 4.0},
	"tower_damage": {"wood": 15, "red_stone": 25, "time": 4.0},
	"hero_damage": {"gold": 30, "time": 3.0},
	"hero_health": {"gold": 30, "time": 3.0},
}

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var health: Health = $Health

var upgrade_in_progress: String = ""
var upgrade_timer: float = 0.0


func _ready() -> void:
	add_to_group("buildings")
	add_to_group("tech_buildings")
	health.died.connect(queue_free)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.25, 0.55)
	mesh_instance.material_override = material


func start_upgrade(upgrade_id: String) -> bool:
	if upgrade_in_progress != "" or not UPGRADES.has(upgrade_id):
		return false
	var data: Dictionary = UPGRADES[upgrade_id]
	var wood_needed: int = data.get("wood", 0)
	var red_stone_needed: int = data.get("red_stone", 0)
	var gold_needed: int = data.get("gold", 0)
	if GameState.wood < wood_needed or GameState.red_stone < red_stone_needed or GameState.gold < gold_needed:
		return false
	GameState.spend_resources(wood_needed, red_stone_needed, gold_needed)
	upgrade_in_progress = upgrade_id
	upgrade_timer = data["time"]
	return true


func _process(delta: float) -> void:
	if upgrade_in_progress == "":
		return
	upgrade_timer -= delta
	if upgrade_timer <= 0.0:
		_apply_upgrade(upgrade_in_progress)
		upgrade_in_progress = ""


func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"worker_speed":
			GameState.increase_worker_speed(0.2)
		"tower_damage":
			GameState.increase_tower_damage(0.25)
		"hero_damage":
			GameState.increase_hero_damage(5)
		"hero_health":
			GameState.increase_hero_max_health(20)
