extends "res://Scenes/Stage/Stage.gd"

const NAME = "Grid"
#var music = {
#		"name" : "survival_test", # to not play the same music as the one currently being played
#		"audio_filename" : "res://Assets/Music/Survival1.ogg",
#		"loop_end": 157.09,
#		"vol" : -4,
#	}

func _ready():
	if Globals.survival_level != null:
		$SoftPlatform1.free()
		$SoftPlatform2.free()
		$MPlatform1.free()
		$MPlatform2.free()
