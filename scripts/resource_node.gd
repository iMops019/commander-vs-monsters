extends StaticBody3D

@export var resource_type: String = "wood"
@export var amount: int = 500

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("resource_nodes")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.45, 0.28, 0.12) if resource_type == "wood" else Color(0.7, 0.15, 0.15)
	mesh_instance.material_override = material


func harvest(units: int) -> int:
	var taken := mini(units, amount)
	amount -= taken
	if amount <= 0:
		queue_free()
	return taken
