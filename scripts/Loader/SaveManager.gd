extends Node

const SAVE_PATH := "user://savegame.cfg"
const SAVE_VERSION := 1

signal save_changed

var unlocked_levels: Array[String] = []
var completed_levels: Array[String] = []
var collected_clocks: Dictionary = {}
var discovered_secrets: Dictionary = {}
var _cache: Dictionary = {}


func _ready() -> void:
	load_save()


func default_save() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"settings": {
			"fullscreen": true,
			"music_enabled": true,
			"fx_enabled": true,
			"music_volume": 0.0,
			"fx_volume": 0.0,
		},
		"unlocked_levels": ["world1"],
		"completed_levels": [],
		"levels": {},
		"run": {},
	}


func load_save() -> Dictionary:
	var data := default_save()
	var config := ConfigFile.new()

	if config.load(SAVE_PATH) == OK:
		for key in config.get_section_keys("settings") if config.has_section("settings") else []:
			data.settings[key] = config.get_value("settings", key, data.settings.get(key))

		var unlocked = config.get_value("progress", "unlocked_levels", data.unlocked_levels)
		var completed = config.get_value("progress", "completed_levels", data.completed_levels)
		data.unlocked_levels = _string_array(unlocked, ["world1"])
		data.completed_levels = _string_array(completed, [])

		if config.has_section("levels"):
			for level_id in config.get_section_keys("levels"):
				var level_data: Dictionary = data.levels.get(level_id, {})
				level_data["collected_clocks"] = _string_array(
					config.get_value("levels", "%s/collected_clocks" % level_id, []),
					[]
				)
				level_data["discovered_secrets"] = _string_array(
					config.get_value("levels", "%s/discovered_secrets" % level_id, []),
					[]
				)
				for stat in ["best_time", "best_deaths", "best_clocks", "best_secrets"]:
					if config.has_section_key("levels", "%s/%s" % [level_id, stat]):
						level_data[stat] = config.get_value("levels", "%s/%s" % [level_id, stat])
				data.levels[level_id] = level_data

		if config.has_section("run"):
			for key in config.get_section_keys("run"):
				data.run[key] = config.get_value("run", key)

	unlocked_levels = _string_array(data.unlocked_levels, ["world1"])
	completed_levels = _string_array(data.completed_levels, [])
	collected_clocks = {}
	discovered_secrets = {}

	for level_id in data.levels:
		collected_clocks[level_id] = _string_array(data.levels[level_id].get("collected_clocks", []), [])
		discovered_secrets[level_id] = _string_array(data.levels[level_id].get("discovered_secrets", []), [])

	_apply_settings(data.settings)
	_cache = data.duplicate(true)
	return data


func save_data(data: Dictionary) -> void:
	_cache = data.duplicate(true)
	var config := ConfigFile.new()
	config.set_value("meta", "version", SAVE_VERSION)

	for key in data.settings:
		config.set_value("settings", key, data.settings[key])

	config.set_value("progress", "unlocked_levels", data.unlocked_levels)
	config.set_value("progress", "completed_levels", data.completed_levels)

	for level_id in data.levels:
		var level_data: Dictionary = data.levels[level_id]
		for key in level_data:
			config.set_value("levels", "%s/%s" % [level_id, key], level_data[key])

	for key in data.run:
		config.set_value("run", key, data.run[key])

	config.save(SAVE_PATH)
	save_changed.emit()


func get_save() -> Dictionary:
	if _cache.is_empty():
		return load_save()
	return _cache.duplicate(true)


func save_settings() -> void:
	var data := get_save()
	data.settings = {
		"fullscreen": settings.fullscreen,
		"music_enabled": settings.music_enabled,
		"fx_enabled": settings.fx_enabled,
		"music_volume": settings.music_volume,
		"fx_volume": settings.fx_volume,
	}
	save_data(data)


func _apply_settings(saved_settings: Dictionary) -> void:
	settings.fullscreen = saved_settings.get("fullscreen", settings.fullscreen)
	settings.music_enabled = saved_settings.get("music_enabled", settings.music_enabled)
	settings.fx_enabled = saved_settings.get("fx_enabled", settings.fx_enabled)
	settings.music_volume = saved_settings.get("music_volume", settings.music_volume)
	settings.fx_volume = saved_settings.get("fx_volume", settings.fx_volume)

	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)


