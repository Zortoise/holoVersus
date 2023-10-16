extends "res://Scenes/Stage/Stage.gd"

const NAME = "Amahara"

const MUSIC = {
		"name" : "Survival Theme",
		"artist" : "Zortoise",
		"audio" : "res://Assets/Music/Survival1.ogg",
		"loop_end": 157.09,
		"vol" : -4,
	}
	
var time = 0.0 # for scrolling clouds

func _ready():
	if Globals.survival_level != null:
		$SoftPlatform1.free()
		$SoftPlatform2.free()
		

func _physics_process(delta):

	if !Globals.Game.is_stage_paused():
		time += delta
		
		$MainPlatform/Frontcloud.material.set_shader_param("time", time)
		$MainPlatform/Frontcloud2.material.set_shader_param("time", time)
		$ParallaxBackground/ParallaxLayer2/Midcloud.material.set_shader_param("time", time)
		$ParallaxBackground/ParallaxLayer2/Midcloud2.material.set_shader_param("time", time)	
		
