extends Node


func test(rect):
	rect.position.x += 1
	return rect
	
func _ready():
	var rect := Rect2(Vector2(0, 0), Vector2(1, 1))
	rect = test(rect)
	print(rect.position)

#	print(FMath.get_fraction_percent(5000, 10000))

#	var vector = FVector.new()
#	vector.set_vector(45000, 1000)
#	print(vector.angle())
#	vector.set_vector(45000, 1)
#	print(vector.angle())
#	vector.set_vector(45000, 0)
#	print(vector.angle())
#	vector.set_vector(45000, -1)
#	print(vector.angle())
#	vector.set_vector(45000, -1000)
#	print(vector.angle())
	
#	for x in [0, 45, 90, 135, 180, 225, 270, 315, 360]:
#		vector.set_vector(10000, 0)
#		vector.rotate(x)
#		print(str(vector.x) + " " + str(vector.y))

#	vector.f_vec_percent(150)
#	print(vector.x)
#	print(vector.y)

#	print(str(FMath.ease_in_lerp(68418, 5464, 0)) + " " + str(FMath.ease_out_lerp(68418, 5464, 0)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 10)) + " " + str(FMath.ease_out_lerp(68418, 5464, 10)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 20)) + " " + str(FMath.ease_out_lerp(68418, 5464, 20)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 30)) + " " + str(FMath.ease_out_lerp(68418, 5464, 30)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 40)) + " " + str(FMath.ease_out_lerp(68418, 5464, 40)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 50)) + " " + str(FMath.ease_out_lerp(68418, 5464, 50)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 60)) + " " + str(FMath.ease_out_lerp(68418, 5464, 60)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 70)) + " " + str(FMath.ease_out_lerp(68418, 5464, 70)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 80)) + " " + str(FMath.ease_out_lerp(68418, 5464, 80)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 90)) + " " + str(FMath.ease_out_lerp(68418, 5464, 90)))
#	print(str(FMath.ease_in_lerp(68418, 5464, 100)) + " " + str(FMath.ease_out_lerp(68418, 5464, 100)))
	
	pass
