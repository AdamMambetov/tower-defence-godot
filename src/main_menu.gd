extends Control


enum MenuState {
	None,
	Game,
	Accounts,
}


var username: String
var email: String
var password: String
var menu_state: MenuState:
	set(value):
		$GameMenu.visible = value == MenuState.Game
		$AccountsMenu.visible = value == MenuState.Accounts


func _show_accept_dialog(dialog_text: String) -> void:
	$AcceptDialog.dialog_text = dialog_text
	$AcceptDialog.reset_size()
	$AcceptDialog.show()


func _on_start_btn_pressed() -> void:
	menu_state = MenuState.Game

func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.

func _on_account_btn_pressed() -> void:
	menu_state = MenuState.Accounts

func _on_exit_btn_pressed() -> void:
	get_tree().quit()

func _on_go_sign_up_btn_pressed() -> void:
	$AccountsMenu/SignIn.visible = false
	$AccountsMenu/SignUp.visible = true
	username = $AccountsMenu/SignUp/username_le.text
	password = $AccountsMenu/SignUp/password_le.text

func _on_go_sign_in_btn_pressed() -> void:
	$AccountsMenu/SignIn.visible = true
	$AccountsMenu/SignUp.visible = false
	username = $AccountsMenu/SignIn/username_le.text
	password = $AccountsMenu/SignIn/password_le.text

func _on_sign_up_btn_pressed() -> void:
	Api.sign_up(username, email, password)
	$LoadingScreen.visible = true
	var res = await Api.sign_result
	var dialog_text = res[1]
	if res[0]:
		Api.sign_in(username, password)
		res = await Api.sign_result
		if !res[0]:
			dialog_text = res[1]
	$LoadingScreen.visible = false
	_show_accept_dialog(dialog_text)

func _on_sign_in_btn_pressed() -> void:
	Api.sign_in(username, password)
	$LoadingScreen.visible = true
	var res = await Api.sign_result
	$LoadingScreen.visible = false
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
