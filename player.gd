extends Sprite

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	pass

func _process(delta):
	var v = Vector2(0.0, -1.0).rotated(get_rot())
	var new_pos = get_pos()
	var delta_rad = 0.0
	var f1 = 300.0
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
		var bullet = Sprite.new()
		get_parent().add_child(bullet)
		bullet.set_texture(preload("bullet.png"))
		bullet.set_script(preload("bullet.gd"))
		bullet.v_ = v * delta * f1 * 1.2
		bullet.set_pos(get_pos())
		bullet.notification(NOTIFICATION_READY)

	set_pos(new_pos)
	rotate(delta_rad)
