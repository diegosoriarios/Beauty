extends Area2D

@export var clock_id := ""

var _collected := false


func _ready() -> void:
	add_to_group("collectibles")
	apply_saved_state()


func apply_saved_state() -> void:
	if SaveManager.is_clock_collected(LevelManager.current_level_id, _stable_id()):
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return

	if LevelManager.collect_clock(self):
		_collected = true
		set_deferred("monitoring", false)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property($Sprite2D, "scale", $Sprite2D.scale * 1.4, 0.12)
		tween.tween_property($Sprite2D, "modulate:a", 0.0, 0.12)
		tween.chain().tween_callback(queue_free)


func _stable_id() -> String:
	if not clock_id.is_empty():
		return clock_id
	return LevelManager.stable_id(self)
