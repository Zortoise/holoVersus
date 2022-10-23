extends Node

var time := 0

	
func stimulate():
	if time > 0:
		time -= 1
	elif time < 0:
		time = 0

func stop():
	time = 0

func is_running():
	if time > 0:
		return true
	else:
		return false
