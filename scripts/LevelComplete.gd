extends CanvasLayer

@onready var title_label: Label = $Root/Panel/Content/Title
@onready var stats_label: Label = $Root/Panel/Content/Stats
@onready var retry_button: Button = $Root/Panel/Content/Actions/RetryButton
@onready var next_button: Button = $Root/Panel/Content/Actions/NextButton
@onready var menu_button: Button = $Root/Panel/Content/Actions/MenuButton


func _ready() -> void:
	var result: Dictionary = LevelManager.last_result
	title_label.text = "%s Complete" % result.get("level_title", "Level")

	var clocks: int = result.get("clocks", 0)
	var total_clocks: int = result.get("total_clocks", 0)
	var secrets: int = result.get("secrets", 0)
	var total_secrets: int = result.get("total_secrets", 0)
	var time_seconds: float = result.get("time", 0.0)
	var deaths: int = result.get("deaths", 0)
	stats_label.text = "Time: %s\nDeaths: %d\nClocks: %d/%d\nSecrets: %d/%d" % [
		LevelManager.format_time(time_seconds),
		deaths,
		clocks,
		total_clocks,
		secrets,
		total_secrets,
	]

	var next_level: String = result.get("next_level", "")
	next_button.visible = not next_level.is_empty()
	retry_button.pressed.connect(_on_retry_pressed)
	next_button.pressed.connect(_on_next_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	retry_button.grab_focus()


func _on_retry_pressed() -> void:
	LevelManager.restart_level()


func _on_next_pressed() -> void:
	LevelManager.next_level()


func _on_menu_pressed() -> void:
	LevelManager.go_to_menu()
