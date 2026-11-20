extends Node

signal checkpoint_activated(checkpoint)
signal player_died
signal player_respawned
signal clock_collected(clock)
signal secret_discovered(secret)
signal level_completed(result)

const LEVEL_COMPLETE_SCENE := preload("res://scenes/Interface/LevelComplete.tscn")
const DEATH_EFFECT_SCENE := preload("res://scenes/DeathEffect.tscn")
const MAIN_MENU_PATH := "res://scenes/Interface/MainMenu.tscn"
const RESPAWN_DELAY := 0.22

var current_level: Node = null
var current_level_id := ""
var active_checkpoint_id := ""
var checkpoint_position := Vector2.ZERO
var checkpoint_camera: Camera2D = null

var player: CharacterBody2D = null
var run_active := false
var run_time := 0.0
var run_deaths := 0
var is_player_dead := false
var is_level_completed := false
var last_result: Dictionary = {}

var _pending_level_id := ""
var _pending_checkpoint_id := ""
var _checkpoints: Dictionary = {}


func _process(delta: float) -> void:
	if run_active and not is_player_dead and not is_level_completed:
		run_time += delta


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		persist_run()


func start_level(level_id: String, checkpoint_id := "") -> void:
	_pending_level_id = level_id
	_pending_checkpoint_id = checkpoint_id
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Interface/Loading.tscn")


func continue_run() -> void:
	var run := SaveManager.get_run()
	if run.is_empty():
		start_level("world1")
		return
	start_level(run.get("level_id", "world1"), run.get("checkpoint_id", ""))


func start_new_run() -> void:
	SaveManager.clear_run()
	start_level(LevelCatalog.get_first_level_id())


func consume_pending_load() -> Array:
	var requested := [_pending_level_id, _pending_checkpoint_id]
	_pending_level_id = ""
	_pending_checkpoint_id = ""
	return requested


func register_level(level: Node) -> void:
	current_level = level
	current_level_id = level.level_id
	var resume_run := not _pending_checkpoint_id.is_empty()
	var saved_run := SaveManager.get_run()
	run_time = 0.0
	run_deaths = 0
	if resume_run and saved_run.get("level_id", "") == current_level_id:
		run_time = saved_run.get("time_seconds", 0.0)
		run_deaths = saved_run.get("deaths", 0)
	is_player_dead = false
	is_level_completed = false
	last_result = {}
	_checkpoints.clear()
	run_active = true

	var requested_checkpoint := _pending_checkpoint_id
	if requested_checkpoint.is_empty():
		for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
			if checkpoint.checkpoint_level_id == current_level_id and checkpoint.default_checkpoint:
				requested_checkpoint = checkpoint.checkpoint_id
				break

	var chosen: Node = null
	for checkpoint in get_tree().get_nodes_in_group("checkpoints"):
		if checkpoint.checkpoint_level_id != current_level_id:
			continue
		_checkpoints[checkpoint.checkpoint_id] = checkpoint
		if checkpoint.checkpoint_id == requested_checkpoint:
			chosen = checkpoint
		elif chosen == null and checkpoint.default_checkpoint:
			chosen = checkpoint

	for collectible in get_tree().get_nodes_in_group("collectibles"):
		if collectible.has_method("apply_saved_state"):
			collectible.apply_saved_state()

	for secret in get_tree().get_nodes_in_group("secrets"):
		if secret.has_method("apply_saved_state"):
			secret.apply_saved_state()

	if chosen:
		_set_checkpoint_internal(chosen, false)
		if player:
			_place_player(chosen.global_position)
		if checkpoint_camera:
			checkpoint_camera.make_current()

	SaveManager.save_run(
		current_level_id,
		active_checkpoint_id,
		checkpoint_position,
		run_time,
		run_deaths
	)


func register_player(active_player: CharacterBody2D) -> void:
	player = active_player
	if run_active and not active_checkpoint_id.is_empty() and player.global_position.distance_to(checkpoint_position) < 1.0:
		_place_player(checkpoint_position)


func register_checkpoint(checkpoint: Node) -> void:
	if checkpoint.checkpoint_level_id != current_level_id:
		return
	_checkpoints[checkpoint.checkpoint_id] = checkpoint
	if active_checkpoint_id.is_empty() and checkpoint.default_checkpoint:
		_set_checkpoint_internal(checkpoint, false)


func activate_checkpoint(checkpoint: Node) -> void:
	if checkpoint.checkpoint_id == active_checkpoint_id:
		return
	var active_checkpoint: Node = _checkpoints.get(active_checkpoint_id, null)
	if active_checkpoint and checkpoint.order < active_checkpoint.order:
		return
	_set_checkpoint_internal(checkpoint, true)
	checkpoint_activated.emit(checkpoint)


