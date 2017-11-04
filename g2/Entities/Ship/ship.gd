extends Area2D

onready var game = get_tree().get_root().get_node("game")

func death(area):
	game.death()
	#print(get_name(), " <-> ", area.get_name())

func _ready():
	set_process(true)

func _process(delta):
	var v = Vector2(0.0, -1.0).rotated(get_rot())
	var new_pos = get_pos()
	var delta_rad = 0.0
	var f1 = 280.0
	var f2 = 4.0
	if Input.is_action_pressed("ui_up"):
		new_pos += v * delta * f1
	if Input.is_action_pressed("ui_down"):
		new_pos -= v * delta * f1
	if Input.is_action_pressed("ui_left"):
		delta_rad += delta * f2
	if Input.is_action_pressed("ui_right"):
		delta_rad -= delta * f2

	if Input.is_action_pressed("ui_select"):
		var bullet = preload("../Bullet/bullet.tscn").instance()
		get_parent().add_child(bullet)
		bullet.v_ = v * delta * f1 * 1.3
		bullet.set_pos(get_transform() * Vector2(0.0, -45.0))

	set_pos(new_pos)
	rotate(delta_rad)

func _on_ShipArea2D_area_enter( area ):
	death(area)
