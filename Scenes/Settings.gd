extends Node

const SETTINGS_FILEPATH = "" # filepath to the file containing saved settings

var input_buffer_time := [5, 5] # can be changed by the user, index is the player ID
var tap_jump := [true, true] # # can set so that up does not jump, index is the player ID
var dj_fastfall := [false, false]

const DEFAULT_PRESETS = {
		"Alphanumeric" : {
			"up" : KEY_W,
			"down" : KEY_S,
			"left" : KEY_A,
			"right" : KEY_D,
			"jump" : KEY_SPACE,
			"light" : KEY_U,
			"fierce" : KEY_I,
			"dash" : KEY_O,
			"aux" : KEY_K,
			"block" : KEY_J,
			"special" : KEY_SHIFT,
			"unique" : KEY_CONTROL,
			"pause" : KEY_ESCAPE,
			"tapjump" : 1,
			"dj_fastfall" : 0,
			"buffer" : 5,
			"deadzone" : 3,
			"extra_buttons" : [],
		},
		"NavKeys" : {
			"up" : KEY_W,
			"down" : KEY_S,
			"left" : KEY_A,
			"right" : KEY_D,
			"jump" : KEY_SPACE,
			"light" : KEY_DELETE,
			"fierce" : KEY_END,
			"dash" : KEY_PAGEDOWN,
			"aux" : KEY_INSERT,
			"block" : KEY_HOME,
			"special" : KEY_CONTROL,
			"unique" : KEY_SHIFT,
			"pause" : KEY_ESCAPE,
			"tapjump" : 1,
			"dj_fastfall" : 0,
			"buffer" : 5,
			"deadzone" : 3,
			"extra_buttons" : [],
		},
		"Test_P2" : {
			"up" : KEY_UP,
			"down" : KEY_DOWN,
			"left" : KEY_LEFT,
			"right" : KEY_RIGHT,
			"jump" : KEY_KP_ENTER,
			"light" : KEY_KP_4,
			"fierce" : KEY_KP_5,
			"dash" : KEY_KP_6,
			"aux" : KEY_KP_7,
			"block" : KEY_KP_8,
			"special" : KEY_KP_0,
			"unique" : KEY_KP_ADD,
			"pause" : KEY_KP_SUBTRACT,
			"tapjump" : 1,
			"dj_fastfall" : 0,
			"buffer" : 5,
			"deadzone" : 3,
			"extra_buttons" : [],
		},
		"Gamepad D1" : {
			"up" : [0, JOY_ANALOG_LY, -1.0],
			"down" : [0, JOY_ANALOG_LY, 1.0],
			"left" : [0, JOY_ANALOG_LX, -1.0],
			"right" : [0, JOY_ANALOG_LX, 1.0],
			"jump" : [0, JOY_XBOX_A],
			"light" : [0, JOY_XBOX_B],
			"fierce" : [0, JOY_XBOX_Y],
			"dash" : [0, JOY_R],
			"aux" : [0, JOY_L],
			"block" : [0, JOY_XBOX_X],
			"special" : [0, JOY_L2],
			"unique" : [0, JOY_R2],
			"pause" : [0, JOY_START],
			"tapjump" : 0,
			"dj_fastfall" : 0,
			"buffer" : 5,
			"deadzone" : 3,
			"extra_buttons" : [["left", [0, JOY_DPAD_LEFT]], ["right", [0, JOY_DPAD_RIGHT]], ["up", [0, JOY_DPAD_UP]], ["down", [0, JOY_DPAD_DOWN]]],
		},
		"Gamepad D2" : {
			"up" : [1, JOY_ANALOG_LY, -1.0],
			"down" : [1, JOY_ANALOG_LY, 1.0],
			"left" : [1, JOY_ANALOG_LX, -1.0],
			"right" : [1, JOY_ANALOG_LX, 1.0],
			"jump" : [1, JOY_XBOX_A],
			"light" : [1, JOY_XBOX_B],
			"fierce" : [1, JOY_XBOX_Y],
			"dash" : [1, JOY_R],
			"aux" : [1, JOY_L],
			"block" : [1, JOY_XBOX_X],
			"special" : [1, JOY_L2],
			"unique" : [1, JOY_R2],
			"pause" : [1, JOY_START],
			"tapjump" : 0,
			"dj_fastfall" : 0,
			"buffer" : 5,
			"deadzone" : 3,
			"extra_buttons" : [["left", [1, JOY_DPAD_LEFT]], ["right", [1, JOY_DPAD_RIGHT]], ["up", [1, JOY_DPAD_UP]], ["down", [1, JOY_DPAD_DOWN]]]
		},
	}
	
	


