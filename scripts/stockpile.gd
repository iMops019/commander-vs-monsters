extends Node3D


func _ready() -> void:
	add_to_group("stockpile")


func deposit(resource_name: String, amount: int) -> void:
	GameState.add_resource(resource_name, amount)
