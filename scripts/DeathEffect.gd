extends Node2D


func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property($Icon, "scale", Vector2(2.2, 2.2), 0.18)
	tween.tween_property($Icon, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
