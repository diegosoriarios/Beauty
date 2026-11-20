class_name LevelCatalog

const LEVELS := {
	"world1": {
		"title": "World 1",
		"scene": "res://scenes/Levels/World1.tscn",
		"next_level": "",
	},
}


static func get_level(level_id: String) -> Dictionary:
	return LEVELS.get(level_id, {})


static func get_level_path(level_id: String) -> String:
	return get_level(level_id).get("scene", "")


static func get_first_level_id() -> String:
	return LEVELS.keys()[0]
