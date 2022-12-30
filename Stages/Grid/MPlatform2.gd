extends "res://Scenes/Stage/MovingPlatform.gd"

const TYPE = Globals.moving_platform.WARPING
const PERIOD = 300


func _ready():
	add_to_group("MovingPlatforms")
	

# convert current frametime into unit_offset
func movement_pattern():
	
# warning-ignore:integer_division
	var time_ref : int = (posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) * 100) / PERIOD
# warning-ignore:integer_division
	var segment: int = time_ref / 50
#	var sub_time: int = posmod(time_ref, 50)
	
	match segment:
		0:
			return $Waypoints/A.position
		1:
			return $Waypoints/B.position
	
#
#	var in_unit_offset = posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) / float(PERIOD) * 100 # 100 for easier setting of pattern
#
#	if in_unit_offset < 50:
#		return false
#	else:
#		return true
