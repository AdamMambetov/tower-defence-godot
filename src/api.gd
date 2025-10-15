extends Node


signal sign_result(result: bool)
signal join_result(result: bool)


var socket: WebSocketPeer
var join_url: String

@export var _request_path: NodePath
@onready var request_node: HTTPRequest = get_node(_request_path)

const BASE_URL = "http://10.144.97.136:8000/"
const header = {
	sign_in = ["Content-Type: multipart/form-data; boundary=\"boundary\""],
	sign_up = ["Content-Type: application/json"],
	queue = ["Content-Type: application/json", "Authorization: Bearer %s"],
}

func _process(_delta: float) -> void:
	if !is_instance_valid(socket):
		return
	socket.poll()
	var state = socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			print("STATE_OPEN")
		WebSocketPeer.STATE_CLOSING:
			print("STATE_CLOSING")
		WebSocketPeer.STATE_CLOSED:
			print("STATE_CLOSED")
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			socket.free()
			socket = null

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
	var res = await request_node.request_completed
	if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
		var body_json = JSON.parse_string(res[3].get_string_from_utf8())
		Global.access = body_json.access
		sign_result.emit(true)
		print("request success! :)")
	else:
		sign_result.emit(false)
		printerr("request error: ", res)

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
	
	var res = await request_node.request_completed
	if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
		emit_signal("sign_result", true)
		print("request success! :)")
	else:
		emit_signal("sign_result", false)
		printerr("request error: ", res)

func join() -> void:
	var headers = header.queue.duplicate(true)
	headers[-1] %= Global.access
	request_node.request(
		BASE_URL + "queue/join/",
		headers,
		HTTPClient.METHOD_POST,
	)
	
	var res = await request_node.request_completed
	if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
		join_result.emit(true)
		print("request success! :)")
		var body_json = JSON.parse_string(res[3].get_string_from_utf8())
		var room_id = body_json.waiting_room_id
		join_url = BASE_URL + room_id
		_connect()
	else:
		join_result.emit(false)
		printerr("request error: ", res)


func _add_field(body: PackedByteArray, key: String, value: String) -> void:
	var content = "\r\n--boundary\r\n" + "Content-Disposition: form-data; name=\"%s\"\r\n" % key + "Content-Type: text/plain; charset=UTF-8\r\n\r\n" + value
	body.append_array(content.to_utf8_buffer())

func _end_body(body: PackedByteArray):
	body.append_array("\r\n--boundary--\r\n".to_utf8_buffer())

func _connect() -> void:
	socket = WebSocketPeer.new()
	var err = socket.connect_to_url(join_url)
	if err != OK:
		printerr("connect error: ", err)
		await get_tree().create_timer(5).timeout
		_connect()
	else:
		printerr("connect...")
