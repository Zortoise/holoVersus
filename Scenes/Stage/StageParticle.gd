extends AnimatedSprite


var origin: Vector2
var sway_offset_start: = 0.0 # from 0.0 to 1.0
var particle_data := {}

var time := 0.0


func init(in_particle_data, offset = false):
	
#	particle_data = {
#		"speed" : speed,
#		"direction" : angle,	 # only needed if speed != 0
#		"loop" : false, 		# if true will keep looping till it goes off stage
#		"sway_amount" : Vector2,
#		"sway_period" : in seconds		# only needed if sway_amount != 0
#		"ease" : 0.0 to 1.0 	# will start at ease * speed and accelerate to full at half total frames
#		"fade_frames" : int		# number of frames after start and before end to fade in/out
#	}

	particle_data = in_particle_data
	origin = position
		
	if "loop" in particle_data:
		frames.set_animation_loop("default", true)
	else: # no loop, queue_free when loop ends
		frames.set_animation_loop("default", false)
# warning-ignore:return_value_discarded
		connect("animation_finished", self, "queue_free")
		
	if "sway_amount" in particle_data:
		time = Globals.random.randf() *  particle_data.sway_period # randomize sway starting point
		
	play("default")
	
	if !offset:
		frame = 0
	else: # initial spawn, spawn with an offset on frames
		frame = Globals.random.randi_range(0, frames.get_frame_count("default") - 1)
		
		
func _physics_process(delta):

	if "speed" in particle_data:
		if !"ease" in particle_data:
			origin += Vector2(particle_data.speed * delta, 0).rotated(particle_data.direction)
		else: # start from ease * speed, accelerate to full speed at half total frames
			var weight = abs(frame - frames.get_frame_count("default") * 0.5) / (frames.get_frame_count("default") * 0.5)
			var new_speed = lerp(particle_data.speed, particle_data.speed * particle_data.ease, weight)
			origin += Vector2(new_speed * delta, 0).rotated(particle_data.direction)
		position = origin
	
		if "sway_amount" in particle_data:
			time += delta
			if time > particle_data.sway_period:
				time = 0.0
				
			var weight = sin((time / float(particle_data.sway_period)) * TAU) # get a value between -1.0 and 1.0 based on time
			position = lerp(origin + particle_data.sway_amount, origin, weight)
		else:
			position = origin
			
# warning-ignore:unassigned_variable
		var detect_box: Rect2 # get a larger box
		detect_box.position = Globals.Game.stage_box.rect_global_position
		detect_box.position -= Vector2(128, 128)
		detect_box.size = Globals.Game.stage_box.rect_size
		detect_box.size += Vector2(256, 256)
		if !detect_box.has_point(position):
			queue_free() # if moved out of bound, remove the particle
		
		
	if "fade_frames" in particle_data: # number of frames after start and before end to fade in/out
		if frame < particle_data.fade_frames: # at beginning
			var weight = (frame + 1) / float(particle_data.fade_frames + 1)
			modulate.a = lerp(0.0, 1.0, weight)
		elif frame >= frames.get_frame_count("default") - particle_data.fade_frames: # at end
			var weight = (frames.get_frame_count("default") - frame) / float(particle_data.fade_frames + 1)
			modulate.a = lerp(0.0, 1.0, weight)
		else:
			modulate.a = 1.0
