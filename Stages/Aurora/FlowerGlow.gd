extends "res://Scenes/Stage/StageGlow.gd"



func _ready():

	modulate_start = Color(1.0, 1.0, 1.0, 1.0)
	modulate_end = Color(1.0, 1.0, 1.0, 0.3)
	period = 5.0 # number of seconds for modulate to complete a cycle
	
	init()
