extends Control

@onready var selection = $Selection
var selected = 0


func _ready():
	select_index(0)


func _input(event):
	if event.is_action_pressed("pause"):
		var new_pause_state = not get_tree().paused
		get_tree().paused = new_pause_state
		visible = new_pause_state
	elif event.is_action_pressed("ui_up"):
		unselect_index()
		selected -= 1
		if selected < 0:
			selected = selection.get_child_count() - 1
		select_index(selected)
	elif event.is_action_pressed("ui_down"):
		unselect_index()
		selected += 1
		if selected == selection.get_child_count():
			selected = 0
		select_index(selected)
	elif event.is_action_pressed("select"):
		handle_selection()


func unselect_index():
	for select in selection.get_children():
		select.add_theme_constant_override("outline_size", 0)


func select_index(index):
	selected = clampi(index, 0, selection.get_child_count() - 1)
	selection.get_child(selected).add_theme_constant_override("outline_size", 8)


func handle_selection():
	var selected_item = selection.get_child(selected)
	match selected_item.name:
		"Continue":
			get_tree().paused = false
			visible = false
		"Options":
			pass
		"RestartCheckpoint":
			visible = false
			LevelManager.restart_checkpoint()
		"RestartLevel":
			LevelManager.restart_level()
		"SaveAndExit":
			LevelManager.persist_run()
			SaveManager.save_settings()
			LevelManager.go_to_menu()
