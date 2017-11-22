extends CanvasLayer

onready var GameManager = get_node("/root/GameManager")
onready var start_button = get_node("VBoxContainer/StartButton")
onready var restart_button = get_node("VBoxContainer/RestartButton")
onready var context = get_node("VBoxContainer/Context")
onready var music_player = get_node("StreamPlayer")
onready var parallax_camera = get_node("ParallaxBackground/Camera2D")

enum MODE {
	start,
	pause,
	game_over,
	next_level,
	win
}
var mode = MODE.start

# GameManager won't be able to end this level
func level_won():
	return false
func level_lost():
	return false
func get_hud():
	return null

func _ready():
	GameManager.download_highscores()
	if (mode != MODE.start):
		parallax_camera.clear_current()
		# add a dim background
		get_node("PauseBG").show()

	music_player.play()
	start_button.grab_focus()
	if mode == MODE.pause:
		context.set_text("Paused")
		start_button.set_text("Continue")
		restart_button.show()
		show_popup_and_get_name()

	elif mode == MODE.game_over:
		context.set_text("GAME OVER")
		start_button.set_text("Try again")
		restart_button.hide()
	elif mode == MODE.next_level:
		context.set_text("Level Completed")
		start_button.set_text("Next Level")
		restart_button.hide()
	elif mode == MODE.win:
		context.set_text("WIN")
		start_button.set_text("Play again")
		restart_button.hide()
		show_popup_and_get_name()

	set_process_input(true)

func _input(event):
	if mode == MODE.pause and event.is_action_pressed("ui_cancel"):
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
