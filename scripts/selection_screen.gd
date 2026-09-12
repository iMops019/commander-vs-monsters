extends CanvasLayer

const CLASS_OPTIONS := {
	"humans": ["warrior", "knight"],
	"horde": ["grunt", "orc"],
}

@onready var faction_panel: VBoxContainer = $CenterContainer/FactionPanel
@onready var humans_button: Button = $CenterContainer/FactionPanel/HumansButton
@onready var horde_button: Button = $CenterContainer/FactionPanel/HordeButton

@onready var class_panel: VBoxContainer = $CenterContainer/ClassPanel
@onready var class_title_label: Label = $CenterContainer/ClassPanel/ClassTitleLabel
@onready var class_button_1: Button = $CenterContainer/ClassPanel/ClassButton1
@onready var class_button_2: Button = $CenterContainer/ClassPanel/ClassButton2
@onready var back_button: Button = $CenterContainer/ClassPanel/BackButton

var chosen_faction: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	humans_button.pressed.connect(_on_faction_chosen.bind("humans"))
	horde_button.pressed.connect(_on_faction_chosen.bind("horde"))
	class_button_1.pressed.connect(_on_class_chosen.bind(0))
	class_button_2.pressed.connect(_on_class_chosen.bind(1))
	back_button.pressed.connect(_on_back_pressed)

	class_panel.visible = false


func _on_faction_chosen(faction: String) -> void:
	chosen_faction = faction
	var classes: Array = CLASS_OPTIONS[faction]
	class_button_1.text = classes[0].capitalize()
	class_button_2.text = classes[1].capitalize()
	faction_panel.visible = false
	class_panel.visible = true


func _on_class_chosen(index: int) -> void:
	var classes: Array = CLASS_OPTIONS[chosen_faction]
	var chosen_class: String = classes[index]
	GameState.choose_class(chosen_faction, chosen_class)
	get_tree().paused = false
	queue_free()


func _on_back_pressed() -> void:
	class_panel.visible = false
	faction_panel.visible = true
