extends Node2D

@export var level_id := "world1"
@export var total_clocks := 5
@export var total_secrets := 4


func _ready() -> void:
	LevelManager.register_level(self)