func _ready():
	# import settings from file
	set_settings(load_settings())
	change_input_map(load_input_map())
	
	set_up_default_presets()
	
	
func set_up_default_presets():

	var dir = Directory.new()
		
	if !dir.dir_exists("user://Presets"): # if Presets folder don't exist, make it
		if dir.make_dir("user://Presets") != OK:
			print("Error: Unable to create Presets folder")
			
	for preset_name in DEFAULT_PRESETS.keys():
#		if !dir.file_exists("user://Presets/" + preset_name + ".tres"):
		var new_preset = load("res://Scenes/Menus/ControlPreset.gd").new()
		new_preset.save_preset(preset_name, DEFAULT_PRESETS[preset_name].duplicate(true))
	
	
func save_settings(config: Dictionary):
	
	var config_data = load("res://Scenes/Menus/Config.gd").new() # save config data
	config_data.config = config.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://config.tres", config_data)
	
	set_settings(config)
	
	
func load_settings():
	var config: Dictionary
	if ResourceLoader.exists("user://config.tres"):
		config = ResourceLoader.load("user://config.tres").config
		
		var valid := true # check if config has all needed keys, if not, use default config
		for check in ["fullscreen", "window_size", "borderless", "vsync", "fps_lock", "fps_and_ping", "game_volume", "music_volume", "ui_volume"]:
			if !check in config:
				valid = false
		if valid:
			return config
		
	 # default config
	return {
		"fullscreen" : 0, # array index
		"window_size" : 0, # array index
		"borderless" : 0, # array index
		"vsync" : 0, # array index
		"fps_lock" : 0, # array index
		"fps_and_ping" : 1, # array index
		"game_volume" : 70, # 0 to 100
		"music_volume" : 70, # 0 to 100
		"ui_volume" : 70, # 0 to 100
	}
	
	
func set_settings(config):
	match config.fullscreen:
		0:
			OS.window_fullscreen = false
		1:
			OS.window_fullscreen = true
			
	match config.window_size:
		0:
			if OS.window_size != Vector2(1280, 720):
				OS.window_size = Vector2(1280, 720)
				OS.set_window_position(OS.get_screen_size() * 0.5 - OS.get_window_size() * 0.5)
		1:
			if OS.window_size != Vector2(1600, 900):
				OS.window_size = Vector2(1600, 900)
				OS.set_window_position(OS.get_screen_size() * 0.5 - OS.get_window_size() * 0.5)
		2:
			if OS.window_size != Vector2(1920, 1080):
				OS.window_size = Vector2(1920, 1080)
				OS.set_window_position(OS.get_screen_size() * 0.5 - OS.get_window_size() * 0.5)
				
	match config.borderless:
		0:
			OS.window_borderless = false
		1:
			OS.window_borderless = true
				
	match config.vsync:
		0:
			OS.vsync_enabled = false
			OS.vsync_via_compositor = false
		1:
			OS.vsync_enabled = true
			OS.vsync_via_compositor = false
		2:
			OS.vsync_enabled = true
			OS.vsync_via_compositor = true
			
	match config.fps_lock:
		0:
			Engine.target_fps = 0
		1:
			Engine.target_fps = 60
			
	match config.fps_and_ping:
		0:
			Fps.hide()
		1:
			Fps.show()

	set_volume("Game", config.game_volume)
	set_volume("Music", config.music_volume)
	set_volume("UI", config.ui_volume)
	
	
