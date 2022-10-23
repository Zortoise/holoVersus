extends "res://Scenes/Stage/MovingPlatform.gd"

const PERIOD = 800


func _ready():
	add_to_group("MovingPlatforms")


# convert current frametime into unit_offset
func movement_pattern():
	
	var in_unit_offset = posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) / float(PERIOD) * 600
	
	if in_unit_offset < 100:
		return lerp(0, 0.25, in_unit_offset/100)
		
	elif in_unit_offset <= 200:
		return 0.25
		
	elif in_unit_offset <= 400:
		return lerp(0.25, 0.75, (in_unit_offset - 200)/200)
		
	elif in_unit_offset <= 500:
		return 0.75
		
	else:
		return lerp(0.75, 1.0, (in_unit_offset - 500)/100)
