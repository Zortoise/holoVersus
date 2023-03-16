extends "res://Scenes/Stage/MovingPlatform.gd"

const TYPE = Em.moving_platform.MOVING
const PERIOD = 800


func _ready():
	add_to_group("MovingPlatforms")


# convert current frametime into unit_offset
func movement_pattern():
	
# warning-ignore:integer_division
	var time_ref : int = (posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) * 600) / PERIOD
# warning-ignore:integer_division
	var segment: int = time_ref / 100
	var sub_time: int = posmod(time_ref, 100)
	
	match segment:
		0:
			var target_pos := FVector.new()
			target_pos.x = FMath.f_lerp($Waypoints/A.position.x * FMath.S, $Waypoints/B.position.x * FMath.S, sub_time)
			target_pos.y = FMath.n_lerp($Waypoints/A.position.y * FMath.S, ($Waypoints/A.position.y - 32)* FMath.S, sub_time)
			return target_pos.convert_to_vec()
		1:
			return $Waypoints/B.position
		2:
			var target_pos := FVector.new()
			target_pos.x = FMath.f_lerp($Waypoints/B.position.x * FMath.S, $Waypoints/A.position.x * FMath.S, sub_time)
			target_pos.y = FMath.n_lerp($Waypoints/B.position.y * FMath.S, ($Waypoints/B.position.y + 32)* FMath.S, sub_time)
			return target_pos.convert_to_vec()
		3:
			var target_pos := FVector.new()
			target_pos.x = FMath.f_lerp($Waypoints/A.position.x * FMath.S, $Waypoints/C.position.x * FMath.S, sub_time)
			target_pos.y = FMath.n_lerp($Waypoints/A.position.y * FMath.S, ($Waypoints/A.position.y - 32)* FMath.S, sub_time)
			return target_pos.convert_to_vec()
		4:
			return $Waypoints/C.position
		5:
			var target_pos := FVector.new()
			target_pos.x = FMath.f_lerp($Waypoints/C.position.x * FMath.S, $Waypoints/A.position.x * FMath.S, sub_time)
			target_pos.y = FMath.n_lerp($Waypoints/C.position.y * FMath.S, ($Waypoints/C.position.y + 32)* FMath.S, sub_time)
			return target_pos.convert_to_vec()
	
	
#
#	if time_ref < 100:
#		return lerp(0, 0.25, time_ref/100)
#
#	elif time_ref <= 200:
#		return 0.25
#
#	elif time_ref <= 400:
#		return lerp(0.25, 0.75, (time_ref - 200)/200)
#
#	elif time_ref <= 500:
#		return 0.75
#
#	else:
#		return lerp(0.75, 1.0, (time_ref - 500)/100)
