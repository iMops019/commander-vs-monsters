extends StaticBody3D

@export var display_name: String = "Tech Building"
@export var wood_cost: int = 30
@export var red_stone_cost: int = 40

const UPGRADES := {
	"worker_speed": {"wood": 20, "red_stone": 10, "time": 4.0},
	"tower_damage": {"wood": 15, "red_stone": 25, "time": 4.0},
}

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var upgrade_in_progress: String = ""
var upgrade_timer: float = 0.0


func _ready() -> void:
	add_to_group("buildings")
	add_to_group("tech_buildings")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.25, 0.55)
	mesh_instance.material_override = material


func start_upgrade(upgrade_id: String) -> bool:
	if upgrade_in_progress != "" or not UPGRADES.has(upgrade_id):
		return false
	var data: Dictionary = UPGRADES[upgrade_id]
	if GameState.wood < data["wood"] or GameState.red_stone < data["red_stone"]:
		return false
	GameState.spend_resources(data["wood"], data["red_stone"])
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
