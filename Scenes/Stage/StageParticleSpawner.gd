extends ColorRect

var particle_scene # set by script extending this
var particle_data = { # set by script extending this
}

#	particle_data = {
#		"speed" : speed,
#		"direction" : angle,	 # only needed if speed != 0
#		"loop" : false, 		# if true will keep looping till it goes off stage
#		"sway_amount" : Vector2,
#		"sway_period" : in seconds		# only needed if sway_amount != 0
#		"ease" : 0.0 to 1.0 	# will start at ease * speed and accelerate to full at half total frames
#		"fade_frames" : int		# number of frames after start and before end to fade in/out
#	}

var interval # set by script extending this
#var count := 1 # set by script extending this

var time := 0.0


func _physics_process(delta):
	
	if Globals.Game.is_stage_paused(): return
	
	time += delta
	if time >= interval:
		time = 0.0
		spawn()
		
		
func spawn(offset = false):
# warning-ignore:unassigned_variable
	var spawn_pos: Vector2
	spawn_pos.x = round(Globals.random.randf() * rect_size.x + rect_position.x)
	spawn_pos.y = round(Globals.random.randf() * rect_size.y + rect_position.y)
	
	var particle = particle_scene.instance()
	get_parent().add_child(particle)
	particle.position = spawn_pos
	particle.init(particle_data, offset)
	
func initial_spawn():
	var number_to_spawn = ceil(2 / float(interval))
	for x in number_to_spawn:
		spawn(true)

	

