extends StaticBody3D

@export var display_name: String = "Tower"
@export var wood_cost: int = 40
@export var red_stone_cost: int = 20

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("buildings")
	add_to_group("towers")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.35, 0.4)
	mesh_instance.material_override = material
