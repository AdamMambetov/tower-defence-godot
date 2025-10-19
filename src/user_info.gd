class_name UserInfo extends Object


const CACHE_USER_INFO = "user://user_info.json"


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
