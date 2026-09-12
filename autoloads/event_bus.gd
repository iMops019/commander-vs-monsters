extends Node

signal view_mode_changed(mode: int)
signal resource_changed(resource_name: String, amount: int)
signal hero_leveled_up(new_level: int)
signal hero_xp_changed(total_xp: int)
signal building_selected(building: Node)
signal worker_selected(worker: Node)
signal upgrade_applied(upgrade_id: String, new_value: float)
signal game_won
signal class_selected(player_class: String, player_faction: String)
