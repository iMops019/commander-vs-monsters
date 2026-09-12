extends CanvasLayer

const TOWER_SCENE := preload("res://scenes/tower.tscn")
const TECH_BUILDING_SCENE := preload("res://scenes/tech_building.tscn")

@onready var resource_label: Label = $Margin/VBox/ResourceLabel
@onready var build_tower_button: Button = $Margin/VBox/BuildPanel/BuildTowerButton
@onready var build_tech_button: Button = $Margin/VBox/BuildPanel/BuildTechButton
@onready var upgrade_panel: VBoxContainer = $Margin/VBox/UpgradePanel
@onready var upgrade_title_label: Label = $Margin/VBox/UpgradePanel/UpgradeTitleLabel
@onready var worker_speed_button: Button = $Margin/VBox/UpgradePanel/WorkerSpeedButton
@onready var tower_damage_button: Button = $Margin/VBox/UpgradePanel/TowerDamageButton

var selected_building: Node = null


func _ready() -> void:
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.view_mode_changed.connect(_on_view_mode_changed)
	EventBus.building_selected.connect(_on_building_selected)

	build_tower_button.pressed.connect(_on_build_tower_pressed)
	build_tech_button.pressed.connect(_on_build_tech_pressed)
	worker_speed_button.pressed.connect(_on_worker_speed_pressed)
	tower_damage_button.pressed.connect(_on_tower_damage_pressed)

	_on_view_mode_changed(GameState.view_mode)
	_update_resource_label()


func _on_resource_changed(_resource_name: String, _amount: int) -> void:
	_update_resource_label()


func _update_resource_label() -> void:
	resource_label.text = "Wood: %d   Red Stone: %d   Gold: %d" % [GameState.wood, GameState.red_stone, GameState.gold]


func _on_view_mode_changed(mode: int) -> void:
	visible = mode == GameState.ViewMode.COMMANDER


func _on_build_tower_pressed() -> void:
	if is_instance_valid(GameState.commander_camera):
		GameState.commander_camera.start_placement(TOWER_SCENE, 40, 20)


func _on_build_tech_pressed() -> void:
	if is_instance_valid(GameState.commander_camera):
		GameState.commander_camera.start_placement(TECH_BUILDING_SCENE, 30, 40)


func _on_building_selected(building: Node) -> void:
	selected_building = building
	upgrade_panel.visible = building != null and building.is_in_group("tech_buildings")
	if upgrade_panel.visible:
		upgrade_title_label.text = building.display_name


func _on_worker_speed_pressed() -> void:
	if is_instance_valid(selected_building):
		selected_building.start_upgrade("worker_speed")


func _on_tower_damage_pressed() -> void:
	if is_instance_valid(selected_building):
		selected_building.start_upgrade("tower_damage")
