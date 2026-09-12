extends StaticBody3D

@export var reward_xp: int = 25
@export var reward_gold: int = 10
@export var respawn_time: float = 3.0

@onready var health: Health = $Health
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

var is_down := false
var respawn_timer := 0.0


func _ready() -> void:
	add_to_group("hostile")
	health.died.connect(_on_died)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.1, 0.1)
	mesh_instance.material_override = material


func _on_died() -> void:
	is_down = true
	respawn_timer = respawn_time
	mesh_instance.visible = false
	collision_layer = 0
	collision_mask = 0
	GameState.add_hero_xp(reward_xp)
	GameState.add_resource("gold", reward_gold)


func _process(delta: float) -> void:
	if not is_down:
		return
	respawn_timer -= delta
	if respawn_timer <= 0.0:
		is_down = false
		mesh_instance.visible = true
		collision_layer = 1
		collision_mask = 1
		health.reset()
