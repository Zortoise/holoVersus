extends "res://Scenes/Stage/MovingPlatform.gd"

const TYPE = Em.moving_platform.MOVING
const PERIOD = 800


func _ready():
	add_to_group("MovingPlatforms")

# convert current frametime into unit_offset
func movement_pattern():
	
# warning-ignore:integer_division
	var time_ref : int = (posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) * 400) / PERIOD
# warning-ignore:integer_division
	var segment: int = time_ref / 100
	var sub_time: int = posmod(time_ref, 100)
	
	match segment:
		0:
			return $Waypoints/A.position
		1:
			var target_pos := FVector.new()
			target_pos.x = FMath.sin_lerp($Waypoints/A.position.x * FMath.S, $Waypoints/B.position.x * FMath.S, sub_time)
			target_pos.y = $Waypoints/A.position.y * FMath.S
			return target_pos.convert_to_vec()
		2:
			return $Waypoints/B.position
		3:
			var target_pos := FVector.new()
			target_pos.x = FMath.sin_lerp($Waypoints/B.position.x * FMath.S, $Waypoints/A.position.x * FMath.S, sub_time)
			target_pos.y = $Waypoints/A.position.y * FMath.S
			return target_pos.convert_to_vec()
	
	
#	var in_unit_offset = posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) / float(PERIOD) * 100 # 100 for easier setting of pattern
#
#	if in_unit_offset < 25:
#		return 0
#
#	if in_unit_offset < 50:
#		return Globals.sin_lerp(0.0, 1.0, (in_unit_offset - 25) / 25.0)
#
#	if in_unit_offset < 75:
#		return 1
#
#	else:
#		return Globals.sin_lerp(1.0, 0.0, (in_unit_offset - 75) / 25.0)
		