func is_level_unlocked(level_id: String) -> bool:
	return level_id in unlocked_levels


func is_level_completed(level_id: String) -> bool:
	return level_id in completed_levels


func unlock_level(level_id: String) -> void:
	if is_level_unlocked(level_id):
		return
	unlocked_levels.append(level_id)
	_save_progress()


func complete_level(level_id: String, time_seconds: float, deaths: int, clocks: int, secrets: int) -> Dictionary:
	var data := get_save()
	if not level_id in data.completed_levels:
		data.completed_levels.append(level_id)

	var level_data: Dictionary = data.levels.get(level_id, {})
	var old_time: float = level_data.get("best_time", INF)
	var old_deaths: int = level_data.get("best_deaths", 2147483647)
	var old_clocks: int = level_data.get("best_clocks", -1)
	var old_secrets: int = level_data.get("best_secrets", -1)

	level_data["best_time"] = minf(old_time, time_seconds)
	level_data["best_deaths"] = mini(old_deaths, deaths)
	level_data["best_clocks"] = maxi(old_clocks, clocks)
	level_data["best_secrets"] = maxi(old_secrets, secrets)
	level_data["collected_clocks"] = collected_clocks.get(level_id, [])
	level_data["discovered_secrets"] = discovered_secrets.get(level_id, [])
	data.levels[level_id] = level_data

	unlocked_levels = _string_array(data.unlocked_levels, ["world1"])
	completed_levels = _string_array(data.completed_levels, [])
	save_data(data)
	return level_data


func get_level_progress(level_id: String) -> Dictionary:
	var data := get_save()
	return data.levels.get(level_id, {})


func mark_clock_collected(level_id: String, collectible_id: String) -> bool:
	var clocks: Array[String] = _string_array(collected_clocks.get(level_id, []), [])
	if collectible_id in clocks:
		return false

	clocks.append(collectible_id)
	collected_clocks[level_id] = clocks
	var data := get_save()
	var level_data: Dictionary = data.levels.get(level_id, {})
	level_data["collected_clocks"] = clocks
	data.levels[level_id] = level_data
	save_data(data)
	return true


func is_clock_collected(level_id: String, collectible_id: String) -> bool:
	return collectible_id in collected_clocks.get(level_id, [])


func mark_secret_discovered(level_id: String, secret_id: String) -> bool:
	var secrets: Array[String] = _string_array(discovered_secrets.get(level_id, []), [])
	if secret_id in secrets:
		return false

	secrets.append(secret_id)
	discovered_secrets[level_id] = secrets
	var data := get_save()
	var level_data: Dictionary = data.levels.get(level_id, {})
	level_data["discovered_secrets"] = secrets
	data.levels[level_id] = level_data
	save_data(data)
	return true


func is_secret_discovered(level_id: String, secret_id: String) -> bool:
	return secret_id in discovered_secrets.get(level_id, [])


func save_run(level_id: String, checkpoint_id: String, checkpoint_position: Vector2, time_seconds: float, deaths: int) -> void:
	var data := get_save()
	data.run = {
		"level_id": level_id,
		"checkpoint_id": checkpoint_id,
		"checkpoint_position": checkpoint_position,
		"time_seconds": time_seconds,
		"deaths": deaths,
	}
	save_data(data)


func clear_run() -> void:
	var data := get_save()
	data.run = {}
	save_data(data)


func get_run() -> Dictionary:
	return get_save().run


func has_continue() -> bool:
	var run := get_run()
	return not run.is_empty() and run.get("checkpoint_id", "") != "" and is_level_unlocked(run.get("level_id", ""))


func _save_progress() -> void:
	var data := get_save()
	data.unlocked_levels = unlocked_levels
	data.completed_levels = completed_levels
	save_data(data)


func _string_array(value, fallback: Array) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			if item is String:
				result.append(item)
	if result.is_empty() and not fallback.is_empty():
		for item in fallback:
			if item is String:
				result.append(item)
	return result
