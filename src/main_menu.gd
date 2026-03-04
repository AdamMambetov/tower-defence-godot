extends Control


enum MenuState {
	None,
	Game,
	Accounts,
	Settings,
}

enum AccountsState {
	SignUp,
	SignIn,
	Profile,
	Friends,
	FriendRequests,
}

const FRIEND = preload("res://scene/friend_item.tscn")
const FRIEND_REQUEST = preload("res://scene/friend_request_item.tscn")

var username: String
var email: String
var password: String
var menu_state: MenuState:
	set(value):
		menu_state = value
		$GameMenu.visible = menu_state == MenuState.Game
		$AccountsMenu.visible = menu_state == MenuState.Accounts
		$SettingsMenu.visible = menu_state == MenuState.Settings

var accounts_state: AccountsState:
	set(value):
		accounts_state = value
		$AccountsMenu/SignUp.visible = accounts_state == AccountsState.SignUp
		$AccountsMenu/SignIn.visible = accounts_state == AccountsState.SignIn
		$AccountsMenu/ProfileTabs.visible = accounts_state != AccountsState.SignIn \
				and accounts_state != AccountsState.SignUp
		$AccountsMenu/Profile.visible = accounts_state == AccountsState.Profile
		$AccountsMenu/Friends.visible = accounts_state == AccountsState.Friends
		$AccountsMenu/FriendRequests.visible = accounts_state == AccountsState.FriendRequests
		
		get_button_shader(profile_button).set_shader_parameter(
			"active",
			accounts_state == AccountsState.Profile,
		)
		get_button_shader(friends_button).set_shader_parameter(
			"active",
			accounts_state == AccountsState.Friends,
		)
		get_button_shader(friend_request_button).set_shader_parameter(
			"active",
			accounts_state == AccountsState.FriendRequests,
		)


@export var _warning_menu_path: NodePath
@onready var warning_menu: WarningMenu = get_node(_warning_menu_path)

@export var _friend_container_path: NodePath
@onready var friend_container: Node = get_node(_friend_container_path)

@export var _friend_request_container_path: NodePath
@onready var friend_request_container: Node = get_node(_friend_request_container_path)

@export var _profile_button_path: NodePath
@onready var profile_button: TextureButton = get_node(_profile_button_path)

@export var _friends_button_path: NodePath
@onready var friends_button: TextureButton = get_node(_friends_button_path)

@export var _friend_request_button_path: NodePath
@onready var friend_request_button: TextureButton = get_node(_friend_request_button_path)


func _ready() -> void:
	OnlineWS.new_data_received.connect(_on_OnlineWS_new_data_received)
	init_audio_player()
	clear_friends()
	clear_friend_requests()
	
	accounts_state = AccountsState.SignIn
	if !Cache.get_user_info().is_empty():
		$LoadingScreen.visible = true
		var success = await Api.update_access_token()
		if !success:
			$LoadingScreen.visible = false
			return
		
		var user_info = await Api.get_user_info()
		if user_info.has("detail"):
			$LoadingScreen.visible = false
			return
		update_profile(user_info)
		accounts_state = AccountsState.Profile
		for i in 3:
			success = await OnlineWS.connect_to_url()
			if success: break
			OnlineWS.socket = null
		if !success:
			_show_warning_menu("У вас плохой интернет!")
		$LoadingScreen.visible = false


func _show_warning_menu(text: String) -> void:
	warning_menu.detail = text
	warning_menu.show_menu()

func update_profile(user_info: Dictionary) -> void:
	$AccountsMenu/Profile/id_label.text = "ID: %s" % str(user_info.id)
	$AccountsMenu/Profile/username_label.text = "Имя пользователя: %s" % user_info.username
	$AccountsMenu/Profile/email_label.text = "Почта: %s" % user_info.email

func init_audio_player() -> void:
	var settings = Cache.get_settings()
	if !settings.is_empty():
		AudioPlayer.set_music_volume(settings.music_volume)
	else:
		settings.music_volume = AudioPlayer.get_music_volume()
		Cache.append_settings(settings)
	AudioPlayer.play_main_menu()
	$SettingsMenu/VBoxContainer/Music/MusicSlider.value = settings.music_volume

func clear_friends() -> void:
	var friends = friend_container.get_children()
	for el in friends:
		friend_container.remove_child(el)
	
func clear_friend_requests() -> void:
	var requests = friend_request_container.get_children()
	for el in requests:
		friend_request_container.remove_child(el)

func add_friend_request_item(user_name: String) -> void:
	var friend_request = FRIEND_REQUEST.instantiate()
	friend_request.username = user_name
	friend_request.on_accept.connect(_on_friend_request_accept)
	friend_request.on_reject.connect(_on_friend_request_reject)
	friend_request_container.add_child(friend_request)

func add_friend_item(user_name: String, is_online: bool) -> void:
	var friend = FRIEND.instantiate()
	friend.username = user_name
	friend.is_online = is_online
	friend_container.add_child(friend)

func get_button_shader(button: TextureButton) -> ShaderMaterial:
	return button.material


func _on_start_btn_pressed() -> void:
	menu_state = MenuState.Game

func _on_settings_btn_pressed() -> void:
	menu_state = MenuState.Settings

func _on_account_btn_pressed() -> void:
	menu_state = MenuState.Accounts

