extends "res://Scenes/Stage/Stage.gd"

const NAME = "Waterfall"

func _ready():
	
	if Globals.survival_level != null:
		$MPlatform1.free()
		$MPlatform2.free()


func _physics_process(_delta):

	if Globals.Game.is_stage_paused():
		$MainPlatform/AnimatedSprite.stop()
		$MainPlatform/AnimatedSprite2.stop()
		$MainPlatform/TextureRect.texture.pause = true
	else:
		$MainPlatform/AnimatedSprite.play()
		$MainPlatform/AnimatedSprite2.play()
		$MainPlatform/TextureRect.texture.pause = false
