extends Area2D

@export var checkpoint_id := ""
@export var checkpoint_level_id := "world1"
@export var order := 0
@export var camera_path: NodePath
@export var default_checkpoint := false

@onready var indicator: Sprite2D = $Indicator


func _ready() -> void:
	add_to_group("checkpoints")
	body_entered.connect(_on_body_entered)
	set_active(LevelManager.active_checkpoint_id == checkpoint_id)


func get_camera() -> Camera2D:
	if camera_path.is_empty():
		return null
	return get_node_or_null(camera_path) as Camera2D


func set_active(active: bool) -> void:
	if active:
		indicator.modulate = Color(1.0, 0.88, 0.35, 1.0)
		indicator.scale = Vector2(3.0, 3.0)
	else:
		indicator.modulate = Color(0.55, 0.55, 0.6, 0.65)
		indicator.scale = Vector2(2.5, 2.5)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		LevelManager.activate_checkpoint(self)