# audio, between -60 dB and 0 dB, every -6 dB halves the volume
# processes a variable called "volume_ref", range from 0 to 100
# set the audio buses whenever game is launched or when they are changed
# for bus names "UI", "Music", "Game"
func get_volume(bus_name: String):
	var volume_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))
	var volume_ref # convert volume_db to volume_ref
	if volume_db >= -6.0:
		volume_ref = lerp(100, 70, volume_db / -6.0)
	else:
		volume_ref = lerp(70, 0, (volume_db + 6.0) / -54.0)
	
	return volume_ref
	
func set_volume(bus_name: String, volume_ref):
	var volume_db # convert volume_ref to volume_db
	if volume_ref >= 70.0:
		volume_db = lerp(-6.0, 0.0, (volume_ref - 70)/30.0)
	else:
		volume_db = lerp(-60.0, 6.0, volume_ref/70.0)
		
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), volume_db)
	

# game config for last picked options, so you don't have to keep resetting them
func save_game_config(game_config: Dictionary):
	var game_config_data = load("res://Scenes/Menus/GameConfig.gd").new() # save config data
	game_config_data.game_config = game_config.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://game_config.tres", game_config_data)
	
func load_game_config():
	var game_config: Dictionary
	if ResourceLoader.exists("user://game_config.tres"):
		game_config = ResourceLoader.load("user://game_config.tres").game_config
		
		var valid := true # check if game_config has all needed keys, if not, use default game_config
		for check in ["game_mode", "stock_points", "time_limit", "assists", "static_stage", "custom_playlist"]:
			if !check in game_config:
				valid = false
		if valid:
			return game_config
		
	# default game_config
	return {
			"game_mode" : 0,
			"stock_points" : 2,
			"time_limit" : 6,
			"assists" : 0,
			"static_stage" : 0,
			"custom_playlist" : 0,
		}		

func save_training_config(training_config: Dictionary):
	var training_config_data = load("res://Scenes/Menus/GameConfig.gd").new() # save config data
	training_config_data.game_config = training_config.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://training_config.tres", training_config_data)
	
func load_training_config():
	var training_config: Dictionary
	if ResourceLoader.exists("user://training_config.tres"):
		training_config = ResourceLoader.load("user://training_config.tres").game_config
		
		var valid := true # check if game_config has all needed keys, if not, use default game_config
		for check in ["assists", "static_stage", "custom_playlist"]:
			if !check in training_config:
				valid = false
		if valid:
			return training_config
		
	# default training_config
	return {
			"assists" : 0,
			"static_stage" : 1,
			"custom_playlist" : 0,
		}	
		
func save_training_settings(training_settings: Dictionary):
	var training_settings_data = load("res://Scenes/Menus/GameConfig.gd").new() # save config data
	training_settings_data.game_config = training_settings.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://training_settings.tres", training_settings_data)
	
func load_training_settings():
	var training_settings: Dictionary
	if ResourceLoader.exists("user://training_settings.tres"):
		training_settings = ResourceLoader.load("user://training_settings.tres").game_config
		
		var valid := true # check if game_config has all needed keys, if not, use default game_config
		for check in ["gganchor", "regen", "input_viewer", "hitbox_viewer", "frame_viewer"]:
			if !check in training_settings:
				valid = false
		if valid:
			return training_settings
		
	# default training_settings
	return {
			"gganchor" : 0,
			"regen" : 1,
			"input_viewer" : 0,
			"hitbox_viewer" : 0,
			"frame_viewer" : 0,
		}	
	
