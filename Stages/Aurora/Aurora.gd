extends "res://Scenes/Stage/Stage.gd"

func _ready():
	if Globals.survival_level != null:
		$MPlatform1.free()
		$MPlatform2.free()
		$MPlatform3.free()
