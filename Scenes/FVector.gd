extends Node

class_name FVector

var x : int = 0 # scaled by FMath.S
var y : int = 0 # scaled by FMath.S

func set_vector(in_x: int, in_y: int):
	x = in_x
	y = in_y
	
func set_from_vec(in_vector:Vector2):
# warning-ignore:narrowing_conversion
	x = in_vector.x * FMath.S
# warning-ignore:narrowing_conversion
	y = in_vector.y * FMath.S

func convert_to_vec() -> Vector2: # for going from scaled true_position to node position
	return Vector2(FMath.round_and_descale(x), FMath.round_and_descale(y))
	
	
func is_longer_than(target_length) -> bool: # target_length is scaled!
	var descaled_vector = Vector2(FMath.round_and_descale(x), FMath.round_and_descale(y))
	target_length = FMath.round_and_descale(target_length)
	var length_square = (descaled_vector.x * descaled_vector.x) + (descaled_vector.y * descaled_vector.y)
	if length_square > target_length * target_length:
		return true
	else:
		return false
	
	
func is_longer_than_another(other_fvector) -> bool: # compare length of 2 FVectors fast
	var descaled_vector = Vector2(FMath.round_and_descale(x), FMath.round_and_descale(y))
	var descaled_other_vector = Vector2(FMath.round_and_descale(other_fvector.x), FMath.round_and_descale(other_fvector.y))
	var length_square = (descaled_vector.x * descaled_vector.x) + (descaled_vector.y * descaled_vector.y)
	var other_length_square = (descaled_other_vector.x * descaled_other_vector.x) + (descaled_other_vector.y * descaled_other_vector.y)
	if length_square > other_length_square:
		return true
	else:
		return false
		
	
func length(in_angle = null) -> int: # can pass in the angle if found before hand to make it faster
	var angle: int
	if in_angle == null:
		angle = angle() # get the angle 1st
	else:
		angle = in_angle
		
	if angle == 0 or angle == 180:
		return int(abs(x))
# warning-ignore:integer_division
	return y * FMath.S / FMath.f_sin(angle) # use sine to find the length of the hypotenuse
	
	
func percent(percent: int): # multiply a vector's length by a percent
	x = FMath.percent(x, percent)
	y = FMath.percent(y, percent)
	
	
func rotate(angle_int: int): # rotate vector by a certain angle, angle is in integer degrees
	var sin_angle: int = FMath.f_sin(angle_int)
	var cos_angle: int = FMath.f_cos(angle_int)
	
# warning-ignore:integer_division
	var new_x: int = (cos_angle * x - sin_angle * y) / FMath.S # place result in temp variable first!
# warning-ignore:integer_division
	var new_y: int = (sin_angle * x + cos_angle * y) / FMath.S
	
	x = new_x
	y = new_y

	
	
# ------------------------------------------------------------------------------------------------------------------------------
	
func angle(bias = null) -> int: # get angle of a vector by using reverse lookup on TANGENT_TABLE
	if x == 0 and y == 0:
		if bias != null and bias in [1, -1]:
			if bias == 1:
				return 0
			else:
				return 180
		else:
			return 0 # zero vector, just in case
	
	if abs(y) > abs(x * FMath.TANGENT_INF_REF): # x is too small and y/x approaches infinity, do not divide y by x
		if y >= 0:
			return 90
		else:
			return 270
			
# warning-ignore:integer_division
	var z: int = (y * FMath.S) / x  # multiply by scaling factor first before division!
#	TANGENT_TABLE gives z (scaled by 10000) values for each angle in tan(angle), find closest one to your z to get the angle
	
	if z >= 0: # angle is 0~90 or 180~270
		var angle: int = _find_closest_tangent_table_key(z)
		if angle == 0 or angle == 180: # special case
			if x > 0: return 0
			else: return 180
		if y >= 0: # 1st half of the circle
			return angle
		else: # 2nd half
			return angle + 180
	else: # angle is 90~180 or 270~360
		var angle: int = _find_closest_tangent_table_key_inverted(z)
		if angle == 0 or angle == 180: # special case
			if x > 0: return 0
			else: return 180
		if y >= 0: # 1st half of the circle
			return angle
		else: # 2nd half
			return angle + 180
	
	
func _find_closest_tangent_table_key(z: int) -> int:
	
	if z > FMath.TANGENT_TABLE[FMath.TANGENT_TABLE.size() - 1]: # should not be possible but just in case
		if z < FMath.TANGENT_INF_REF: # TANGENT_INF_REF is for tan(89.5)
			return 89
		else: # z is over tan(89.5), return 90
			return 90
			
	var hi: int = FMath.TANGENT_TABLE.size() - 1 # search for closest value in TANGENT_TABLE via binary search
	var lo: int = 0
	while hi - lo > 1:
# warning-ignore:integer_division
		var mid: int = (hi + lo) / 2
		if z < FMath.TANGENT_TABLE[mid]:
			hi = mid
		else:
			lo = mid
	if hi == lo: return hi
	elif abs(FMath.TANGENT_TABLE[hi] - z) < abs(FMath.TANGENT_TABLE[lo] - z):
		return hi
	else:
		return lo	


func _find_closest_tangent_table_key_inverted(z: int) -> int:
	
	if z < -FMath.TANGENT_TABLE[FMath.TANGENT_TABLE.size() - 1]: # should not be possible but just in case
		if z > -FMath.TANGENT_INF_REF: # -TANGENT_INF_REF is for tan(90.5)
			return 91
		else: # z is under tan(90.5), return 90
			return 90
				
	var hi: int = FMath.TANGENT_TABLE.size() - 1 # search for closest value in TANGENT_TABLE via binary search
	var lo: int = 0
	while hi - lo > 1:
# warning-ignore:integer_division
		var mid: int = (hi + lo) / 2
		if abs(z) < FMath.TANGENT_TABLE[mid]:
			hi = mid
		else:
			lo = mid
	if hi == lo: return 180 - hi
	elif abs(FMath.TANGENT_TABLE[hi] - abs(z)) < abs(FMath.TANGENT_TABLE[lo] - abs(z)):
		return 180 - hi
	else:
		return 180 - lo	

