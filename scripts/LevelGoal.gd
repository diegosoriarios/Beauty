extends Area2D

@export var goal_id := "world1_goal"

var _used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group("player"):
		return

	_used = true
	LevelManager.complete_level(self)