# save last picked characters/stages, so you don't have to keep resetting them
func save_last_picked(last_picked: Dictionary):
	var last_picked_data = load("res://Scenes/Menus/LastPicked.gd").new() # save config data
	last_picked_data.last_picked = last_picked.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://last_picked.tres", last_picked_data)
	
func load_last_picked():
	var last_picked: Dictionary
	if ResourceLoader.exists("user://last_picked.tres"):
		last_picked = ResourceLoader.load("user://last_picked.tres").last_picked
	else: # no last_picked
		return null	
		
	var valid := true 			
	for check in ["P1_character", "P1_palette", "P1_stage", \
			"P2_character", "P2_palette", "P2_stage"]:
		if !check in last_picked:
			valid = false
	
	if valid: return last_picked
	else: return null

	
func save_input_map(input_map):

	var input_map_data = load("res://Scenes/Menus/Controls.gd").new()
	input_map_data.controls = input_map.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://controls.tres", input_map_data)
	
	# set the inputs here
	change_input_map(input_map)
	
func set_input_preset(input_map: Dictionary, player_ID: int, preset: Dictionary):
	for input_name in preset:
		input_map["P" + str(player_ID + 1) + "_" + input_name] = preset[input_name]
	
func load_input_map():
	var input_map: Dictionary
	if ResourceLoader.exists("user://controls.tres"):
		input_map = ResourceLoader.load("user://controls.tres").controls

		var valid := true # check if input_map has all needed keys, if not, use default input_map
		for player_inputs in Globals.INPUTS: # iterate through each player
			for input_array in player_inputs.values(): # iterate through each input array and get the key names
				if !input_array[0] in input_map:
					valid = false
					
		for check in ["P1_tapjump", "P1_buffer", "P1_dj_fastfall", "P1_deadzone", "P1_extra_buttons", \
				"P2_tapjump", "P2_buffer", "P2_dj_fastfall", "P2_deadzone", "P2_extra_buttons"]:
			if !check in input_map:
				valid = false
				
		if valid:
			return input_map

	# default controls	
	set_input_preset(input_map, 0, DEFAULT_PRESETS.Alphanumeric)
	set_input_preset(input_map, 1, DEFAULT_PRESETS.Test_P2)
		
	return input_map


func change_input_map(new_input_map):	# runs this when saving new controls
	
	for input in new_input_map.keys():
		if InputMap.has_action(input):
			# 1st, erase the old inputs from Godot's input map
			InputMap.action_erase_events(input)
			InputMap.action_set_deadzone(input, 0.5)
			
			if new_input_map[input] != null: # if null, leave it as having no event
				# add the new inputs into Godot's input map
				if !new_input_map[input] is Array: # non-array means keyboard
					var event = InputEventKey.new() # HAVE TO MAKE NEW ONE!
					event.scancode = new_input_map[input]
					InputMap.action_add_event(input, event)
				elif new_input_map[input].size() == 2 : # size 2 array means gamepad
					var event = InputEventJoypadButton.new()
					event.device = new_input_map[input][0]
					event.button_index = new_input_map[input][1]
					InputMap.action_add_event(input, event)
				else: # size 3 array means joystick
					var event = InputEventJoypadMotion.new()
					event.device = new_input_map[input][0]
					event.axis = new_input_map[input][1]
					event.axis_value = new_input_map[input][2]
					InputMap.action_add_event(input, event)	
					if input.begins_with("P1"):
						InputMap.action_set_deadzone(input, (new_input_map["P1_deadzone"] + 1) * 0.05)
					elif input.begins_with("P2"):
						InputMap.action_set_deadzone(input, (new_input_map["P2_deadzone"] + 1) * 0.05)
					
	# extra_button is a size2 array, 1st entry is the action, 2nd entry is the inputevent (can be an int/size2 array/size3 array)
	if "P1_extra_buttons" in new_input_map:
		for extra_button in new_input_map.P1_extra_buttons:
			add_extra_buttons(0, extra_button, new_input_map)
						
	if "P2_extra_buttons" in new_input_map:
		for extra_button in new_input_map.P2_extra_buttons:
			add_extra_buttons(1, extra_button, new_input_map)
		
	tap_jump[0] = new_input_map.P1_tapjump
	tap_jump[1] = new_input_map.P2_tapjump
	input_buffer_time[0] = new_input_map.P1_buffer
	input_buffer_time[1] = new_input_map.P2_buffer
	dj_fastfall[0] = new_input_map.P1_dj_fastfall
	dj_fastfall[1] = new_input_map.P2_dj_fastfall
	
	
