extends Node


signal new_data_received(result: Dictionary)
signal socket_closed()


const WS_BASE_URL = "ws://26.186.139.15:8100/ws/online/"

var socket: WebSocketPeer
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
				new_data_received.emit(json)
		WebSocketPeer.STATE_CLOSED:
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			socket = null
			prints("Connection closed", "CODE:", code, "Reason:", reason)
			socket_closed.emit()


func connect_to_url() -> bool:
	socket = WebSocketPeer.new()
	var access_token = Global.get_password("access")
	socket.handshake_headers = PackedStringArray([
		"access: " + access_token,
	])
	var err = socket.connect_to_url(WS_BASE_URL)
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
	prints("WebSocket connected:", WS_BASE_URL)
	return socket.get_ready_state() == WebSocketPeer.STATE_OPEN
