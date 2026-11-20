extends Control

@onready var loading = preload("res://scenes/Interface/Loading.tscn")
@onready var credits_scene = preload("res://scenes/Interface/Credits.tscn")
var selected = 0
var current_tab = 0

@onready var selection = [
	$Main,
	$Options,
	$Credits
]

func _ready():
	select_index(0)
	$Sound/Lead.volume_db = settings.music_volume
	$Sound/Main.volume_db = settings.music_volume
	$Options/EffectsVolume/HSlider.value = settings.fx_volume + 50
	$Options/MusicVolume/HSlider.value = settings.music_volume + 50

func _input(event):
	if event.is_action_pressed("ui_up"):
		unselect_index()
		selected -= 1
		if selected < 0:
			selected = selection[current_tab].get_child_count() - 1
		select_index(selected)
	elif event.is_action_pressed("ui_down"):
		unselect_index()
		selected += 1
		if selected == selection[current_tab].get_child_count():
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
	for select in selection[current_tab].get_children():
		select.get_node("Label").add_theme_constant_override("outline_size", 0)

func select_index(index):
	selection[current_tab].get_child(index).get_node("Label").add_theme_constant_override("outline_size", 8)

func handle_selection():
	if selected == 0:
		get_tree().change_scene_to_packed(loading)
	elif selected == 1:
		$AnimationPlayer.play("main-options")
		current_tab = 1
		selected = 0
		select_index(0)
	elif selected == 2:
		$AnimationPlayer.play("main-credits")
		current_tab = 2
		selected = 0
		select_index(0)
	elif selected == 3:
		get_tree().quit()

func handle_option_selection():
	if selected == 0:
		get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (!((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))) else Window.MODE_WINDOWED
		$Options/Fullscreen/Label.button_pressed = ((get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN) or (get_window().mode == Window.MODE_FULLSCREEN))
		current_tab = 1
		selected = 0
		select_index(0)
	elif selected == 1:
		current_tab = 1
		selected = 1
		select_index(1)
	elif selected == 2:
		current_tab = 1
		selected = 2
		select_index(2)
	elif selected == 3:
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

func handle_fx_volume(volume):
	settings.fx_volume = volume - 50
	if has_node("Effects"):
		for fx in $Effects.get_children():
			fx.volume_db = volume - 50

func _on_Lead_finished():
	$Sound/Lead.play()
	$Sound/Main.play()
