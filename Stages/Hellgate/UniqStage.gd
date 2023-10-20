extends "res://Scenes/Stage/Stage.gd"

const NAME = "Hellgate"

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