func set_checkpoint_internal(checkpoint: Node, emit := false) -> void:
	_set_checkpoint_internal(checkpoint, emit)


func kill_player() -> void:
	if is_player_dead or is_level_completed or player == null:
		return

	is_player_dead = true
	run_deaths += 1
	player.enter_death()
	_spawn_death_effect(player.global_position)
	SaveManager.save_run(current_level_id, active_checkpoint_id, checkpoint_position, run_time, run_deaths)
	player_died.emit()

	await get_tree().create_timer(RESPAWN_DELAY).timeout
	respawn_player()


func respawn_player(count_death := false) -> void:
	if player == null:
		return
	if count_death:
		run_deaths += 1

	is_player_dead = false
	player.respawn_at(checkpoint_position)
	if checkpoint_camera:
		checkpoint_camera.make_current()
	player_respawned.emit()


func collect_clock(clock: Node) -> bool:
	var collectible_id := stable_id(clock)
	var is_new := SaveManager.mark_clock_collected(current_level_id, collectible_id)
	if is_new:
		clock_collected.emit(clock)
	return is_new


func discover_secret(secret: Node) -> bool:
	var secret_id := stable_id(secret)
	var is_new := SaveManager.mark_secret_discovered(current_level_id, secret_id)
	if is_new:
		secret_discovered.emit(secret)
	return is_new


func complete_level(goal: Node) -> void:
	if is_level_completed:
		return

	is_level_completed = true
	run_active = false
	var clocks: int = SaveManager.collected_clocks.get(current_level_id, []).size()
	var secrets: int = SaveManager.discovered_secrets.get(current_level_id, []).size()
	var level_data: Dictionary = SaveManager.complete_level(
		current_level_id,
		run_time,
		run_deaths,
		clocks,
		secrets
	)

	var catalog: Dictionary = LevelCatalog.get_level(current_level_id)
	var next_id: String = catalog.get("next_level", "")
	if not next_id.is_empty():
		SaveManager.unlock_level(next_id)

	SaveManager.clear_run()
	last_result = {
		"level_id": current_level_id,
		"level_title": catalog.get("title", current_level_id.capitalize()),
		"time": run_time,
		"deaths": run_deaths,
		"clocks": clocks,
		"total_clocks": current_level.total_clocks,
		"secrets": secrets,
		"total_secrets": current_level.total_secrets,
		"best": level_data,
		"next_level": next_id,
	}

	if player:
		player.transition_on()

	var complete_screen := LEVEL_COMPLETE_SCENE.instantiate()
	get_tree().current_scene.add_child.call_deferred(complete_screen)
	level_completed.emit(last_result)
	get_tree().paused = true


func next_level() -> void:
	if last_result.get("next_level", "") != "":
		start_level(last_result.next_level)


func restart_checkpoint() -> void:
	get_tree().paused = false
	respawn_player(false)


func persist_run() -> void:
	if run_active and not active_checkpoint_id.is_empty():
		SaveManager.save_run(current_level_id, active_checkpoint_id, checkpoint_position, run_time, run_deaths)


func restart_level() -> void:
	start_level(current_level_id)


func go_to_menu() -> void:
	get_tree().paused = false
	is_player_dead = false
	run_active = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func stable_id(node: Node) -> String:
	return "%s:%s" % [current_level_id, String(node.get_path())]


func format_time(time_seconds: float) -> String:
	var total_seconds := int(time_seconds)
	return "%d:%02d" % [total_seconds / 60, total_seconds % 60]


func _set_checkpoint_internal(checkpoint: Node, emit: bool) -> void:
	active_checkpoint_id = checkpoint.checkpoint_id
	checkpoint_position = checkpoint.global_position
	checkpoint_camera = checkpoint.get_camera()
	checkpoint.set_active(true)

	for checkpoint_id in _checkpoints:
		if checkpoint_id != active_checkpoint_id:
			_checkpoints[checkpoint_id].set_active(false)

	SaveManager.save_run(
		current_level_id,
		active_checkpoint_id,
		checkpoint_position,
		run_time,
		run_deaths
	)
	if emit:
		checkpoint_activated.emit(checkpoint)


func _place_player(position: Vector2) -> void:
	if player:
		player.respawn_at(position)


func _spawn_death_effect(position: Vector2) -> void:
	var effect := DEATH_EFFECT_SCENE.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = position
