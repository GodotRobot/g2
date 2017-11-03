extends RigidBody2D

var time_to_course
var course

func init_course():
	time_to_course = randf() * 5.0 # 0..10 secs
	course = Vector2(rand_range(-1, 1), rand_range(-1, 1))
	course *= 2.0 * rand_range(1.0, 5.0)

func _ready():
	init_course()
	rotate(PI)
	# Called every time the node is added to the scene.
	# Initialization here
	set_process(true)
	
func _process(delta):
	time_to_course -= delta
	if time_to_course < 0.0:
		init_course()
	var local_change = delta * 80.0 * Vector2(rand_range(-1, 1), rand_range(-1, 1))
	var new_pos = get_pos() + course + local_change
	if new_pos.x < 0:
		new_pos.x = 0
		course.x = -course.x
	if new_pos.y < 0:
		new_pos.y = 0
		course.y = -course.y
	if new_pos.x > get_viewport_rect().size.x:
		new_pos.x = get_viewport_rect().size.x
		course.x = -course.x
	if new_pos.y > get_viewport_rect().size.y:
		new_pos.y = get_viewport_rect().size.y
		course.y = -course.y
	set_pos(new_pos)
