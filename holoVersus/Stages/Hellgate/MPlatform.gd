extends "res://Scenes/Stage/MovingPlatform.gd"

const PERIOD = 1500


func movement_pattern():
	
# warning-ignore:integer_division
	var time_ref : int = (posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) * 800) / PERIOD
#	Globals.Game.matchtime is the remaining time on the clock, so Globals.time_limit * 60 - Globals.Game.matchtime is the time elasped
#	Globals.Game.matchtime counts into the negatives if Globals.time_limit = 0, so need posmod()
#	posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) gives the time position on the period
#	divide by period and multiply by a more suitable number for easier segmentation
	
# warning-ignore:integer_division
	var segment: int = time_ref / 100
	var sub_time: int = posmod(time_ref, 100)
	
	var target_pos := FVector.new()
	
	match segment:
		0:
			target_pos.x = FMath.f_lerp($Waypoints/A.position.x * FMath.S, $Waypoints/B.position.x * FMath.S, sub_time)
		1:
			target_pos.x = FMath.ease_out_lerp($Waypoints/B.position.x * FMath.S, $Waypoints/C.position.x * FMath.S, sub_time)
		2:
			target_pos.x = FMath.ease_in_lerp($Waypoints/C.position.x * FMath.S, $Waypoints/B.position.x * FMath.S, sub_time)
		3:
			target_pos.x = FMath.f_lerp($Waypoints/B.position.x * FMath.S, $Waypoints/A.position.x * FMath.S, sub_time)
		4:
			target_pos.x = FMath.f_lerp($Waypoints/A.position.x * FMath.S, $Waypoints/D.position.x * FMath.S, sub_time)
		5:
			target_pos.x = FMath.ease_out_lerp($Waypoints/D.position.x * FMath.S, $Waypoints/E.position.x * FMath.S, sub_time)
		6:
			target_pos.x = FMath.ease_in_lerp($Waypoints/E.position.x * FMath.S, $Waypoints/D.position.x * FMath.S, sub_time)
		7:
			target_pos.x = FMath.f_lerp($Waypoints/D.position.x * FMath.S, $Waypoints/A.position.x * FMath.S, sub_time)
			
	if posmod(Globals.Game.orig_rng_seed, 2) != 0:
		target_pos.x *= -1 # flip 50% of time
			
	return {"type":Em.mov_platform.MOVING, "pos":target_pos.convert_to_vec()}

