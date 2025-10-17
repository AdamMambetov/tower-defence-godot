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


func _on_start_btn_pressed() -> void:
	menu_state = MenuState.Game

func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.

func _on_account_btn_pressed() -> void:
	menu_state = MenuState.Accounts

func _on_exit_btn_pressed() -> void:
	get_tree().quit()

func _on_go_sign_up_btn_pressed() -> void:
	$AccountsPopup/Background/SignIn.visible = false
	$AccountsPopup/Background/SignUp.visible = true
	username = $AccountsPopup/Background/SignUp/username_le.text
	password = $AccountsPopup/Background/SignUp/password_le.text

func _on_go_sign_in_btn_pressed() -> void:
	$AccountsPopup/Background/SignIn.visible = true
	$AccountsPopup/Background/SignUp.visible = false
	username = $AccountsPopup/Background/SignIn/username_le.text
	password = $AccountsPopup/Background/SignIn/password_le.text

func _on_sign_up_btn_pressed() -> void:
	Api.sign_up(username, email, password)
	var res = await Api.sign_result
	if res:
		menu_state = MenuState.None

func _on_sign_in_btn_pressed() -> void:
	Api.sign_in(username, password)
	var res = await Api.sign_result
	if res:
		menu_state = MenuState.None

func _on_password_le_text_changed(new_text: String) -> void:
	password = new_text

func _on_email_le_text_changed(new_text: String) -> void:
	email = new_text

func _on_username_le_text_changed(new_text: String) -> void:
	username = new_text

func _on_play_random_btn_pressed() -> void:
	Api.join()
	$LoadingScreen.visible = true
	var success = await Api.join_result
	$LoadingScreen.visible = false
	if success:
		get_tree().change_scene_to_file("res://scene/main_map.tscn")
	else:
		print("NOOOOOOOOOOOOOOO111!!!!!!")

func _on_play_friend_btn_pressed() -> void:
	pass # Replace with function body.
