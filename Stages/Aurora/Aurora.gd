extends "res://Scenes/Stage/Stage.gd"

const NAME = "Aurora"

const MUSIC = {
		"name" : "Lamy's Theme",
		"artist" : "Zortoise",
		"audio" : "res://Stages/Aurora/Resources/LamyTheme.ogg",
#		"loop_start": 1.6,
		"loop_end": 179.2,
		"vol" : -4,
	}

func _ready():
	if Globals.survival_level != null:
		$MPlatform1.free()
		$MPlatform2.free()
		$MPlatform3.free()
