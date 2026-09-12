extends Node

enum ViewMode { COMMANDER, HERO }

const XP_PER_LEVEL := 100

var view_mode: ViewMode = ViewMode.COMMANDER

var wood: int = 0
var red_stone: int = 0
var gold: int = 0

var hero_xp: int = 0
var hero_level: int = 1
var hero_max_health: int = 100
var hero_damage_bonus: int = 0

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


func spend_resources(wood_amount: int = 0, red_stone_amount: int = 0, gold_amount: int = 0) -> void:
	wood -= wood_amount
	red_stone -= red_stone_amount
	gold -= gold_amount
	EventBus.resource_changed.emit("wood", -wood_amount)
	EventBus.resource_changed.emit("red_stone", -red_stone_amount)
	EventBus.resource_changed.emit("gold", -gold_amount)


func add_hero_xp(amount: int) -> void:
	hero_xp += amount
	while hero_xp >= XP_PER_LEVEL:
		hero_xp -= XP_PER_LEVEL
		hero_level += 1
		EventBus.hero_leveled_up.emit(hero_level)
	EventBus.hero_xp_changed.emit(hero_xp)


func increase_hero_damage(amount: int) -> void:
	hero_damage_bonus += amount
	EventBus.upgrade_applied.emit("hero_damage", hero_damage_bonus)


func increase_hero_max_health(amount: int) -> void:
	hero_max_health += amount
	EventBus.upgrade_applied.emit("hero_health", hero_max_health)
	if is_instance_valid(hero):
		hero.on_max_health_increased(hero_max_health)


func increase_worker_speed(amount: float) -> void:
	worker_speed_multiplier += amount
	EventBus.upgrade_applied.emit("worker_speed", worker_speed_multiplier)


func increase_tower_damage(amount: float) -> void:
	tower_damage_multiplier += amount
	EventBus.upgrade_applied.emit("tower_damage", tower_damage_multiplier)


func set_view_mode(mode: ViewMode) -> void:
	view_mode = mode
	EventBus.view_mode_changed.emit(mode)


func reset() -> void:
	view_mode = ViewMode.COMMANDER
	wood = 0
	red_stone = 0
	gold = 0
	hero_xp = 0
	hero_level = 1
	hero_max_health = 100
	hero_damage_bonus = 0
	hero = null
	commander_camera = null
	worker_speed_multiplier = 1.0
	tower_damage_multiplier = 1.0