func add_extra_buttons(player_ID, extra_button, new_input_map):
	
	var action = "P" + str(player_ID + 1) + "_" + extra_button[0]
	
	if InputMap.has_action(action):
		InputMap.action_set_deadzone(action, 0.5)
		if !extra_button[1] is Array: # non-array means keyboard
			var event = InputEventKey.new() # HAVE TO MAKE NEW ONE!
			event.scancode = extra_button[1]
			InputMap.action_add_event(action, event)
		elif extra_button[1].size() == 2 : # size 2 array means gamepad
			var event = InputEventJoypadButton.new()
			event.device = extra_button[1][0]
			event.button_index = extra_button[1][1]
			InputMap.action_add_event(action, event)
		else: # size 3 array means joystick
			var event = InputEventJoypadMotion.new()
			event.device = extra_button[1][0]
			event.axis = extra_button[1][1]
			event.axis_value = extra_button[1][2]
			InputMap.action_add_event(action, event)	
			if action.begins_with("P1"):
				InputMap.action_set_deadzone(action, (new_input_map["P1_deadzone"] + 1) * 0.05)
			elif action.begins_with("P2"):
				InputMap.action_set_deadzone(action, (new_input_map["P2_deadzone"] + 1) * 0.05)
	
#func test(new_input_map):
#	for input in new_input_map.keys():
#		print(input + "   " +  button_to_string(new_input_map[input]))
	
