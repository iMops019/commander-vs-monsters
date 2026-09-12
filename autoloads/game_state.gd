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


func add_resource(resource_name: String, amount: int) -> void:
	match resource_name:
		"wood":
			wood += amount
		"red_stone":
			red_stone += amount
		"gold":
			gold += amount
	EventBus.resource_changed.emit(resource_name, amount)


func set_view_mode(mode: ViewMode) -> void:
	view_mode = mode
	EventBus.view_mode_changed.emit(mode)
