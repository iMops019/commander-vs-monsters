extends Node3D

@onready var health: Health = $Health


func _ready() -> void:
	add_to_group("stockpile")
	health.died.connect(_on_died)


func _on_died() -> void:
	health.reset()


func deposit(resource_name: String, amount: int) -> void:
	GameState.add_resource(resource_name, amount)
