extends CanvasLayer

onready var GameManager = get_node("/root/GameManager")
onready var context = get_node("VBoxContainer/Context")
onready var menu_box_container = get_node("VBoxContainer")
onready var parallax_camera = get_node("ParallaxBackground/Camera2D")
onready var sfx = get_node("SamplePlayer")
onready var credits_dialog = get_node("CreditsDialog")
onready var title = get_node("Title")

# buttons
onready var start_button = get_node("VBoxContainer/StartButton")
onready var restart_button = get_node("VBoxContainer/RestartButton")
onready var options_button = get_node("VBoxContainer/OptionsButton")
onready var options_fullscreen_button = get_node("VBoxContainer/OptionsFullScreenButton")
onready var options_music_button = get_node("VBoxContainer/OptionsMusicButton")
onready var options_sfx_button = get_node("VBoxContainer/OptionsSfxButton")
onready var options_return_button = get_node("VBoxContainer/OptionsReturnButton")
onready var credits_button = get_node("VBoxContainer/CreditsButton")
onready var quit_button = get_node("VBoxContainer/QuitButton")


const mid_game_menu_y = 200
const mid_game_title_y = 90

enum MODE {
	start,
	pause,
	game_over,
	win
}
var mode = MODE.start

# level interface, GameManager uses these:
func level_won():
	return false
func level_lost():
	return false
func get_hud():
	return null

func _ready():
	GameManager.download_highscores()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if (mode != MODE.start):
		menu_box_container.set_pos(Vector2(menu_box_container.get_pos().x, mid_game_menu_y))
		title.set_pos(Vector2(title.get_pos().x, mid_game_title_y))
		parallax_camera.clear_current()
		get_node("Instructions").hide()
		get_node("PauseBG").show()
	start_button.grab_focus()
	if mode == MODE.start:
		pass
	elif mode == MODE.pause:
		context.set_text("Paused")
		start_button.set_text("Continue")
		restart_button.show()
	elif mode == MODE.game_over:
		context.set_text("GAME OVER")
		start_button.set_text("Try again")
		restart_button.hide()
		show_popup_and_get_name()
	elif mode == MODE.win:
		context.set_text("WIN")
		start_button.set_text("Play again")
		restart_button.hide()
		show_popup_and_get_name()
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if options_return_button.is_visible():
			_on_OptionsReturnButton_pressed()
		elif credits_dialog.is_visible():
			credits_dialog.hide()
		else:
			if mode == MODE.pause:
				GameManager.unpause(self)

func update_highscores(result_string):
	get_node("VBoxContainer/Highscores").update_highscores(result_string)

func highscores_download_started():
	get_node("VBoxContainer/Highscores").highscores_download_started()

func _on_Start_Button_pressed():
	if mode == MODE.pause:
		GameManager.unpause(self)
	else:
		GameManager.start_game()

func _on_QuitButton_pressed():
	GameManager.quit_game()

func _on_RestartButton_pressed():
	GameManager.unpause(self)
	GameManager.start_game()

func _on_NameDialog_confirmed():
	var name = get_node("NameDialog/LineEdit").get_text()
	GameManager.download_highscores({"name": name, "score": str(GameManager.score)})

func show_popup_and_get_name():
	get_node("NameDialog/FinalScore").set_text("Final score: " + str(GameManager.score))
	get_node("NameDialog").register_text_enter(get_node("NameDialog/LineEdit"))
	get_node("NameDialog").popup_centered()
	get_node("NameDialog/LineEdit").grab_focus()

func _on_CreditsButton_pressed():
	credits_dialog.popup()
	
####### options
var options_state_start = false
var options_state_restart = false
func _on_OptionsFullScreenButton_pressed():
	GameManager.set_full_screen(!GameManager.full_screen)
	update_options_buttons()

func _on_OptionsMusicButton_pressed():
	var new_level = (GameManager.music_level + 1) % 11
	GameManager.set_music_level(new_level)
	update_options_buttons()
	
func _on_OptionsSfxButton_pressed():
	var new_level = (GameManager.sfx_level + 1) % 11
	GameManager.set_sfx_level(new_level)
	sfx.play("sfx_laser1")
	update_options_buttons()
	
func update_options_buttons():
	options_music_button.set_text("Music Volume: " + String(GameManager.music_level))
	options_sfx_button.set_text("Sfx Volume: " + String(GameManager.sfx_level))
	if GameManager.full_screen:
		options_fullscreen_button.set_text("Go Window Mode")
	else:
		options_fullscreen_button.set_text("Go Full Screen")

func _on_OptionsButton_pressed():
	# store menu
	options_state_start = false
	if start_button.is_visible():
		options_state_start = true
	options_state_restart = false
	if restart_button.is_visible():
		options_state_restart = true
	# hide menu
	start_button.hide()
	restart_button.hide()
	options_button.hide()
	credits_button.hide()
	quit_button.hide()
	# show options
	options_fullscreen_button.show()
	options_music_button.show()
	options_sfx_button.show()
	options_return_button.show()
	update_options_buttons()
	options_return_button.grab_focus()

func _on_OptionsReturnButton_pressed():
	# hide options
	options_fullscreen_button.hide()
	options_music_button.hide()
	options_sfx_button.hide()
	options_return_button.hide()
	# restore menu
	if options_state_start:
		start_button.show()
	if options_state_restart:
		restart_button.show()
	options_button.show()
	if not get_tree().is_paused():
		credits_button.show()
	credits_button.show()
	quit_button.show()
	options_button.grab_focus()

func _on_MusicLink_pressed():
	OS.shell_open("http://dig.ccmixter.org/files/cdk/34152")

func _on_KenneyLink_pressed():
	OS.shell_open("http://www.kenney.nl")

func _on_ProjectLink_pressed():
	OS.shell_open("https://godotrobot.itch.io/warp")

func _on_CreditsDialog_confirmed():
	pass
