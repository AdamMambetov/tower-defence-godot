extends Node


signal sign_result(result: bool)


@export var _request_path: NodePath
@onready var request_node: HTTPRequest = get_node(_request_path)

const BASE_URL = "http://10.144.97.136:8000/api/"
const header = {
	sign_in = [],
	sign_up = ["Content-Type: application/json"],
}

# login
func sign_in(username: String, password: String) -> void:
	var form = [
		{"name": "username", "value": username},
		{"name": "password", "value": password},
	]
	request_node.request(
		BASE_URL + "users/login/",
		header.sign_in,
		HTTPClient.METHOD_POST,
		form,
	)

# register
func sign_up(username: String, email: String, password: String) -> void:
	var data = JSON.stringify({
		username = username,
		email = email,
		password = password,
	})
	request_node.request(
		BASE_URL + "users/register/",
		header.sign_up,
		HTTPClient.METHOD_POST,
		data,
	)

func _on_request_completed(
		result: int,
		response_code: int,
		_headers: PackedStringArray,
		body: PackedByteArray
) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var res = JSON.parse_string(body.get_string_from_utf8())
		if res.has("access"):
			Global.access = res.access
		emit_signal("sing_result", true)
		print("request success! :)")
	else:
		emit_signal("sing_result", false)
		printerr("request error: ", result, " --- ", response_code)
