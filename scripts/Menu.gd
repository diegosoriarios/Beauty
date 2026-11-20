extends Control

@onready var selection = $Selection
@onready var world_1 = preload("res://scenes/Levels/World1.tscn")
var selected = 0

func _ready():
	select_index(0)

func _input(event):
	if event.is_action_pressed("ui_up"):
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
		select.get_node("Label").add_theme_constant_override("outline_size", 0)

func select_index(index):
	selection.get_child(index).get_node("Label").add_theme_constant_override("outline_size", 8)

func handle_selection():
	if selected == 0:
		get_tree().change_scene_to_packed(world_1)
	elif selected == 1:
		pass
	elif selected == 2:
		pass
	elif selected == 3:
		get_tree().quit()
