extends Node


signal sign_result(result: bool)


@export var _request_path: NodePath
@onready var request_node: HTTPRequest = get_node(_request_path)

const BASE_URL = "http://10.144.97.136:8000/"
const header = {
	sign_in = ["Content-Type: multipart/form-data; boundary=\"boundary\""],
	sign_up = ["Content-Type: application/json"],
}

# login
func sign_in(username: String, password: String) -> void:
	var body = PackedByteArray()
	_add_field(body, "username", username)
	_add_field(body, "password", password)
	_end_body(body)
	
	request_node.request_raw(
		BASE_URL + "users/login/",
		header.sign_in,
		HTTPClient.METHOD_POST,
		body,
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


func _add_field(body: PackedByteArray, key: String, value: String) -> void:
	var content = "\r\n--boundary\r\n" + "Content-Disposition: form-data; name=\"%s\"\r\n" % key + "Content-Type: text/plain; charset=UTF-8\r\n\r\n" + value
	body.append_array(content.to_utf8_buffer())

func _end_body(body: PackedByteArray):
	body.append_array("\r\n--boundary--\r\n".to_utf8_buffer())


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var res = JSON.parse_string(body.get_string_from_utf8())
		if res.has("access"):
			Global.access = res.access
		emit_signal("sign_result", true)
		print("request success! :)")
	else:
		emit_signal("sign_result", false)
		printerr("request error: ", result, " --- ", response_code)
