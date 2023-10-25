extends "res://Scenes/Stage/StageParticleSpawner.gd"


func _ready():
	hide()
	interval = 0.6 # in seconds
	
	particle_scene = load("res://Stages/Aurora/ShootingStar.tscn")
	particle_data = {
		
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
