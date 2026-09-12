extends Node

enum ViewMode { COMMANDER, HERO }

var view_mode: ViewMode = ViewMode.COMMANDER

var wood: int = 0
var red_stone: int = 0
var gold: int = 0

var hero_xp: int = 0
var hero_level: int = 1

var hero: Node3D
var commander_camera: Camera3D

var worker_speed_multiplier: float = 1.0
var tower_damage_multiplier: float = 1.0


func add_resource(resource_name: String, amount: int) -> void:
	match resource_name:
		"wood":
			wood += amount
		"red_stone":
			red_stone += amount
		"gold":
			gold += amount
	EventBus.resource_changed.emit(resource_name, amount)


func spend_resources(wood_amount: int, red_stone_amount: int) -> void:
	wood -= wood_amount
	red_stone -= red_stone_amount
	EventBus.resource_changed.emit("wood", -wood_amount)
	EventBus.resource_changed.emit("red_stone", -red_stone_amount)


func increase_worker_speed(amount: float) -> void:
	worker_speed_multiplier += amount
	EventBus.upgrade_applied.emit("worker_speed", worker_speed_multiplier)


func increase_tower_damage(amount: float) -> void:
	tower_damage_multiplier += amount
	EventBus.upgrade_applied.emit("tower_damage", tower_damage_multiplier)


func set_view_mode(mode: ViewMode) -> void:
	view_mode = mode
	EventBus.view_mode_changed.emit(mode)
