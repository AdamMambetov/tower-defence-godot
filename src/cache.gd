class_name Cache extends Object

#region Utils

static func _read_json(path: String) -> Dictionary:
	var result = {}
	if !FileAccess.file_exists(path):
		return result
	var file = FileAccess.open(path, FileAccess.READ)
	result = JSON.parse_string(file.get_as_text())
	file.close()
	return result

static func _write_json(path: String, value: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

#endregion Utils

#region UserInfo

const CACHE_USER_INFO = "user://user_info.json"

static func get_user_info() -> Dictionary:
	return _read_json(CACHE_USER_INFO)

static func set_user_info(info: Dictionary) -> void:
	_write_json(CACHE_USER_INFO, info)

static func append_user_info(info: Dictionary) -> void:
	var user_info = get_user_info()
	user_info.merge(info, true)
	set_user_info(user_info)

#endregion UserInfo

#region RoomID

const CACHE_ROOM_ID = "user://room_id.json"

static func get_room_id() -> String:
	return _read_json(CACHE_ROOM_ID).value

static func set_room_id(new_room_id: String) -> void:
	_write_json(CACHE_ROOM_ID, { value = new_room_id })

#endregion RoomID

#region Settings

const CACHE_SETTINGS = "user://settings.json"

static func get_settings() -> Dictionary:
	return _read_json(CACHE_SETTINGS)

static func set_settings(info: Dictionary) -> void:
	_write_json(CACHE_SETTINGS, info)

static func append_settings(info: Dictionary) -> void:
	var settings = get_settings()
	settings.merge(info, true)
	set_settings(settings)

#endregion Settings
