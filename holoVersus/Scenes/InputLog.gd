extends Resource

# this saves key presses, and releases
# only save changes in pressed keys (as int variables), in timestamps

export var input_log = {
	
}

export var latest_correct_time := 0 # for rollback netcode
	
	
func reset():
	input_log = {}
	latest_correct_time = 0
	
# clear all timestamps in input_log after end_frametime
func set_end_frametime(end_frametime):
	var timestamps = input_log.keys()
	for timestamp in timestamps:
		if timestamp > end_frametime:
			input_log.erase(timestamp)

