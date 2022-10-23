extends "res://Scenes/Stage/MovingPlatform.gd"

const PERIOD = 300


func _ready():
	add_to_group("MovingPlatforms")
	

# return and load a bool for vanishing platform
func movement_pattern():
	
	var in_unit_offset = posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) / float(PERIOD) * 100 # 100 for easier setting of pattern
	
	if in_unit_offset < 50:
		return false
	else:
		return true