func _on_exit_btn_pressed() -> void:
	get_tree().quit()

func _on_go_sign_up_btn_pressed() -> void:
	accounts_state = AccountsState.SignUp
	username = $AccountsMenu/SignUp/username_le.text
	password = $AccountsMenu/SignUp/password_le.text

func _on_go_sign_in_btn_pressed() -> void:
	accounts_state = AccountsState.SignIn
	username = $AccountsMenu/SignIn/username_le.text
	password = $AccountsMenu/SignIn/password_le.text

func _on_sign_up_btn_pressed() -> void:
	Api.sign_up(username, email, password)
	$LoadingScreen.visible = true
	var res = await Api.sign_result
	var message = res[1]
	if !res[0]:
		$LoadingScreen.visible = false
		_show_warning_menu(message)
		return
	
	Api.sign_in(username, password)
	res = await Api.sign_result
	if !res[0]:
		message = res[1]
		$LoadingScreen.visible = false
		_show_warning_menu(message)
		return
	
	$LoadingScreen.visible = false
	_show_warning_menu(message)
	accounts_state = AccountsState.Profile

func _on_sign_in_btn_pressed() -> void:
	Api.sign_in(username, password)
	$LoadingScreen.visible = true
	var res = await Api.sign_result
	$LoadingScreen.visible = false
	if res[0]:
		_show_warning_menu(res[1])
		var user_info = await Api.get_user_info()
		if user_info.has("detail"):
			_show_warning_menu(user_info.detail)
			menu_state = MenuState.None
			return
		accounts_state = AccountsState.Profile
		update_profile(user_info)
	else:
		_show_warning_menu(res[1])

func _on_password_le_text_changed(new_text: String) -> void:
	password = new_text

func _on_email_le_text_changed(new_text: String) -> void:
	email = new_text

func _on_username_le_text_changed(new_text: String) -> void:
	username = new_text

func _on_play_random_btn_pressed() -> void:
	#if (await Api.check_room_exists()):
		#await GameWS.reconnect()
		#return
	if $LoadingScreen.visible:
		return
	
	Api.join()
	$LoadingScreen.visible = true
	var res = await Api.join_result
	$LoadingScreen.visible = false
	if res[0]:
		get_tree().change_scene_to_file("res://scene/main_map.tscn")
	else:
		_show_warning_menu(res[1])

func _on_play_friend_btn_pressed() -> void:
	pass # Replace with function body.

func _on_logout_btn_pressed() -> void:
	accounts_state = AccountsState.SignIn
	Cache.set_user_info({})
	Api.authorized = false
	Api.access_token_timer.stop()

func _on_music_slider_value_changed(value: float) -> void:
	$SettingsMenu/VBoxContainer/Music/ValueLabel.text = "{0}%".format([int(value)])
	AudioPlayer.set_music_volume(value)
	Cache.append_settings({ music_volume = value })

func _on_exit_button_pressed() -> void:
	menu_state = MenuState.None

func _on_profile_button_pressed() -> void:
	accounts_state = AccountsState.Profile

func _on_friends_button_pressed() -> void:
	accounts_state = AccountsState.Friends

func _on_friend_request_button_pressed() -> void:
	accounts_state = AccountsState.FriendRequests

func _on_OnlineWS_new_data_received(result: Dictionary) -> void:
	print(result)
	match result.type:
		"friends":
			Global.online_friends = result.online_friends.map(func(id): return int(id))
			Global.friends = Global.map(
				result.accepted_friends,
				func(k,v): return { int(k): v },
			)
			clear_friends()
			for id in Global.friends:
				add_friend_item(
					Global.friends[id],
					Global.online_friends.has(id),
				)
			
			Global.friend_requests = Global.map(
				result.pending_friends,
				func(k,v): return { int(k): v },
			)
			clear_friend_requests()
			for user_name in Global.friend_requests.values():
				add_friend_request_item(user_name)
		"new_friend":
			Global.friends[result.friend_id] = result.friend_name
			if result.is_online:
				Global.online_friends.push_back(result.friend_id)
			add_friend_item(result.friend_name, result.is_online)
		"friend_status":
			if result.is_online:
				Global.online_friends.push_back(result.user_id)
			else:
				Global.online_friends.erase(result.user_id)
			var friend_item = friend_container.get_child(
				Global.friends.keys().find(result.user_id),
			)
			friend_item.is_online = result.is_online

func _on_friend_request_accept(request_node: Node, user_name: String) -> void:
	request_node.disable_buttons()
	var msg = await Api.accept_friend(Global.friend_requests.find_key(user_name))
	if !msg.is_empty():
		request_node.enable_buttons()
		_show_warning_menu(msg)
		return
	Global.friend_requests.erase(Global.friend_requests.find_key(user_name))
	friend_request_container.remove_child(request_node)
	request_node = null

func _on_friend_request_reject(request_node: Node, user_name: String) -> void:
	request_node.disable_buttons()
	var msg = await Api.reject_friend(Global.friend_requests.find_key(user_name))
	if !msg.is_empty():
		request_node.enable_buttons()
		_show_warning_menu(msg)
		return
	Global.friend_requests.erase(Global.friend_requests.find_key(user_name))
	friend_request_container.remove_child(request_node)
	request_node = null
