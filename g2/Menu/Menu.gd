extends CanvasLayer

onready var game = get_tree().get_root().get_node("game")
onready var start_button = get_node("VBoxContainer/StartButton")
onready var context = get_node("VBoxContainer/Context")

enum MODE {
	start,
	pause,
	game_over,
	next_level,
	win
}
var mode = MODE.start

func _ready():
	if mode == MODE.pause:
		context.set_text("Paused")
		start_button.set_text("Continue")
	elif mode == MODE.game_over:
		context.set_text("GAME OVER")
		start_button.set_text("Restart")
	elif mode == MODE.next_level:
		context.set_text("Level Completed")
		start_button.set_text("Next Level")
	elif mode == MODE.win:
		context.set_text("WIN")
		start_button.set_text("Restart")
	set_process_input(true)

func _input(event):
	if mode == MODE.pause and event.is_action_pressed("ui_cancel"):
		game.unpause(self)

func _on_Start_Button_pressed():
	if mode == MODE.pause:
		game.unpause(self)
	else:
		get_tree().change_scene("res://Game.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()
