extends "res://Scenes/Stage/Stage.gd"

func _ready():
	if Globals.survival_level != null:
		$SoftPlatform1.free()
		$SoftPlatform2.free()
		$MPlatform1.free()
		$MPlatform2.free()
