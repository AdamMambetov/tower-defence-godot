extends Node


signal new_data_received(result: Dictionary)
signal socket_closed()


const WS_BASE_URL = "ws://26.186.139.15:8100/ws/"
const PLAY_ROOM_URL = "play_room"
const WAITING_ROOM_URL = "waiting_room"

var socket: WebSocketPeer
var waiting_opponent: bool
var prev_state = -1


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
			while socket.get_available_packet_count():
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
						_playing_game_process(json)
		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			socket = null
			prints("Connection closed","CODE:",code,"Reason:",reason)
			socket_closed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(socket):
			socket.close()
		socket = null


func spawn_unit(unit_name: String) -> void:
	if !is_instance_valid(socket):
		printerr("spawn_unit: socket not valid")
		return
	
	var info = {
		type = "spawn",
		unit_name = unit_name,
	}
	var error = socket.send_text(JSON.stringify(info))
	if error:
		printerr(error)

# to_id - String or Array[String]
func attack(from_id: String, to_id) -> void:
	if !is_instance_valid(socket):
		printerr("attack: socket not valid")
		return

	socket.send_text(JSON.stringify({
		type = "attack",
		from = from_id,
		to = to_id if typeof(to_id) == TYPE_ARRAY else [to_id],
	}))

func connect_to_url(join_url: String) -> bool:
	socket = WebSocketPeer.new()
	socket.handshake_headers = PackedStringArray([
		"access: " + UserInfo.get_user_info().access,
	])
	var err = socket.connect_to_url(join_url)
	if err != OK:
		printerr("Failed to initiate websocket:", err)
		return false

	var start_time = Time.get_ticks_msec()
	while socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		socket.poll()
		await get_tree().process_frame
		if Time.get_ticks_msec() - start_time > 5000:
			printerr("WebSocket timeout")
			return false
	prints("WebSocket connected:", join_url)
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN

func construct_url(...args) -> String:
	var res = WS_BASE_URL
	for a in args:
		res += str(a) + "/"
	return res

func reconnect() -> void:
	await connect_to_url(construct_url("splay_room", UserInfo.get_room_id()))


func _waiting_game_process(json: Dictionary) -> void:
	if waiting_opponent and json.has("room_id"):
		waiting_opponent = false
		UserInfo.set_room_id(json.room_id)
		for i in 3:
			if await connect_to_url(construct_url(WS.PLAY_ROOM_URL, json.room_id)):
				Global.game_state = Global.GameState.PlayingGame
				Api.join_result.emit(true, "")
				await get_tree().create_timer(1.0).timeout
				return
		socket = null
		Global.game_state = Global.GameState.Menu
		Api.join_result.emit(false, "Не удалось найти противника.")
	else:
		prints("Received other message: ", json)

func _playing_game_process(json: Dictionary) -> void:
	new_data_received.emit(json)
