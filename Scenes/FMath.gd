extends Node

# variables like angles, Damage Value and EX Gauge will use FMath as well
# angles will be limited to increments of 1 degree

const S_FACTOR = 10000

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
	var quotient: int = in_int / S_FACTOR
	var remainder: int = in_int - (quotient * S_FACTOR)
	if remainder >= 5000:
		out_int = quotient + 1
	else:
		out_int = quotient
	return out_int
	

func percent(in_int: int, percent: int) -> int: # for multiplication/division (to multiply by 2: percent = 200, to divide by 2: percent = 50)
	var out_int: int
# warning-ignore:integer_division
	out_int = (in_int * percent) / 100
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


	
	
