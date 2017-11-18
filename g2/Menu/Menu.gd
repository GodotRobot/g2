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
	if (mode != MODE.start):
		parallax_camera.clear_current()

	music_player.play()
	start_button.grab_focus()
	if mode == MODE.pause:
		context.set_text("Paused")
		start_button.set_text("Continue")
		restart_button.show()
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
		start_button.set_text("Restart")
		restart_button.hide()
	set_process_input(true)

func _input(event):
	if mode == MODE.pause and event.is_action_pressed("ui_cancel"):
		GameManager.unpause(self)

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
