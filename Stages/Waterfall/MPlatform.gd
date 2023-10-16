extends "res://Scenes/Stage/MovingPlatform.gd"

const PERIOD = 800


func movement_pattern():
	
# warning-ignore:integer_division
	var time_ref : int = (posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) * 400) / PERIOD
# warning-ignore:integer_division
	var segment: int = time_ref / 100
	var sub_time: int = posmod(time_ref, 100)
	
	var target_pos := FVector.new()
	
	match segment:
		0:
			target_pos.x = $Waypoints/A.position.x * FMath.S
		1:
			target_pos.x = FMath.sin_lerp($Waypoints/A.position.x * FMath.S, $Waypoints/B.position.x * FMath.S, sub_time)
		2:
			target_pos.x = $Waypoints/B.position.x * FMath.S
		3:
			target_pos.x = FMath.sin_lerp($Waypoints/B.position.x * FMath.S, $Waypoints/A.position.x * FMath.S, sub_time)
	
	return {"type":Em.mov_platform.MOVING, "pos":target_pos.convert_to_vec()}
