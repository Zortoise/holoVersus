extends "res://Scenes/Stage/MovingPlatform.gd"

const PERIOD = 800


func _ready():
	add_to_group("MovingPlatforms")

# convert current frametime into unit_offset
func movement_pattern():
	
	var in_unit_offset = posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) / float(PERIOD) * 100 # 100 for easier setting of pattern
	
	if in_unit_offset < 25:
		return 0
		
	if in_unit_offset < 50:
		return Globals.sin_lerp(0.0, 1.0, (in_unit_offset - 25) / 25.0)
		
	if in_unit_offset < 75:
		return 1
		
	else:
		return Globals.sin_lerp(1.0, 0.0, (in_unit_offset - 75) / 25.0)
		



