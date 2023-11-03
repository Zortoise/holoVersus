extends "res://Scenes/Stage/MovingPlatform.gd"

const PERIOD = 800


func movement_pattern():
	
# warning-ignore:integer_division
	var time_ref : int = (posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) * 60000) / PERIOD
#	Globals.Game.matchtime is the remaining time on the clock, so Globals.time_limit * 60 - Globals.Game.matchtime is the time elasped
#	Globals.Game.matchtime counts into the negatives if Globals.time_limit = 0, so need posmod()
#	posmod(Globals.time_limit * 60 - Globals.Game.matchtime, PERIOD) gives the time position on the period
#	divide by period and multiply by a more suitable number for easier segmentation

# warning-ignore:integer_division
	var segment: int = time_ref / 10000
	var sub_time: int = posmod(time_ref, 10000)
	
	var new_pos: Vector2
	
	match segment:
		0:
			var target_pos := FVector.new()
			target_pos.x = FMath.f_lerp_m($Waypoints/A.position.x * FMath.S, $Waypoints/B.position.x * FMath.S, sub_time)
			target_pos.y = FMath.n_lerp_m($Waypoints/A.position.y * FMath.S, ($Waypoints/A.position.y - 32)* FMath.S, sub_time)
			new_pos = target_pos.convert_to_vec()
		1:
			new_pos = $Waypoints/B.position
		2:
			var target_pos := FVector.new()
			target_pos.x = FMath.f_lerp_m($Waypoints/B.position.x * FMath.S, $Waypoints/A.position.x * FMath.S, sub_time)
			target_pos.y = FMath.n_lerp_m($Waypoints/B.position.y * FMath.S, ($Waypoints/B.position.y + 32)* FMath.S, sub_time)
			new_pos = target_pos.convert_to_vec()
		3:
			var target_pos := FVector.new()
			target_pos.x = FMath.f_lerp_m($Waypoints/A.position.x * FMath.S, $Waypoints/C.position.x * FMath.S, sub_time)
			target_pos.y = FMath.n_lerp_m($Waypoints/A.position.y * FMath.S, ($Waypoints/A.position.y - 32)* FMath.S, sub_time)
			new_pos = target_pos.convert_to_vec()
		4:
			new_pos = $Waypoints/C.position
		5:
			var target_pos := FVector.new()
			target_pos.x = FMath.f_lerp_m($Waypoints/C.position.x * FMath.S, $Waypoints/A.position.x * FMath.S, sub_time)
			target_pos.y = FMath.n_lerp_m($Waypoints/C.position.y * FMath.S, ($Waypoints/C.position.y + 32)* FMath.S, sub_time)
			new_pos = target_pos.convert_to_vec()
	
	if posmod(Globals.Game.orig_rng_seed, 2) != 0:
		new_pos.x *= -1 # flip 50% of time
		
	return {"type":Em.mov_platform.MOVING, "pos": new_pos}
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
