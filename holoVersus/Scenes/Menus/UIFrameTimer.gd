extends Node

var playing := false
var time := 0

func start():
	time = 0
	playing = true
	
func stop():
	time = 0
	playing = false

func _physics_process(_delta):
	if playing:
		time += 1
