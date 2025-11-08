extends Control


enum MenuState {
	None,
	Game,
	Accounts,
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

var accounts_state: AccountsState:
	set(value):
		accounts_state = value
		$AccountsMenu/SignUp.visible = accounts_state == AccountsState.SignUp
		$AccountsMenu/SignIn.visible = accounts_state == AccountsState.SignIn
		$AccountsMenu/Profile.visible = accounts_state == AccountsState.Profile


func _ready() -> void:
	if UserInfo.get_user_info().is_empty():
		accounts_state = AccountsState.SignIn
	else:
		$LoadingScreen.visible = true
		var success = await Api.update_access_token()
		if !success:
			accounts_state = AccountsState.SignIn
			$LoadingScreen.visible = false
			return
		
		var user_info = await Api.get_user_info()
		if user_info.has("detail"):
			accounts_state = AccountsState.SignIn
			$LoadingScreen.visible = false
			return
		update_profile(user_info)
		accounts_state = AccountsState.Profile
		$LoadingScreen.visible = false


func _show_accept_dialog(dialog_text: String) -> void:
	$AcceptDialog.dialog_text = dialog_text
	$AcceptDialog.reset_size()
	$AcceptDialog.show()

func update_profile(user_info: Dictionary) -> void:
	$AccountsMenu/Profile/id_label.text = "ID: %s" % str(user_info.id)
	$AccountsMenu/Profile/username_label.text = "Имя пользователя: %s" % user_info.username
	$AccountsMenu/Profile/email_label.text = "Почта: %s" % user_info.email


func _on_start_btn_pressed() -> void:
	menu_state = MenuState.Game

func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.

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
	var dialog_text = res[1]
	if !res[0]:
		$LoadingScreen.visible = false
		_show_accept_dialog(dialog_text)
		return
	
	Api.sign_in(username, password)
	res = await Api.sign_result
	if !res[0]:
		dialog_text = res[1]
		$LoadingScreen.visible = false
		_show_accept_dialog(dialog_text)
		return
	
	$LoadingScreen.visible = false
	_show_accept_dialog(dialog_text)
	await $AcceptDialog.confirmed
	accounts_state = AccountsState.Profile

func _on_sign_in_btn_pressed() -> void:
	Api.sign_in(username, password)
	$LoadingScreen.visible = true
	var res = await Api.sign_result
	$LoadingScreen.visible = false
	if res[0]:
		_show_accept_dialog("Вы успешно вошли!")
		await $AcceptDialog.confirmed
		var user_info = await Api.get_user_info()
		if user_info.has("detail"):
			_show_accept_dialog(user_info.detail)
			menu_state = MenuState.None
			return
		accounts_state = AccountsState.Profile
		update_profile(user_info)
	else:
		_show_accept_dialog(res[1])

func _on_password_le_text_changed(new_text: String) -> void:
	password = new_text

func _on_email_le_text_changed(new_text: String) -> void:
	email = new_text

func _on_username_le_text_changed(new_text: String) -> void:
	username = new_text

func _on_play_random_btn_pressed() -> void:
	Api.join()
	$LoadingScreen.visible = true
	var result = await Api.join_result
	$LoadingScreen.visible = false
	if result[0]:
		get_tree().change_scene_to_file("res://scene/main_map.tscn")
	else:
		$AcceptDialog.dialog_text = result[1]
		$AcceptDialog.reset_size()
		$AcceptDialog.show()

func _on_play_friend_btn_pressed() -> void:
	pass # Replace with function body.

func _on_logout_btn_pressed() -> void:
	accounts_state = AccountsState.SignIn
	UserInfo.set_user_info({})
	Api.authorized = false
	Api.access_token_timer.stop()
