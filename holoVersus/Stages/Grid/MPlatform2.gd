extends "res://Scenes/Stage/MovingPlatform.gd"

const PERIOD = 300


func movement_pattern():
	
# warning-ignore:integer_division
	var time_ref : int = (posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) * 100) / PERIOD
# warning-ignore:integer_division
	var segment: int = time_ref / 50
#	var sub_time: int = posmod(time_ref, 50)
	
	match segment:
		0:
			return {"type":Em.mov_platform.ACTIVATE, "active":true}
		1:
			return {"type":Em.mov_platform.ACTIVATE, "active":false}
	
#
#	var in_unit_offset = posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) / float(PERIOD) * 100 # 100 for easier setting of pattern
#
#	if in_unit_offset < 50:
#		return false
#	else:
#		return true
