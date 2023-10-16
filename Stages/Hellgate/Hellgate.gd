extends "res://Scenes/Stage/Stage.gd"

const NAME = "Hellgate"

const MUSIC = {
		"name" : "Survival1",
		"audio" : "res://Assets/Music/Survival1.ogg",
		"loop_end": 157.09,
		"vol" : -4,
	}

func _ready():
	if Globals.survival_level != null:
		$MPlatform.free()


func _physics_process(_delta):
	
	if Globals.Game.is_stage_paused():
		$ParallaxBackground/ParallaxLayer2/Eyes/AnimationPlayer.stop(false)
		$ParallaxBackground/ParallaxLayer2/Speakers/AnimationPlayer.stop(false)
		$ParallaxBackground/ParallaxLayer2/Speakers/AnimationPlayer2.stop(false)
	else:
		$ParallaxBackground/ParallaxLayer2/Eyes/AnimationPlayer.play()
		$ParallaxBackground/ParallaxLayer2/Speakers/AnimationPlayer.play()
		$ParallaxBackground/ParallaxLayer2/Speakers/AnimationPlayer2.play()