func button_to_string(key):
	if key is Array:
		var button: String
		if key.size() == 2:
			match key[1]:
				JOY_XBOX_A:
					button = "PadA"
				JOY_XBOX_B:
					button = "PadB"
				JOY_XBOX_X:
					button = "PadX"
				JOY_XBOX_Y:
					button = "PadY"
				JOY_DPAD_UP:
					button = "PadUp"
				JOY_DPAD_DOWN:
					button = "PadDown"
				JOY_DPAD_LEFT:
					button = "PadLeft"
				JOY_DPAD_RIGHT:
					button = "PadRight"
				JOY_L:
					button = "PadL1"
				JOY_R:
					button = "PadR1"
				JOY_L3:
					button = "PadL3"
				JOY_R3:
					button = "PadR3"
				JOY_SELECT:
					button = "PadSelect"
				JOY_START:
					button = "PadStart"
				JOY_L2:
					button = "PadL2"
				JOY_R2:
					button = "PadR2"
		else: # joystick motion
			match key[1]:
				JOY_ANALOG_LX:
					if key[2] > 0:
						button = "LStickR"
					else:
						button = "LStickL"
				JOY_ANALOG_LY:
					if key[2] > 0:
						button = "LStickD"
					else:
						button = "LStickU"
				JOY_ANALOG_RX:
					if key[2] > 0:
						button = "RStickR"
					else:
						button = "RStickL"
				JOY_ANALOG_RY:
					if key[2] > 0:
						button = "RStickD"
					else:
						button = "RStickU"
				JOY_L2:
					button = "PadL2"
				JOY_R2:
					button = "PadR2"
		return "D" + str(key[0] + 1) + " " + button
	else:
		match key:
			KEY_TAB:
				return "Tab"
			KEY_BACKSPACE:
				return "Backspace"
			KEY_ENTER:
				return "Enter"
			KEY_KP_ENTER:
				return "NumEnter"
			KEY_INSERT:
				return "Ins"
			KEY_DELETE:
				return "Del"
			KEY_HOME:
				return "Home"
			KEY_END:
				return "End"
			KEY_LEFT:
				return "Left"
			KEY_UP:
				return "Up"
			KEY_RIGHT:
				return "Right"
			KEY_DOWN:
				return "Down"
			KEY_PAGEUP:
				return "PgUp"
			KEY_PAGEDOWN:
				return "PgDn"
			KEY_SHIFT:
				return "Shift"
			KEY_CONTROL:
				return "Ctrl"
			KEY_ALT:
				return "Alt"
			KEY_F1:
				return "F1"
			KEY_F2:
				return "F2"
			KEY_F3:
				return "F3"
			KEY_F4:
				return "F4"
			KEY_F5:
				return "F5"
			KEY_F6:
				return "F6"
			KEY_F7:
				return "F7"
			KEY_F8:
				return "F8"
			KEY_F9:
				return "F9"
			KEY_F10:
				return "F10"
			KEY_F11:
				return "F11"
			KEY_F12:
				return "F12"
			KEY_F13:
				return "F13"
			KEY_F14:
				return "F14"
			KEY_F15:
				return "F15"
			KEY_F16:
				return "F16"
			KEY_KP_MULTIPLY:
				return "Num*"
			KEY_KP_DIVIDE:
				return "Num/"
			KEY_KP_SUBTRACT:
				return "Num-"
			KEY_KP_PERIOD:
				return "Num."
			KEY_KP_ADD:
				return "Num+"
			KEY_KP_0:
				return "Num0"
			KEY_KP_1:
				return "Num1"
			KEY_KP_2:
				return "Num2"
			KEY_KP_3:
				return "Num3"
			KEY_KP_4:
				return "Num4"
			KEY_KP_5:
				return "Num5"
			KEY_KP_6:
				return "Num6"
			KEY_KP_7:
				return "Num7"
			KEY_KP_8:
				return "Num8"
			KEY_KP_9:
				return "Num9"
			KEY_SPACE:
				return "Space"
			KEY_APOSTROPHE:
				return "'"
			KEY_COMMA:
				return ","
			KEY_MINUS:
				return "-"
			KEY_PERIOD:
				return "."
			KEY_SLASH:
				return "/"
			KEY_0:
				return "0"
			KEY_1:
				return "1"
			KEY_2:
				return "2"
			KEY_3:
				return "3"
			KEY_4:
				return "4"
			KEY_5:
				return "5"
			KEY_6:
				return "6"
			KEY_7:
				return "7"
			KEY_8:
				return "8"
			KEY_9:
				return "9"
			KEY_SEMICOLON:
				return ";"
			KEY_EQUAL:
				return "="
			KEY_A:
				return "A"
			KEY_B:
				return "B"
			KEY_C:
				return "C"
			KEY_D:
				return "D"
			KEY_E:
				return "E"
			KEY_F:
				return "F"
			KEY_G:
				return "G"
			KEY_H:
				return "H"
			KEY_I:
				return "I"
			KEY_J:
				return "J"
			KEY_K:
				return "K"
			KEY_L:
				return "L"
			KEY_M:
				return "M"
			KEY_N:
				return "N"
			KEY_O:
				return "O"
			KEY_P:
				return "P"
			KEY_Q:
				return "Q"
			KEY_R:
				return "R"
			KEY_S:
				return "S"
			KEY_T:
				return "T"
			KEY_U:
				return "U"
			KEY_V:
				return "V"
			KEY_W:
				return "W"
			KEY_X:
				return "X"
			KEY_Y:
				return "Y"
			KEY_Z:
				return "Z"
			KEY_BRACKETLEFT:
				return "["
			KEY_BACKSLASH:
				return "\\"
			KEY_BRACKETRIGHT:
				return "]"
			KEY_QUOTELEFT:
				return "`"
			KEY_ESCAPE:
				return "Esc"
			_:
				return "Error"
