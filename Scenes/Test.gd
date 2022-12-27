extends Node



func _ready():
	var vector = FVector.new()
	vector.set_vector(10000, 20000)
	vector.f_rotate(-30)
	print(vector.x)
	print(vector.y)
	vector.f_vec_percent(150)
	print(vector.x)
	print(vector.y)
