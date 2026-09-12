extends Node3D


func _ready() -> void:
	GameState.set_view_mode(GameState.ViewMode.COMMANDER)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_view"):
		var next_mode := GameState.ViewMode.HERO if GameState.view_mode == GameState.ViewMode.COMMANDER else GameState.ViewMode.COMMANDER
		GameState.set_view_mode(next_mode)
