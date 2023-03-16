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
			target_pos.x = $Waypoints/A.position.x * FMath.S
			target_pos.y = FMath.sin_lerp($Waypoints/A.position.y * FMath.S, $Waypoints/B.position.y * FMath.S, sub_time)
			return target_pos.convert_to_vec()
		2:
			return $Waypoints/B.position
		3:
			var target_pos := FVector.new()
			target_pos.x = $Waypoints/B.position.x * FMath.S
			target_pos.y = FMath.sin_lerp($Waypoints/B.position.y * FMath.S, $Waypoints/A.position.y * FMath.S, sub_time)
			return target_pos.convert_to_vec()


