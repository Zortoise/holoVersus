extends Resource

export var data_name := ""

export var preset := {
		"up" : null,
		"down" : null,
		"left" : null,
		"right" : null,
		"jump" : null,
		"light" : null,
		"fierce" : null,
		"dash" : null,
		"aux" : null,
		"block" : null,
		"special" : null,
		"unique" : null,
		"pause" : null,
		"tapjump" : null,
		"dj_fastfall" : null,
		"buffer" : null,
		"input_assist" : null,
		"deadzone" : null,
		"extra_buttons" : [],
	}


func create_preset(player_ID, input_map, in_preset_name):
	data_name = in_preset_name
	
	for input in input_map.keys():
		if input.begins_with("P" + str(player_ID + 1)):
			var action = input.trim_prefix("P" + str(player_ID + 1) + "_")
			preset[action] = input_map[input]
			
			
	var dir = Directory.new()
		
	if !dir.dir_exists("user://Presets"): # if Presets folder don't exist, make it
		if dir.make_dir("user://Presets") != OK:
			print("Error: Unable to create Presets folder")
		
	var filepath = "user://Presets/" + data_name + ".tres" # set filepath
	var value := 2
	while dir.file_exists(filepath): # if there is already a preset of the same name, increment the name
		data_name = in_preset_name + str(value)
		filepath = "user://Presets/" + data_name + ".tres"
		value += 1
		
# warning-ignore:return_value_discarded
	ResourceSaver.save(filepath, self)
	
	
func save_preset(in_preset_name: String, in_preset: Dictionary): # used to create tres files for default presets
	data_name = in_preset_name
	preset = in_preset
	
	var filepath = "user://Presets/" + data_name + ".tres" # set filepath
		
# warning-ignore:return_value_discarded
	ResourceSaver.save(filepath, self)
			

#const INPUT_PRESETS = {
#		"navkeys" : {
#			"up" : KEY_W,
#			"down" : KEY_S,
#			"left" : KEY_A,
#			"right" : KEY_D,
#			"jump" : KEY_SPACE,
#			"light" : KEY_DELETE,
#			"fierce" : KEY_END,
#			"dash" : KEY_PAGEDOWN,
#			"unique" : KEY_INSERT,
#			"block" : KEY_HOME,
#			"assist" : KEY_PAGEUP,
#			"special" : KEY_CONTROL,
#			"extra" : KEY_SHIFT,
#			"pause" : KEY_ESCAPE,
#		},
#		"test_p2" : {
#			"up" : KEY_UP,
#			"down" : KEY_DOWN,
#			"left" : KEY_LEFT,
#			"right" : KEY_RIGHT,
#			"jump" : KEY_KP_ENTER,
#			"light" : KEY_KP_4,
#			"fierce" : KEY_KP_5,
#			"dash" : KEY_KP_6,
#			"unique" : KEY_KP_7,
#			"block" : KEY_KP_8,
#			"assist" : KEY_KP_9,
#			"special" : KEY_KP_0,
#			"extra" : KEY_KP_ADD,
#			"pause" : KEY_KP_SUBTRACT,
#		},
#		"gamepad D0" : {
#			"up" : [0, JOY_DPAD_UP],
#			"down" : [0, JOY_DPAD_DOWN],
#			"left" : [0, JOY_DPAD_LEFT],
#			"right" : [0, JOY_DPAD_RIGHT],
#			"jump" : [0, JOY_XBOX_A],
#			"light" : [0, JOY_XBOX_B],
#			"fierce" : [0, JOY_XBOX_Y],
#			"dash" : [0, JOY_R],
#			"unique" : [0, JOY_XBOX_X],
#			"block" : [0, JOY_L],
#			"assist" : [0, JOY_R3],
#			"special" : [0, JOY_R2],
#			"extra" : [0, JOY_L2],
#			"pause" : [0, JOY_START],
#		},
#		"gamepad D1" : {
#			"up" : [1, JOY_DPAD_UP],
#			"down" : [1, JOY_DPAD_DOWN],
#			"left" : [1, JOY_DPAD_LEFT],
#			"right" : [1, JOY_DPAD_RIGHT],
#			"jump" : [1, JOY_XBOX_A],
#			"light" : [1, JOY_XBOX_B],
#			"fierce" : [1, JOY_XBOX_Y],
#			"dash" : [1, JOY_R],
#			"unique" : [1, JOY_XBOX_X],
#			"block" : [1, JOY_L],
#			"assist" : [1, JOY_R3],
#			"special" : [1, JOY_R2],
#			"extra" : [1, JOY_L2],
#			"pause" : [1, JOY_START],
#		},
#	}
