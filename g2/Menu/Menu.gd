extends Node2D

onready var game = get_tree().get_root().get_node("game")

func _ready():
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		game.unpause(self)
