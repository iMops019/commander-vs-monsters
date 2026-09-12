class_name Health
extends Node

signal died
signal damaged(amount: int, remaining: int)

@export var max_health: int = 100

var current: int


func _ready() -> void:
	current = max_health


func apply_damage(amount: int) -> void:
	if current <= 0:
		return
	current = maxi(current - amount, 0)
	damaged.emit(amount, current)
	if current <= 0:
		died.emit()


func heal(amount: int) -> void:
	current = mini(current + amount, max_health)


func reset() -> void:
	current = max_health


func is_dead() -> bool:
	return current <= 0
