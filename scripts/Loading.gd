extends Node

var loader_path = ""
var wait_frames = 0
var current_scene

func _ready():
	current_scene = get_tree().current_scene
	var requested = LevelManager.consume_pending_load()
	var level_id: String = requested[0]
	var level_path := LevelCatalog.get_level_path(level_id)
	if level_path.is_empty():
		level_id = LevelCatalog.get_first_level_id()
		level_path = LevelCatalog.get_level_path(level_id)
	goto_scene(level_path)

func _process(_delta):
	if loader_path == "":
		set_process(false)
		return

	# Wait for frames to let the "loading..." animation show up.
	if wait_frames > 0:
		wait_frames -= 1
		return

	var progress = []
	var status = ResourceLoader.load_threaded_get_status(loader_path, progress)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			update_progress(progress)
		ResourceLoader.THREAD_LOAD_LOADED:
			var resource = ResourceLoader.load_threaded_get(loader_path)
			loader_path = ""
			set_new_scene(resource)
		_:
			show_error()
			loader_path = ""

func goto_scene(path): # Game requests to switch to this scene.
	loader_path = path
	var err = ResourceLoader.load_threaded_request(path)
	if err != OK:
		show_error()
		loader_path = ""
		return
	set_process(true)

	# Start your "loading..." animation.
	#get_node("animation").play("loading")

	wait_frames = 1

func update_progress(progress):
	if progress.size() > 0:
		print(progress[0])

func set_new_scene(scene_resource):
	current_scene.queue_free() # Get rid of the old scene.

	# Start your "loading..." animation.
	#get_node("animation").play("loading")
	current_scene = scene_resource.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene
	var camera = current_scene.find_child("Camera2D", true, false)
	if camera:
		camera.make_current()

func show_error():
	print("Error")
