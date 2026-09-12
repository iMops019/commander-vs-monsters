extends Node3D

@export var map_width: float = 70.0
@export var map_length: float = 260.0
@export var wall_height: float = 20.0
@export var wall_thickness: float = 6.0


func _ready() -> void:
	var half_width := map_width / 2.0
	var half_length := map_length / 2.0
	var extended_width := map_width + wall_thickness * 2.0

	_build_wall(Vector3(0, wall_height / 2.0, -half_length - wall_thickness / 2.0), Vector3(extended_width, wall_height, wall_thickness))
	_build_wall(Vector3(0, wall_height / 2.0, half_length + wall_thickness / 2.0), Vector3(extended_width, wall_height, wall_thickness))
	_build_wall(Vector3(-half_width - wall_thickness / 2.0, wall_height / 2.0, 0), Vector3(wall_thickness, wall_height, map_length))
	_build_wall(Vector3(half_width + wall_thickness / 2.0, wall_height / 2.0, 0), Vector3(wall_thickness, wall_height, map_length))


func _build_wall(local_position: Vector3, size: Vector3) -> void:
	var wall := StaticBody3D.new()
	add_child(wall)
	wall.position = local_position

	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.32, 0.28)
	mesh_instance.material_override = material
	wall.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	wall.add_child(collision_shape)
