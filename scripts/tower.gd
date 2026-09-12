extends StaticBody3D

@export var display_name: String = "Tower"
@export var wood_cost: int = 40
@export var red_stone_cost: int = 20
@export var attack_range: float = 10.0
@export var damage: int = 8
@export var fire_cooldown: float = 1.0

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var health: Health = $Health
@onready var detection_area: Area3D = $DetectionArea
@onready var detection_shape: CollisionShape3D = $DetectionArea/CollisionShape3D

var targets: Array = []
var fire_timer := 0.0


func _ready() -> void:
	add_to_group("buildings")
	add_to_group("towers")
	health.died.connect(queue_free)

	detection_shape.shape = detection_shape.shape.duplicate()
	detection_shape.shape.radius = attack_range
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.35, 0.4)
	mesh_instance.material_override = material


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("hostile"):
		targets.append(body)


func _on_body_exited(body: Node) -> void:
	targets.erase(body)


func _process(delta: float) -> void:
	fire_timer = maxf(fire_timer - delta, 0.0)
	targets = targets.filter(func(t): return is_instance_valid(t))
	if targets.is_empty() or fire_timer > 0.0:
		return
	var target := _pick_target()
	if target != null:
		fire_timer = fire_cooldown
		_fire_at(target)


func _pick_target() -> Node:
	var closest: Node = null
	var closest_distance := INF
	for target in targets:
		var distance := global_position.distance_to(target.global_position)
		if distance < closest_distance:
			closest = target
			closest_distance = distance
	return closest


func _fire_at(target: Node) -> void:
	var target_health: Node = target.get_node_or_null("Health")
	if target_health != null:
		target_health.apply_damage(int(damage * GameState.tower_damage_multiplier))
	_show_tracer(target.global_position)


func _show_tracer(target_position: Vector3) -> void:
	var from := mesh_instance.global_position + Vector3(0, 1.0, 0)
	var to := target_position + Vector3(0, 1.0, 0)
	var distance := from.distance_to(to)
	if distance < 0.01:
		return

	var tracer := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.05
	cylinder.bottom_radius = 0.05
	cylinder.height = distance
	tracer.mesh = cylinder

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.3, 0.1)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.3, 0.1)
	tracer.material_override = material

	get_tree().current_scene.add_child(tracer)
	_orient_between(tracer, from, to)
	get_tree().create_timer(0.1).timeout.connect(tracer.queue_free)


func _orient_between(node: Node3D, from: Vector3, to: Vector3) -> void:
	var diff := to - from
	var length := diff.length()
	var y_axis := diff / length
	var reference := Vector3.UP
	if absf(y_axis.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	var x_axis := reference.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	node.global_transform = Transform3D(Basis(x_axis, y_axis, z_axis), (from + to) / 2.0)
