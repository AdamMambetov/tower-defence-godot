extends HTTPRequest


signal sign_result(success: bool, result: String)
signal join_result(success: bool, result: String)


var socket: WebSocketPeer
var join_url: String
var room_id: String
var waiting_opponent: bool
var authorized: bool
var prev_state = -1
var access_token_timer: Timer

const ACCESS_TOKEN_LIFE_TIME = 60*60
const API_BASE_URL = "http://127.0.0.1:8000/"
const WS_BASE_URL = "ws://127.0.0.1:8100/ws/"

const headers = {
	form_data = "Content-Type: multipart/form-data; boundary=\"boundary\"",
	json = "Content-Type: application/json",
	jwt_token = "Authorization: Bearer ",
}


func _ready() -> void:
	_create_access_token_timer()
	_try_auth()

func _process(_delta: float) -> void:
	if !is_instance_valid(socket):
		return
	socket.poll()
	var state = socket.get_ready_state()
	if state != prev_state:
		prev_state = state
		prints("State changed to: ", state)
	match state:
		WebSocketPeer.STATE_OPEN:
			while socket.get_available_packet_count() > 0:
				var packet = socket.get_packet()
				if not socket.was_string_packet():
					printerr("Received non-text packet! Size: ", packet.size())
					continue

				var data = packet.get_string_from_utf8()
				var json = JSON.parse_string(data)
				if json == null:
					prints("Message no a JSON format: ", data)
					continue

				match Global.game_state:
					Global.GameState.WaitingGame:
						_waiting_game_process(json)
					Global.GameState.PlayingGame:
						_playing_game_process()
		WebSocketPeer.STATE_CLOSING:
			print("STATE_CLOSING")
		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			socket = null
			prints("Connection closed","CODE:",code,"Reason:",reason)

# login
func sign_in(username: String, password: String) -> void:
	var body = PackedByteArray()
	_add_field(body, "username", username)
	_add_field(body, "password", password)
	_end_body(body)
	
	request_raw(
		API_BASE_URL + "users/login/",
		[headers.form_data],
		HTTPClient.METHOD_POST,
		body,
	)
	var res = await request_completed
	if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
		var body_json = JSON.parse_string(res[3].get_string_from_utf8())
		UserInfo.append_user_info({ access = body_json.access })
		sign_result.emit(true, res[3].get_string_from_utf8())
		access_token_timer.start()
		authorized = true
		prints("POST", res[1], "users/login/", body_json)
	else:
		sign_result.emit(false, res[3].get_string_from_utf8())
		printerr("request error: ", res[3].get_string_from_utf8())

# register
func sign_up(username: String, email: String, password: String) -> void:
	var data = {
		username = username,
		email = email,
		password = password,
	}
	var json = JSON.stringify(data)
	request(
		API_BASE_URL + "users/register/",
		[headers.json],
		HTTPClient.METHOD_POST,
		json,
	)
	
	var res = await request_completed
	if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
		UserInfo.append_user_info(data)
		sign_result.emit(true, "Вы успешно зарегистрированы!")
		prints("POST", res[1], "users/register/", res[3])
	else:
		sign_result.emit(false, res[3].get_string_from_utf8())
		printerr("request error: ", res, res[3].get_string_from_utf8())

func join() -> void:
	if !authorized:
		await get_tree().process_frame
		join_result.emit(false, "Вы не авторизованы!")
		return
	
	request(
		API_BASE_URL + "queue/join/",
		[headers.json, headers.jwt_token + UserInfo.get_user_info().access],
		HTTPClient.METHOD_POST,
	)
	
	var res = await request_completed
	if res[0] == HTTPRequest.RESULT_SUCCESS and res[1] == 200:
		var body_json = JSON.parse_string(res[3].get_string_from_utf8())
		prints("POST", res[1], "queue/join/", body_json)
		if body_json.has('waiting_room_id'):
			Global.game_state = Global.GameState.WaitingGame
			waiting_opponent = true
			room_id = body_json.waiting_room_id
			join_url = "%swaiting_room/%s/" % [WS_BASE_URL, room_id]
		else:
			Global.game_state = Global.GameState.PlayingGame
			room_id = body_json.room_id
			join_url = "%splay_room/%s/" % [WS_BASE_URL, room_id]
		_connect()
	else:
		var error = res[3].get_string_from_utf8()
		printerr("Request Error: ", error)
		join_result.emit(false, error)

func _add_field(body: PackedByteArray, key: String, value: String) -> void:
	var content = "\r\n--boundary\r\n" + "Content-Disposition: form-data; name=\"%s\"\r\n" % key + "Content-Type: text/plain; charset=UTF-8\r\n\r\n" + value
	body.append_array(content.to_utf8_buffer())

func _end_body(body: PackedByteArray):
	body.append_array("\r\n--boundary--\r\n".to_utf8_buffer())

func _connect() -> bool:
	socket = WebSocketPeer.new()
	socket.handshake_headers = PackedStringArray([
		"access: " + UserInfo.get_user_info().access,
	])
	return socket.connect_to_url(join_url) == OK

func _waiting_game_process(json: Dictionary) -> void:
	if waiting_opponent and json.has("room_id"):
		waiting_opponent = false
		room_id = json.room_id
		join_url = "%splay_room/%s/" % [WS_BASE_URL, room_id]
		for i in 3:
			if _connect():
				join_result.emit(true, "")
				await get_tree().create_timer(1.0).timeout
				return
		socket = null
		Global.game_state = Global.GameState.Menu
		join_result.emit(false, "Не удалось найти противника.")
	else:
		prints("Received other message: ", json)

func _playing_game_process() -> void:
	pass

func _try_auth() -> void:
	var user_info = UserInfo.get_user_info()
	if user_info.is_empty():
		authorized = false
	elif user_info.has("access"):
		sign_in(user_info.username, user_info.password)
		var result = await sign_result
		authorized = result[0]

func _create_access_token_timer() -> void:
	access_token_timer = Timer.new()
	access_token_timer.autostart = false
	access_token_timer.one_shot = true
	access_token_timer.wait_time = ACCESS_TOKEN_LIFE_TIME
	access_token_timer.timeout.connect(_on_access_token_timeout)
	add_child(access_token_timer)

func  _on_access_token_timeout() -> void:
	var result = UserInfo.get_user_info()
	sign_in(result.username, result.password)
