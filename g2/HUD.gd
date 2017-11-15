extends CanvasLayer

onready var timer = get_node("HUD/TimeLeft")
onready var ammo_text = get_node("HUD/Ammo")
onready var level_text = get_node("HUD/Level")
onready var lives_container = get_node("HUD/LivesLeft")

const LEVEL_NAME = ['kill', 'kill', 'bounce', 'survive']

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func add_life(count):
	for i in range(count - 1):
		get_node("HUD/LivesLeft").add_child(get_node("HUD/LivesLeft/Life").duplicate()) # icon
		get_node("HUD/LivesLeft").add_child(get_node("HUD/LivesLeft/Sep").duplicate()) # separator

func remove_life():
	var children = lives_container.get_children()
	if children.empty():
		return false
	lives_container.remove_child(children[children.size()-1]) # icon
	lives_container.remove_child(children[children.size()-2]) # separator
	return true

func update_timer(left_ratio):
	timer.set_value(timer.get_max() * left_ratio)

func update_ammo(count):
	ammo_text.set_text(String(count))

func update_level(level):
	level_text.set_text("Level " + String(level) + ": " + LEVEL_NAME[level-1])
	level_text.show()