extends CanvasLayer

onready var time_text = get_node("HUD/Time")
onready var level_text = get_node("HUD/Level")
onready var score_text = get_node("HUD/Score")
onready var lives_container = get_node("HUD/LivesLeft")

onready var warp_container = get_node("HUD/WarpsLeft")
onready var warp_label = get_node("HUD/WarpLabel")
onready var warp_critical_alert = get_node("HUD/WarpCriticalAlert")

onready var warp_container_warp = null
onready var warp_container_sep = null

func _ready():
	warp_container_warp = get_node("HUD/WarpIcon").duplicate()
	warp_container_sep = get_node("HUD/WarpSep").duplicate()
	

func set_level(level):
	level_text.set_text(str(level).pad_zeros(2))

func calc_warps():
	var children = warp_container.get_children()
	return children.size() / 2
	
func set_warps(count):
	var warps_to_add = count - calc_warps()
	if warps_to_add == 0:
		if warp_container.get_children().empty():
			warp_label.hide()
			warp_critical_alert.show()	
		return
	elif warps_to_add > 0:
		add_warps(warps_to_add)
	else:
		remove_warps(warps_to_add)

func add_warps(count):
	warp_label.show()
	warp_critical_alert.hide()
	for i in range(count):
		var new_warp = warp_container_warp.duplicate()
		var new_sep = warp_container_sep.duplicate()
		new_warp.show()
		warp_container.add_child(new_warp) # icon
		warp_container.add_child(new_sep) # separator

func remove_warps(count):
	var children = warp_container.get_children()
	if children.empty():
		return
		
	for i in range(count):
		warp_container.remove_child(children[children.size()-1]) # icon
		warp_container.remove_child(children[children.size()-2]) # separator
	
	if warp_container.get_children().empty():
		warp_label.hide()
		warp_critical_alert.show()
	return true

func set_score(points):
	score_text.set_text(str(points).pad_zeros(4))

func set_time(time):
	time_text.set_text(str(time).pad_zeros(2))

func calc_lifes():
	var children = lives_container.get_children()
	return children.size() / 2

func set_lives(count):
	var lives_to_add = count - calc_lifes()
	if lives_to_add == 0:
		return
	elif lives_to_add > 0:
		add_life(lives_to_add)
	else:
		remove_life(lives_to_add)

func add_life(count):
	for i in range(count):
		lives_container.add_child(get_node("HUD/LivesLeft/Life").duplicate()) # icon
		lives_container.add_child(get_node("HUD/LivesLeft/Sep").duplicate()) # separator

func remove_life(count):
	var children = lives_container.get_children()
	if children.empty():
		return false
	for i in range(count):
		lives_container.remove_child(children[children.size()-1]) # icon
		lives_container.remove_child(children[children.size()-2]) # separator
	return true


func _on_CheckBox_toggled( pressed ):
	GameManager.debug = pressed