extends Node

# angles will be limited to increments of 1 degree

const S = 10000

const SINE_TABLE = PoolIntArray([ # 0 degrees to 90 degrees
	0, 175, 349, 523, 698, 872, 1045, 1219, 1392, 1564, 1736, 1908, 2079, 2250, 2419, 2588, 2756, 2924, 3090,
	3256, 3420, 3584, 3746, 3907, 4067, 4226, 4384, 4540, 4695, 4848, 5000, 5150, 5299, 5446, 5592, 5736, 5878,
	6018, 6157, 6293, 6428, 6561, 6691, 6820, 6947, 7071, 7193, 7314, 7431, 7547, 7660, 7771, 7880, 7986, 8090,
	8192, 8290, 8387, 8480, 8572, 8660, 8746, 8829, 8910, 8988, 9063, 9135, 9205, 9272, 9336, 9397, 9455, 9511,
	9563, 9613, 9659, 9703, 9744, 9781, 9816, 9848, 9877, 9903, 9925, 9945, 9962, 9976, 9986, 9994, 9998, 10000  
])

const TANGENT_TABLE = PoolIntArray([ # 0 degrees to 90 degrees
	0, 175, 349, 524, 699, 875, 1051, 1228, 1405, 1584, 1763, 1944, 2126, 2309, 2493, 2679, 2867, 3057, 
	3249, 3443, 3640, 3839, 4040, 4245, 4452, 4663, 4877, 5095, 5317, 5543, 5774, 6009, 6249, 6494, 6745, 7002, 
	7265, 7536, 7813, 8098, 8391, 8693, 9004, 9325, 9657, 10000, 10355, 10724, 11106, 11504, 11918, 12349, 12799, 13270, 
	13764, 14281, 14826, 15399, 16003, 16643, 17321, 18040, 18807, 19626, 20503, 21445, 22460, 23559, 24751, 26051, 27475, 29042, 
	30777, 32709, 34874, 37321, 40108, 43315, 47046, 51446, 56713, 63138, 71154, 81443, 95144, 114301, 143007, 190811, 286363, 572900
])
const TANGENT_INF_REF = 1145887 # if over 1145887 or under -1145887, the angle is 90 or 270



func round_and_descale(in_int: int) -> int:
	var out_int: int
# warning-ignore:integer_division
	var quotient: int = in_int / S
	var remainder: int = in_int - (quotient * S)
	if remainder >= 5000:
		out_int = quotient + 1
	else:
		out_int = quotient
	return out_int
	
func round_up_and_descale(in_int: int) -> int:
	var out_int: int
# warning-ignore:integer_division
	var quotient: int = in_int / S
	var remainder: int = in_int - (quotient * S)
	if remainder > 0:
		out_int = quotient + 1
	else:
		out_int = quotient
	return out_int
	
func round_down_and_descale(in_int: int) -> int:
	var out_int: int
# warning-ignore:integer_division
	var quotient: int = in_int / S
	out_int = quotient
	return out_int
	

func percent(in_int: int, percent: int) -> int: # for multiplication/division (to multiply by 2: percent = 200, to divide by 2: percent = 50)
	var out_int: int
# warning-ignore:integer_division
	out_int = (in_int * percent) / 100
	return out_int
	
func get_fraction_percent(numerator: int, denominator: int) -> int: # turn a fraction into a 0~100 percent
	var out_int: int
# warning-ignore:integer_division
	out_int = (numerator * 100) / denominator
	return out_int


func f_sin(angle_int: int) -> int: # returns a fraction scaled up by 10000
#	sin( 90° .. 180° ) = sin( 90° ... 0° ), sin( 180° .. 360° ) = - sin( 0° .. 180° )
	angle_int = posmod(angle_int, 360)
	
	if angle_int < 90: # find the quadrant first
		return SINE_TABLE[angle_int]
	elif angle_int < 180:
		return SINE_TABLE[180 - angle_int]
	elif angle_int < 270:
		return -SINE_TABLE[angle_int - 180]
	else:
		return -SINE_TABLE[360 - angle_int]


func f_cos(angle_int: int) -> int: # returns a fraction scaled up by 10000
	return f_sin(angle_int + 90)


func harmonic_motion_vel(amplitude: int, ang_freq: int, time: int) -> int:
	# ang_freq is how many degrees of the period to advance every frame
	return amplitude * ang_freq * FMath.f_cos(time * ang_freq)

func f_lerp(start: int, end: int, weight_percent: int) -> int:
	if weight_percent <= 0: return start
	if weight_percent >= 100: return end
	
	var diff: int = end - start
	diff = percent(diff, weight_percent)
	return start + diff
	
	
func sin_lerp(start: int, end: int, weight_percent: int) -> int: # starts and ends slow
	if weight_percent <= 0: return start
	if weight_percent >= 100: return end
	
# warning-ignore:integer_division
	var weight2: int = percent(f_sin(percent(180, weight_percent) - 90) + 10000, 50)/ 100
	return f_lerp(start, end , weight2)
	
	
func harmonic_lerp(start: int, end: int, weight_percent: int) -> int:
	if weight_percent <= 0: return start
	if weight_percent >= 100: return start
	
# warning-ignore:integer_division
	var weight2: int = f_sin(percent(360, weight_percent)) / 100
	return f_lerp(start, end , weight2)
	
	
func n_lerp(start: int, end: int, weight_percent: int) -> int: # moves in a n-shape
	if weight_percent <= 0: return start
	if weight_percent >= 100: return start
	
# warning-ignore:integer_division
	var weight2: int = f_sin(percent(180, weight_percent)) / 100
	return f_lerp(start, end , weight2)
	
	
func ease_out_lerp(start: int, end: int, weight_percent: int) -> int: # starts fast and ends slow
	if weight_percent <= 0: return start
	if weight_percent >= 100: return end

# warning-ignore:integer_division
	var weight2: int = f_sin(percent(percent(180, weight_percent), 50)) / 100
	return f_lerp(start, end , weight2)


func ease_in_lerp(start: int, end: int, weight_percent: int) -> int: # starts slow and ends fast
	if weight_percent <= 0: return start
	if weight_percent >= 100: return end

# warning-ignore:integer_division
	var weight2: int = (f_sin(percent(percent(180, weight_percent), 50) - 90) + 10000) / 100
	return f_lerp(start, end , weight2)
	
	
func find_center(array: Array, bias: int) -> Vector2:
	var total_x := 0
	var total_y := 0
	for point in array:
		total_x += point.x * S
		total_y += point.y * S
		
	var average_x: int
	if bias == 1:
# warning-ignore:integer_division
		average_x = round_up_and_descale(int(total_x / array.size()))
	else:
# warning-ignore:integer_division
		average_x = round_down_and_descale(int(total_x / array.size()))
# warning-ignore:integer_division
	var average_y: int = round_and_descale(int(total_y / array.size()))
	
	return Vector2(average_x, average_y)
	
	
func get_closest(node_array: Array, target_point: Vector2): # find closest node to target_point
	var shortest_dist_square = null
	var found = null
	
	for node in node_array:
		var x = node.position.x - target_point.x
		var y = node.position.y - target_point.y
		var dist_square = x * x + y * y
		if shortest_dist_square == null:
			found = node
			shortest_dist_square = dist_square
		else:
			if dist_square < shortest_dist_square:
				found = node
				shortest_dist_square = dist_square
	
	return found
	
