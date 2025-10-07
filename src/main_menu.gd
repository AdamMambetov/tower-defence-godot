extends Control


func _on_start_btn_pressed() -> void:
	pass # Replace with function body.

func _on_settings_btn_pressed() -> void:
	pass # Replace with function body.

func _on_account_btn_pressed() -> void:
	$AccountsPopup.show()

func _on_exit_btn_pressed() -> void:
	get_tree().quit()

func _on_go_sign_up_btn_pressed() -> void:
	$AccountsPopup/Background/SignIn.visible = false
	$AccountsPopup/Background/SignUp.visible = true

func _on_go_sign_in_btn_pressed() -> void:
	$AccountsPopup/Background/SignIn.visible = true
	$AccountsPopup/Background/SignUp.visible = false

func _on_sign_up_btn_pressed() -> void:
	$Api.sign_up(
		$AccountsPopup/Background/SignUp/username_te.text,
		$AccountsPopup/Background/SignUp/email_te.text,
		$AccountsPopup/Background/SignUp/password_te.text,
	)
	var res = await $Api.sign_result
	if res:
		$AccountsPopup.hide()

func _on_sign_in_btn_pressed() -> void:
	$Api.sign_in(
		$AccountsPopup/Background/SignIn/username_te.text,
		$AccountsPopup/Background/SignIn/password_te.text,
	)
	var res = await $Api.sign_result
	if res:
		$AccountsPopup.hide()
