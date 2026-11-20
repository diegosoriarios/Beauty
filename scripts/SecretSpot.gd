extends Area2D

@export var secret_id := ""

@onready var color_rect = $ColorRect

var _discovered := false


func _ready() -> void:
	add_to_group("secrets")
	apply_saved_state()


func apply_saved_state() -> void:
	_discovered = SaveManager.is_secret_discovered(LevelManager.current_level_id, _stable_id())


func _on_SecretSpot_body_entered(body):
	if not body.is_in_group("player"):
		return

	if LevelManager.discover_secret(self):
		_discovered = true
	$AnimationPlayer.play("fade_out")


func _on_SecretSpot_body_exited(body):
	if body.is_in_group("player"):
		$AnimationPlayer.play("fade_in")


func _stable_id() -> String:
	if not secret_id.is_empty():
		return secret_id
	return LevelManager.stable_id(self)
