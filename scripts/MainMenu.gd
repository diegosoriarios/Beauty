extends Control

var selected = 0
var current_tab = 0

@onready var selection = [
	$Main,
	$Options,
	$Credits
]


func _ready():
	$Main/Continue.visible = SaveManager.has_continue()
	select_index(0)
	$Sound/Lead.volume_db = settings.music_volume
	$Sound/Main.volume_db = settings.music_volume
	$Options/EffectsVolume/HSlider.value = settings.fx_volume + 50
	$Options/MusicVolume/HSlider.value = settings.music_volume + 50
	SaveManager.save_settings()


func _visible_items(tab_index: int) -> Array[Node]:
	var items: Array[Node] = []
	for item in selection[tab_index].get_children():
		if item.visible:
			items.append(item)
	return items


func _input(event):
	if event.is_action_pressed("ui_up"):
		unselect_index()
		selected -= 1
		if selected < 0:
			selected = _visible_items(current_tab).size() - 1
		select_index(selected)
	elif event.is_action_pressed("ui_down"):
		unselect_index()
		selected += 1
		if selected == _visible_items(current_tab).size():
			selected = 0
		select_index(selected)
	elif event.is_action_pressed("ui_left"):
		handle_option_slider(-10)
	elif event.is_action_pressed("ui_right"):
		handle_option_slider(10)
	elif event.is_action_pressed("select"):
		unselect_index()
		if (current_tab == 0):
			handle_selection()
		elif (current_tab == 1):
			handle_option_selection()
		elif (current_tab == 2):
			$AnimationPlayer.play("credits-main")
			current_tab = 0
			selected = 0
			select_index(0)


func unselect_index():
	var items = _visible_items(current_tab)
	if items.is_empty():
		return
	items[clampi(selected, 0, items.size() - 1)].get_node("Label").add_theme_constant_override("outline_size", 0)


func select_index(index):
	var items = _visible_items(current_tab)
	if items.is_empty():
		return
	selected = clampi(index, 0, items.size() - 1)
	items[selected].get_node("Label").add_theme_constant_override("outline_size", 8)


func handle_selection():
	var selected_item = _visible_items(current_tab)[selected]
	match selected_item.name:
		"Continue":
			LevelManager.continue_run()
		"NewGame":
			LevelManager.start_new_run()
		"LevelSelect":
			get_tree().change_scene_to_file("res://scenes/Interface/LevelSelect.tscn")
		"Options":
			$AnimationPlayer.play("main-options")
			current_tab = 1
			selected = 0
			select_index(0)
		"Credits":
			$AnimationPlayer.play("main-credits")
			current_tab = 2
			selected = 0
			select_index(0)
		"Exit":
			SaveManager.save_settings()
			get_tree().quit()


func handle_option_selection():
	var selected_item = _visible_items(current_tab)[selected]
	match selected_item.name:
		"Fullscreen":
			get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (!((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
			$Options/Fullscreen/Label.button_pressed = ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))
			settings.fullscreen = $Options/Fullscreen/Label.button_pressed
			SaveManager.save_settings()
		"MusicVolume":
			selected = 1
			select_index(1)
		"EffectsVolume":
			selected = 2
			select_index(2)
		"Save":
			$AnimationPlayer.play("options-main")
			current_tab = 0
			selected = 0
			select_index(0)


func handle_option_slider(value):
	if selected == 1:
		$Options/MusicVolume/HSlider.value += value
		handle_sound_volume(value)
	elif selected == 2:
		$Options/EffectsVolume/HSlider.value += value
		handle_fx_volume(value)


func handle_sound_volume(volume):
	settings.music_volume += volume
	var sounds = $Sound.get_children()
	if (sounds != null):
		for sound in sounds:
			sound.volume_db = settings.music_volume
	SaveManager.save_settings()


func handle_fx_volume(volume):
	settings.fx_volume = volume - 50
	if has_node("Effects"):
		for fx in $Effects.get_children():
			fx.volume_db = volume - 50
	SaveManager.save_settings()


func _on_Lead_finished():
	$Sound/Lead.play()
	$Sound/Main.play()
