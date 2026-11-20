extends Control

@onready var world_button: Button = $Content/Buttons/World1Button
@onready var back_button: Button = $Content/Buttons/BackButton
@onready var stats_label: Label = $Content/Stats


func _ready() -> void:
	world_button.pressed.connect(_on_world_1_pressed)
	back_button.pressed.connect(_on_back_pressed)
	_refresh_state()
	world_button.grab_focus()


func _refresh_state() -> void:
	world_button.disabled = not SaveManager.is_level_unlocked("world1")
	if world_button.disabled:
		world_button.text = "World 1 - Locked"
	else:
		world_button.text = "World 1"

	var progress: Dictionary = SaveManager.get_level_progress("world1")
	if progress.has("best_time"):
		var best_time: float = progress.get("best_time", 0.0)
		var best_deaths: int = progress.get("best_deaths", 0)
		stats_label.text = "Best: %s  |  %d deaths" % [
			LevelManager.format_time(best_time),
			best_deaths,
		]
	else:
		stats_label.text = "No completed runs"


func _on_world_1_pressed() -> void:
	LevelManager.start_level("world1")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Interface/MainMenu.tscn")
