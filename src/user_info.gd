class_name UserInfo extends Object


const CACHE_USER_INFO = "user://user_info.json"
const CACHE_ROOM_ID = "user://room_id.json"


static func get_user_info() -> Dictionary:
	var result = {}
	if !FileAccess.file_exists(CACHE_USER_INFO):
		return result
	var file = FileAccess.open(CACHE_USER_INFO, FileAccess.READ)
	result = JSON.parse_string(file.get_as_text())
	file.close()
	return result

static func set_user_info(info: Dictionary) -> void:
	var file = FileAccess.open(CACHE_USER_INFO, FileAccess.WRITE)
	file.store_string(JSON.stringify(info))
	file.close()

static func append_user_info(info: Dictionary) -> void:
	var user_info = get_user_info()
	user_info.merge(info, true)
	set_user_info(user_info)


static func get_room_id() -> String:
	if !FileAccess.file_exists(CACHE_ROOM_ID):
		return ""
	var file = FileAccess.open(CACHE_ROOM_ID, FileAccess.READ)
	var result = file.get_as_text()
	file.close()
	return result

static func set_room_id(new_room_id: String) -> void:
	var file = FileAccess.open(CACHE_ROOM_ID, FileAccess.WRITE)
	file.store_string(new_room_id)
	file.close()
