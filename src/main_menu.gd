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
}

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
		$AccountsMenu/Profile.visible = accounts_state == AccountsState.Profile

@export var _warning_menu_path: NodePath
@onready var warning_menu: WarningMenu = get_node(_warning_menu_path)


func _ready() -> void:
	init_audio_player()
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
		#await WS.reconnect()
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
