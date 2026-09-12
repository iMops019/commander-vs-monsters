extends CanvasLayer

const TOWER_SCENE := preload("res://scenes/tower.tscn")
const TECH_BUILDING_SCENE := preload("res://scenes/tech_building.tscn")

@onready var commander_ui: Control = $CommanderUI
@onready var fighter_ui: Control = $FighterUI

@onready var resource_label: Label = $CommanderUI/TopBar/ResourceLabel

@onready var selection_label: Label = $CommanderUI/PanelsRow/CommanderFunctionsPanel/CFMargin/CFVBox/SelectionLabel
@onready var move_button: Button = $CommanderUI/PanelsRow/CommanderFunctionsPanel/CFMargin/CFVBox/MoveButton
@onready var chop_wood_button: Button = $CommanderUI/PanelsRow/CommanderFunctionsPanel/CFMargin/CFVBox/ChopWoodButton
@onready var mine_stone_button: Button = $CommanderUI/PanelsRow/CommanderFunctionsPanel/CFMargin/CFVBox/MineStoneButton

@onready var build_tower_button: Button = $CommanderUI/PanelsRow/BuildingPanel/BuildMargin/BuildVBox/BuildTowerButton
@onready var build_tech_button: Button = $CommanderUI/PanelsRow/BuildingPanel/BuildMargin/BuildVBox/BuildTechButton
@onready var upgrade_panel: VBoxContainer = $CommanderUI/PanelsRow/BuildingPanel/BuildMargin/BuildVBox/UpgradePanel
@onready var upgrade_title_label: Label = $CommanderUI/PanelsRow/BuildingPanel/BuildMargin/BuildVBox/UpgradePanel/UpgradeTitleLabel
@onready var worker_speed_button: Button = $CommanderUI/PanelsRow/BuildingPanel/BuildMargin/BuildVBox/UpgradePanel/WorkerSpeedButton
@onready var tower_damage_button: Button = $CommanderUI/PanelsRow/BuildingPanel/BuildMargin/BuildVBox/UpgradePanel/TowerDamageButton
@onready var hero_damage_button: Button = $CommanderUI/PanelsRow/BuildingPanel/BuildMargin/BuildVBox/UpgradePanel/HeroDamageButton
@onready var hero_health_button: Button = $CommanderUI/PanelsRow/BuildingPanel/BuildMargin/BuildVBox/UpgradePanel/HeroHealthButton

@onready var health_bar: ProgressBar = $FighterUI/FighterMargin/FighterVBox/HealthRow/HealthBar
@onready var xp_bar: ProgressBar = $FighterUI/FighterMargin/FighterVBox/XPRow/XPBar
@onready var level_label: Label = $FighterUI/FighterMargin/FighterVBox/XPRow/LevelLabel

var selected_building: Node = null
var hero_health_connected := false


func _ready() -> void:
	EventBus.resource_changed.connect(_on_resource_changed)
	EventBus.view_mode_changed.connect(_on_view_mode_changed)
	EventBus.building_selected.connect(_on_building_selected)
	EventBus.worker_selected.connect(_on_worker_selected)
	EventBus.hero_xp_changed.connect(_on_hero_stats_changed)
	EventBus.hero_leveled_up.connect(_on_hero_stats_changed)

	build_tower_button.pressed.connect(_on_build_tower_pressed)
	build_tech_button.pressed.connect(_on_build_tech_pressed)
	worker_speed_button.pressed.connect(_on_worker_speed_pressed)
	tower_damage_button.pressed.connect(_on_tower_damage_pressed)
	hero_damage_button.pressed.connect(_on_hero_damage_pressed)
	hero_health_button.pressed.connect(_on_hero_health_pressed)

	move_button.pressed.connect(_on_move_pressed)
	chop_wood_button.pressed.connect(_on_chop_wood_pressed)
	mine_stone_button.pressed.connect(_on_mine_stone_pressed)

	_on_view_mode_changed(GameState.view_mode)
	_update_resource_label()
	_update_fighter_bars()


func _on_resource_changed(_resource_name: String, _amount: int) -> void:
	_update_resource_label()


func _update_resource_label() -> void:
	resource_label.text = "Wood: %d   Red Stone: %d   Gold: %d" % [GameState.wood, GameState.red_stone, GameState.gold]


func _on_hero_stats_changed(_value) -> void:
	_update_fighter_bars()


func _update_fighter_bars() -> void:
	if is_instance_valid(GameState.hero):
		health_bar.max_value = GameState.hero.health.max_health
		health_bar.value = GameState.hero.health.current
	xp_bar.max_value = GameState.XP_PER_LEVEL
	xp_bar.value = GameState.hero_xp
	level_label.text = "Lv %d" % GameState.hero_level


func _ensure_hero_health_connected() -> void:
	if hero_health_connected or not is_instance_valid(GameState.hero):
		return
	GameState.hero.health.damaged.connect(func(_amount, _remaining): _update_fighter_bars())
	GameState.hero.health.died.connect(func(): _update_fighter_bars())
	hero_health_connected = true


func _on_view_mode_changed(mode: int) -> void:
	commander_ui.visible = mode == GameState.ViewMode.COMMANDER
	fighter_ui.visible = mode == GameState.ViewMode.HERO
	if mode == GameState.ViewMode.HERO:
		_ensure_hero_health_connected()
		_update_fighter_bars()


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


func _on_worker_selected(worker: Node) -> void:
	var has_worker := is_instance_valid(worker)
	selection_label.text = "Selected: Worker" if has_worker else "Selected: none"
	move_button.disabled = not has_worker
	chop_wood_button.disabled = not has_worker
	mine_stone_button.disabled = not has_worker


func _on_move_pressed() -> void:
	if is_instance_valid(GameState.commander_camera):
		GameState.commander_camera.arm_move_command()


func _on_chop_wood_pressed() -> void:
	if is_instance_valid(GameState.commander_camera):
		GameState.commander_camera.command_gather_nearest("wood")


func _on_mine_stone_pressed() -> void:
	if is_instance_valid(GameState.commander_camera):
		GameState.commander_camera.command_gather_nearest("red_stone")


func _on_worker_speed_pressed() -> void:
	if is_instance_valid(selected_building):
		selected_building.start_upgrade("worker_speed")


func _on_tower_damage_pressed() -> void:
	if is_instance_valid(selected_building):
		selected_building.start_upgrade("tower_damage")


func _on_hero_damage_pressed() -> void:
	if is_instance_valid(selected_building):
		selected_building.start_upgrade("hero_damage")


func _on_hero_health_pressed() -> void:
	if is_instance_valid(selected_building):
		selected_building.start_upgrade("hero_health")
