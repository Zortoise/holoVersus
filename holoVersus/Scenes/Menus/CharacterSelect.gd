extends Node2D

var char_grid = {
#	5 : "Gura",
#	6 : "Random"
}
var grid_dimensions = [0, 0]

const STAGE_LIST_SIZE = 7
onready var loaded_stagelabel = load("res://Scenes/Menus/StageLabel.tscn")

var character_data = { # to be filled at _ready()
	"Random" : {
		"portrait" : load("res://Assets/UI/PortraitRandom.tscn"),
		"art" : ResourceLoader.load("res://Assets/UI/random.png"),
		"name" : "Random"
	}
#	"Gura" : {
#		"portrait" : load("res://Characters/Gura/Portrait.tscn"), 
#		"art" : ResourceLoader.load("res://Characters/Gura/UI/full_art.png"),
#		"select_sprite" : load("res://Characters/Gura/SelectSprite.tscn"),
#		"palettes" : { 
#			"2" : ResourceLoader.load("res://Characters/Gura/Palettes/2.png")
#		} 
#		"name" : "Gura"
#	}
}

var stage_data = { # to be filled at _ready()
	"Random" : {
		"name" : "Random",
		"select" : ResourceLoader.load("res://Assets/UI/random_select.png"), 
	}
#	"Aurora" : {
#		"name" : "Aurora",
#		"select" : ResourceLoader.load("res://Stages/Aurora/Resources/select.png"), 
#	}
}
var stage_array

var assist_data = { # to be filled at _ready()
	"Random" : {
		"name" : "Random",
		"select" : ResourceLoader.load("res://Assets/UI/assist_random.png"), 
	}
#	"GuraA" : {
#		"name" : "Gura",
#		"select" : ResourceLoader.load("res://Assists/GuraA/Select.png"), 
#	}
}
var assist_array

var sound := false
var battle_lock := false # set to true after starting battle, prevent certain actions like cancelling during the fade to black

var P1_phase := 0 # 0 is picking characters, 1 is picking stage, 2 is finishing picking and waiting for opponent, 3 is picking assists
var P1_picker_pos := 0
var P1_palette_picked := 1

var P2_phase := 0
var P2_picker_pos := 0
var P2_palette_picked := 1

func _ready():
	Globals.pausing = false
	
	BGM.play_random_in_folder("Common/CharSelectThemes")
	
	# load characters
	var dir = Directory.new()
	if dir.open("res://Characters/") == OK:
		dir.list_dir_begin(true)
		var character_name = dir.get_next()
		while character_name != "":
			if !character_name.begins_with("."):
				character_data[character_name] = {}
				character_data[character_name]["portrait"] = load("res://Characters/" + character_name + "/Portrait.tscn")
				character_data[character_name]["art"] = ResourceLoader.load("res://Characters/" + character_name + "/UI/full_art.png")
				character_data[character_name]["select_sprite"] = load("res://Characters/" + character_name + "/SelectSprite.tscn")
				var character_file = load("res://Characters/" + character_name + "/UniqChar.tscn").instance()
				character_data[character_name]["name"] = character_file.NAME
				if "ORDER" in character_file: character_data[character_name]["order"] = character_file.ORDER
				
				# load in palettes
				character_data[character_name]["palettes"] = {}
				var dir2 = Directory.new()
				if dir2.open("res://Characters/" + character_name + "/Palettes/") == OK:
					dir2.list_dir_begin(true)
					var palette_name = dir2.get_next()
					while palette_name != "":
						if palette_name.ends_with(".png.import"):
							var palette_name2 = palette_name.trim_suffix(".png.import")
							character_data[character_name]["palettes"][palette_name2] = \
									ResourceLoader.load("res://Characters/" + character_name + "/Palettes/" + palette_name2 + ".png")
						palette_name = dir2.get_next()
				else: print("Error: Cannot open Palette folder from CharacterSelect.gd")
				
			character_name = dir.get_next()
	else: print("Error: Cannot open Characters folder from CharacterSelect.gd")
	
	populate_char_grid()
	
	if dir.change_dir("res://Stages/") == OK:
		dir.list_dir_begin(true)
		var stage_name = dir.get_next()
		while stage_name != "":
			if !stage_name.begins_with("."):
				stage_data[stage_name] = {}
				stage_data[stage_name]["name"] = load("res://Stages/" + stage_name + "/UniqStage.tscn").instance().NAME
				stage_data[stage_name]["select"] = ResourceLoader.load("res://Stages/" + stage_name + "/Resources/select.png")
			stage_name = dir.get_next()
	else: print("Error: Cannot open Stages folder from CharacterSelect.gd")
	
	stage_array = stage_data.keys()
	populate_stage_lists()
	$P1_StageSelect.hide()
	$P2_StageSelect.hide()
	
	P1_changed_character()
	P2_changed_character()
	
	if Globals.assists == 1:
		if dir.change_dir("res://Assists/") == OK:
			dir.list_dir_begin(true)
			var assist_name = dir.get_next()
			while assist_name != "":
				if !assist_name.begins_with("."):
					assist_data[assist_name] = {}
					assist_data[assist_name]["name"] = load("res://Assists/" + assist_name + "/UniqNPC.tscn").instance().ASSIST_NAME
					assist_data[assist_name]["select"] = ResourceLoader.load("res://Assists/" + assist_name + "/select.png")
				assist_name = dir.get_next()
		else: print("Error: Cannot open Assists folder from CharacterSelect.gd")
		
		assist_array = assist_data.keys()
		populate_assist_lists()
		$P1_Assist/AssistSelect.hide()
		$P2_Assist/AssistSelect.hide()
	else:
		$P1_Assist.queue_free()
		$P2_Assist.queue_free()
	
	
	# load last picked characters and stages
	var last_picked = Settings.load_last_picked()
#	var last_picked = {
#		"P1_character" : P1_picker_pos,
#		"P1_palette" : P1_palette_picked,
#		"P1_stage" : $P1_StageSelect/StageList.get_child(3).stage_name,
#		"P2_character" : P2_picker_pos,
#		"P2_palette" : P2_palette_picked,
#		"P2_stage" : $P2_StageSelect/StageList.get_child(3).stage_name,
#	}
	if last_picked != null:
		load_last_picked(last_picked)
	
	sound = true # only switch on sound after initial setup of characters
	
	load_buttoncheck()
	
	
func load_last_picked(last_picked):
	if last_picked.P1_character != null:
		P1_picker_pos = last_picked.P1_character
		P1_changed_character()
	if last_picked.P2_character != null:
		P2_picker_pos = last_picked.P2_character
		P2_changed_character()

	if last_picked.P1_palette != null:
		if P1_picker_pos in char_grid and "palettes" in character_data[char_grid[P1_picker_pos]]:
			P1_palette_picked = wrapi(last_picked.P1_palette, 1, character_data[char_grid[P1_picker_pos]]["palettes"].size() + 2) # wrap around pointer
			if P1_palette_picked == 1:
				$P1_Sprite.get_child(0).material = null # cannot use $P1_Sprite/SelectSprite since the name will be different
			else:
				$P1_Sprite.get_child(0).material = ShaderMaterial.new()
				$P1_Sprite.get_child(0).material.shader = Loader.loaded_palette_shader
				$P1_Sprite.get_child(0).material.set_shader_param("swap", \
						character_data[char_grid[P1_picker_pos]]["palettes"][str(P1_palette_picked)])
		
	if last_picked.P2_palette != null:
		if P2_picker_pos in char_grid and "palettes" in  character_data[char_grid[P2_picker_pos]]:
			P2_palette_picked = wrapi(last_picked.P2_palette, 1, character_data[char_grid[P2_picker_pos]]["palettes"].size() + 2) # wrap around pointer
			if P2_palette_picked == 1:
				$P2_Sprite.get_child(0).material = null
			else:
				$P2_Sprite.get_child(0).material = ShaderMaterial.new()
				$P2_Sprite.get_child(0).material.shader = Loader.loaded_palette_shader
				$P2_Sprite.get_child(0).material.set_shader_param("swap", \
						character_data[char_grid[P2_picker_pos]]["palettes"][str(P2_palette_picked)])


#	if last_picked.P1_input_style != null:
#		P1_input_style = last_picked.P1_input_style
#		change_input_style($P1_InputStyle, last_picked.P1_input_style)
		
#	if last_picked.P2_input_style != null:
#		P2_input_style = last_picked.P2_input_style
#		change_input_style($P2_InputStyle, last_picked.P2_input_style)
		

	if last_picked.P1_stage != null:
		if last_picked.P1_stage in stage_array:
			while $P1_StageSelect/StageList.get_child(3).stage_name != last_picked.P1_stage:
				shift_stage_list(0, 1)
	if last_picked.P2_stage != null:
		if last_picked.P2_stage in stage_array:
			while $P2_StageSelect/StageList.get_child(3).stage_name != last_picked.P2_stage:
				shift_stage_list(1, 1)
			
	if Globals.assists == 1:
		if last_picked.P1_assist != "":
			if last_picked.P1_assist in assist_array:
				while $P1_Assist/AssistSelect/AssistList.get_child(3).stage_name != last_picked.P1_assist:
					shift_assist_list(0, 1)
		if last_picked.P2_assist != "":
			if last_picked.P2_assist in assist_array:
				while $P2_Assist/AssistSelect/AssistList.get_child(3).stage_name != last_picked.P2_assist:
					shift_assist_list(1, 1)
					
	Globals.P1_assist = last_picked.P1_assist # temp
	Globals.P2_assist = last_picked.P2_assist # temp
			
	
func populate_char_grid():
	
	var total = $Grid.get_child_count()
	grid_dimensions[0] = $Grid.columns # 8
	grid_dimensions[1] = int(ceil(total/grid_dimensions[0])) # 2
	
	var center_indexes = [] # 4, 12
	var left_indexes = [] # 0, 8
	var right_indexes = [] # 7, 15
	var center_point = int(ceil((grid_dimensions[0] + 1) / 2.0)) - 1 # 4
	
	for y in grid_dimensions[1]:
		center_indexes.append(center_point + (y * grid_dimensions[0]))
		left_indexes.append(y * grid_dimensions[0])
		right_indexes.append(left_indexes[y] + grid_dimensions[0] - 1)
		
	var index_array = []
	for level in center_indexes.size():
		var current_coord = center_indexes[level] # 4, 12
		var changer := -1
		while current_coord >= left_indexes[level] and current_coord <= right_indexes[level]:
			index_array.append(current_coord)
			current_coord += changer
			changer = -changer
			if changer < 0: changer -= 1
			else: changer += 1
			
	var char_names := []
	var char_names2 := []
	for character in character_data.keys(): # list of name_keys
		if "order" in character_data[character]:
			var order = min(character_data[character].order, char_names.size())
			char_names.insert(order, character)
		elif character != "Random":
			char_names2.append(character)
			
	char_names.append_array(char_names2)
	
	if posmod(char_names.size(), 2) == 0:
		char_names.append("Random")
	else:
		char_names.insert(char_names.size() - 1, "Random") # to ensure Random is the rightmost one

	for char_pos in char_names.size():
		char_grid[index_array[char_pos]] = char_names[char_pos]

	for character_number in char_grid.keys():
		var new_sprite = character_data[char_grid[character_number]]["portrait"].instance()
		$Grid.get_child(character_number).add_child(new_sprite)
		$Grid.get_child(character_number).modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	P1_picker_pos = center_point - (1 - posmod(grid_dimensions[0], 2))
	P2_picker_pos = center_point
	
	
func populate_stage_lists():
	var stage_array_pointer := 0
	
	# remove test children
	for x in $P1_StageSelect/StageList.get_children():
		x.free()
	for x in $P2_StageSelect/StageList.get_children():
		x.free()
	
	for x in STAGE_LIST_SIZE:
		# add new labels
		var new_stagelabel = loaded_stagelabel.instance()
		$P1_StageSelect/StageList.add_child(new_stagelabel)
		var new_stagelabel2 = loaded_stagelabel.instance()
		$P2_StageSelect/StageList.add_child(new_stagelabel2)
		# change text
		new_stagelabel.stage_name = stage_array[stage_array_pointer]
		new_stagelabel.text = stage_data[stage_array[stage_array_pointer]].name
		new_stagelabel2.stage_name = stage_array[stage_array_pointer]
		new_stagelabel2.text = stage_data[stage_array[stage_array_pointer]].name
		# next stage, wrap around
		stage_array_pointer += 1
		stage_array_pointer = wrapi(stage_array_pointer, 0, stage_array.size())
	
	# shift lists so that get_child(3) points to the first stage
	for x in 3:
		shift_stage_list(0, 1)
	for x in 3:
		shift_stage_list(1, 1)
		
		
func populate_assist_lists():
	var assist_array_pointer := 0
	
	# remove test children
	for x in $P1_Assist/AssistSelect/AssistList.get_children():
		x.free()
	for x in $P2_Assist/AssistSelect/AssistList.get_children():
		x.free()
	
	for x in STAGE_LIST_SIZE:
		# add new labels
		var new_assistlabel = loaded_stagelabel.instance()
		$P1_Assist/AssistSelect/AssistList.add_child(new_assistlabel)
		var new_assistlabel2 = loaded_stagelabel.instance()
		$P2_Assist/AssistSelect/AssistList.add_child(new_assistlabel2)
		# change text
		new_assistlabel.stage_name = assist_array[assist_array_pointer]
		new_assistlabel.text = assist_data[assist_array[assist_array_pointer]].name
		new_assistlabel2.stage_name = assist_array[assist_array_pointer]
		new_assistlabel2.text = assist_data[assist_array[assist_array_pointer]].name
		# next assist, wrap around
		assist_array_pointer += 1
		assist_array_pointer = wrapi(assist_array_pointer, 0, assist_array.size())
	
	# shift lists so that get_child(3) points to the first stage
	for x in 3:
		shift_assist_list(0, 1)
	for x in 3:
		shift_assist_list(1, 1)
		
		
#func change_input_style(input_style_node, input_style):
#	if input_style == 0:
#		input_style_node.get_node("HybridStyle/AnimationPlayer").play("flashing")
#		input_style_node.get_node("ClassicStyle/AnimationPlayer").play("gray")
#	else:
#		input_style_node.get_node("HybridStyle/AnimationPlayer").play("gray")
#		input_style_node.get_node("ClassicStyle/AnimationPlayer").play("flashing")
		
		
func load_buttoncheck():
	
	$P1_ButtonCheck.hide()
	$P2_ButtonCheck.hide()
	
	var input_map = Settings.load_input_map()
	var TAP_JUMP_OPTIONS = ["off", "on"]
	var INPUT_BUFFER_OPTIONS = ["none", "1 frame", "2 frames", "3 frames", "4 frames", "5 frames", "6 frames"
			, "7 frames", "8 frames", "9 frames", "10 frames"]
	var INPUT_ASSIST_OPTIONS = ["off", "on"]
	var DJ_FASTFALL_OPTIONS = ["off", "on"]
	
	for player_ID in [0, 1]:
		var player_index = str(player_ID + 1)
		var grid = get_node("P" + player_index + "_ButtonCheck/ButtonCheckGrid")

		grid.get_node("Up").load_button("Up", Settings.button_to_string(input_map["P" + player_index + "_up"]))
		grid.get_node("Down").load_button("Down", Settings.button_to_string(input_map["P" + player_index + "_down"]))
		grid.get_node("Left").load_button("Left", Settings.button_to_string(input_map["P" + player_index + "_left"]))
		grid.get_node("Right").load_button("Right", Settings.button_to_string(input_map["P" + player_index + "_right"]))
		grid.get_node("Jump").load_button("Jump", Settings.button_to_string(input_map["P" + player_index + "_jump"]))

		grid.get_node("Light").load_button("Light", Settings.button_to_string(input_map["P" + player_index + "_light"]))
		grid.get_node("Fierce").load_button("Fierce", Settings.button_to_string(input_map["P" + player_index + "_fierce"]))
		grid.get_node("Dash").load_button("Dash", Settings.button_to_string(input_map["P" + player_index + "_dash"]))
		grid.get_node("Aux").load_button("Aux", Settings.button_to_string(input_map["P" + player_index + "_aux"]))
		grid.get_node("Block").load_button("Block", Settings.button_to_string(input_map["P" + player_index + "_block"]))
		grid.get_node("Modifier").load_button("Mod", Settings.button_to_string(input_map["P" + player_index + "_modifier"]))
		grid.get_node("Unique").load_button("Unique", Settings.button_to_string(input_map["P" + player_index + "_unique"]))

		grid.get_node("TapJump2").text = TAP_JUMP_OPTIONS[input_map["P" + player_index + "_tapjump"]]
		grid.get_node("DJFastfall2").text = DJ_FASTFALL_OPTIONS[input_map["P" + player_index + "_dj_fastfall"]]
		grid.get_node("InputBuffer2").text = INPUT_BUFFER_OPTIONS[input_map["P" + player_index + "_buffer"]]
		grid.get_node("InputAssist2").text = INPUT_ASSIST_OPTIONS[input_map["P" + player_index + "_input_assist"]]
		

func _physics_process(_delta):
	
	if P1_phase == 0:
		if Input.is_action_just_pressed("P1_fierce"):
			Globals.pausing = true
		if Input.is_action_just_released("P1_fierce"):
			Globals.pausing = false
		
	if P2_phase == 0:
		if Input.is_action_just_pressed("P2_fierce"):
			Globals.pausing = true
		if Input.is_action_just_released("P2_fierce"):
			Globals.pausing = false
		
	# quitting
	if Globals.pausing and !$HoldToQuit/AnimationPlayer.is_playing():
		$HoldToQuit/AnimationPlayer.play("hold")
	elif !Globals.pausing and $HoldToQuit/AnimationPlayer.is_playing():
		$HoldToQuit/AnimationPlayer.play("RESET")
		
	if Input.is_action_pressed("P1_modifier"): # reveal/hide button check
		$P1_ButtonCheck.show()
	else:
		$P1_ButtonCheck.hide()
	if Input.is_action_pressed("P2_modifier"):
		$P2_ButtonCheck.show()
	else:
		$P2_ButtonCheck.hide()
		
	
	# directional keys
	var P1_dir = $P1DirInputs.P1_dir
		
	var P2_dir = $P2DirInputs.P2_dir
	
	move_pickers(P1_dir, P2_dir)
	move_stage_picker(P1_dir, P2_dir)
	
	if Globals.assists == 1:
		move_assist_picker(P1_dir, P2_dir)

	# change palette, in phase 0 only
	var P1_p_dir = 0
	if Input.is_action_just_pressed("P1_aux"):
		P1_p_dir -= 1
	if Input.is_action_just_pressed("P1_block"):
		P1_p_dir += 1

	var P2_p_dir = 0
	if Input.is_action_just_pressed("P2_aux"):
		P2_p_dir -= 1
	if Input.is_action_just_pressed("P2_block"):
		P2_p_dir += 1
	
	change_palette(P1_p_dir, P2_p_dir)
		
	
	if Input.is_action_just_pressed("P1_light"): # select character/stage
		match P1_phase:
			0:
				P1_picked_character()
			1:
				P1_picked_stage()
			3:
				P1_picked_assist()
	if Input.is_action_just_pressed("P2_light"): # select character/stage
		match P2_phase:
			0:
				P2_picked_character()
			1:
				P2_picked_stage()
			3:
				P2_picked_assist()
		
	if Input.is_action_just_pressed("P1_fierce"): # unselect character/stage
		match P1_phase:
			1:
				if Globals.assists == 1:
					P1_unpicked_assist()
				else:
					P1_unpicked_character()
			2:
				P1_unpicked_stage()
			3:
				P1_unpicked_character()
	if Input.is_action_just_pressed("P2_fierce"): # unselect character/stage
		match P2_phase:
			1:
				if Globals.assists == 1:
					P2_unpicked_assist()
				else:
					P2_unpicked_character()
			2:
				P2_unpicked_stage()
			3:
				P2_unpicked_character()
			
	if P1_phase == 2 and P2_phase == 2: # both players have picked characters and stages
		start_battle()
	
# ------------------------------------------------------------------------------------------------------------------------
	
func move_pickers(P1_dir, P2_dir):
	
	var max_rows := int(ceil($Grid.get_child_count()/$Grid.columns))
	
	if P1_phase == 0:
		if P1_dir.x == 1:
			P1_picker_pos += 1
			if P1_picker_pos == $Grid.columns: P1_picker_pos = 0
			elif P1_picker_pos == $Grid.columns * 2: P1_picker_pos = $Grid.columns
#			elif P1_picker_pos == $Grid.columns * 3: P1_picker_pos = $Grid.columns * 2
			P1_changed_character()
		elif P1_dir.x == -1:
			P1_picker_pos -= 1
			if P1_picker_pos == -1: P1_picker_pos = $Grid.columns - 1
			elif P1_picker_pos == $Grid.columns - 1: P1_picker_pos = ($Grid.columns * 2) - 1
#			elif P1_picker_pos == ($Grid.columns * 2) - 1: P1_picker_pos = ($Grid.columns * 3) - 1
			P1_changed_character()
		if P1_dir.y == 1:
			P1_picker_pos += $Grid.columns
			if P1_picker_pos >= $Grid.columns * max_rows: P1_picker_pos -= $Grid.columns * max_rows
			P1_changed_character()
		elif P1_dir.y == -1:
			P1_picker_pos -= $Grid.columns
			if P1_picker_pos < 0: P1_picker_pos += $Grid.columns * max_rows
			P1_changed_character()
		
	if P2_phase == 0:
		if P2_dir.x == 1:
			P2_picker_pos += 1
			if P2_picker_pos == $Grid.columns: P2_picker_pos = 0
			elif P2_picker_pos == $Grid.columns * 2: P2_picker_pos = $Grid.columns
#			elif P2_picker_pos == $Grid.columns * 3: P2_picker_pos = $Grid.columns * 2
			P2_changed_character()
		elif P2_dir.x == -1:
			P2_picker_pos -= 1
			if P2_picker_pos == -1: P2_picker_pos = $Grid.columns - 1
			elif P2_picker_pos == $Grid.columns - 1: P2_picker_pos = ($Grid.columns * 2) - 1
#			elif P2_picker_pos == ($Grid.columns * 2) - 1: P2_picker_pos = ($Grid.columns * 3) - 1
			P2_changed_character()
		if P2_dir.y == 1:
			P2_picker_pos += $Grid.columns
			if P2_picker_pos >= $Grid.columns * max_rows: P2_picker_pos -= $Grid.columns * max_rows
			P2_changed_character()
		elif P2_dir.y == -1:
			P2_picker_pos -= $Grid.columns
			if P2_picker_pos < 0: P2_picker_pos += $Grid.columns * max_rows
			P2_changed_character()		
	
func P1_changed_character():
	if sound:
		play_audio("ui_move2", {"vol":-10})
	P1_palette_picked = 1 # reset picked palette
	$P1_Picker.rect_position = $Grid.get_child(P1_picker_pos).rect_global_position # move picker
	if P1_picker_pos in char_grid: # update art/select sprite/name
		var char_name: String = char_grid[P1_picker_pos]
		$P1_FullArt.texture = character_data[char_name]["art"]
		if $P1_Sprite.get_child_count() > 0:
			$P1_Sprite.get_child(0).free()
		if "select_sprite" in character_data[char_name]:
			var new_sprite = character_data[char_name]["select_sprite"].instance()
			$P1_Sprite.add_child(new_sprite)
			new_sprite.position.y -= (new_sprite.get_node("Feet").position.y - 23)
		$P1_Name.text = character_data[char_name]["name"]
	else: # blank panel
		$P1_FullArt.texture = null
		if $P1_Sprite.get_child_count() > 0:
			$P1_Sprite.get_child(0).free()
		$P1_Name.text = ""
	
func P2_changed_character():
	if sound:
		play_audio("ui_move2", {"vol":-10})
	P2_palette_picked = 1 # reset picked palette
	$P2_Picker.rect_position = $Grid.get_child(P2_picker_pos).rect_global_position # move picker
	if P2_picker_pos in char_grid:
		var char_name: String = char_grid[P2_picker_pos]
		$P2_FullArt.texture = character_data[char_name]["art"]
		if $P2_Sprite.get_child_count() > 0:
			$P2_Sprite.get_child(0).free()
		if "select_sprite" in character_data[char_name]:
			var new_sprite = character_data[char_name]["select_sprite"].instance()
			$P2_Sprite.add_child(new_sprite)
			new_sprite.position.y -= (new_sprite.get_node("Feet").position.y - 23)
		$P2_Name.text = character_data[char_name]["name"]
	else:
		$P2_FullArt.texture = null
		if $P2_Sprite.get_child_count() > 0:
			$P2_Sprite.get_child(0).free()
		$P2_Name.text = ""
	

func change_palette(P1_p_dir, P2_p_dir):
	
	if P1_phase == 0 and P1_p_dir != 0 and P1_picker_pos in char_grid and $P1_Sprite.get_child_count() > 0: # last one is just in case
		P1_palette_picked += P1_p_dir # move pointer
		play_audio("ui_move2", {"vol":-10})
		var char_name: String = char_grid[P1_picker_pos]
		P1_palette_picked = wrapi(P1_palette_picked, 1, character_data[char_name]["palettes"].size() + 2) # wrap around pointer
		if P1_palette_picked == 1:
			$P1_Sprite.get_child(0).material = null # cannot use $P1_Sprite/SelectSprite since the name will be different
		else:
			$P1_Sprite.get_child(0).material = ShaderMaterial.new()
			$P1_Sprite.get_child(0).material.shader = Loader.loaded_palette_shader
			$P1_Sprite.get_child(0).material.set_shader_param("swap", character_data[char_name]["palettes"][str(P1_palette_picked)])
			
	if P2_phase == 0 and P2_p_dir != 0 and P2_picker_pos in char_grid and $P2_Sprite.get_child_count() > 0: # last one is just in case
		P2_palette_picked += P2_p_dir # move pointer
		play_audio("ui_move2", {"vol":-10})
		var char_name: String = char_grid[P2_picker_pos]
		P2_palette_picked = wrapi(P2_palette_picked, 1, character_data[char_name]["palettes"].size() + 2) # wrap around pointer
		
		if P2_palette_picked == 1:
			$P2_Sprite.get_child(0).material = null
		else:
			$P2_Sprite.get_child(0).material = ShaderMaterial.new()
			$P2_Sprite.get_child(0).material.shader = Loader.loaded_palette_shader
			$P2_Sprite.get_child(0).material.set_shader_param("swap", character_data[char_name]["palettes"][str(P2_palette_picked)])


func P1_picked_character():
	if P1_picker_pos in char_grid:
		play_audio("ui_accept2", {})
		$P1_Picker/AnimationPlayer.play("RESET")
		$P1_FullArt/AnimationPlayer.play("flash")
		yield(get_tree(),"idle_frame")
		if Globals.assists == 1:
			P1_phase = 3
			$P1_Assist/Label/AnimationPlayer.play("flashing")
			$P1_Assist/AssistSelect.show()
		else:
			P1_phase = 1
			$P1_StageSelect.show()
		
		# if same character and palette, change palette automatically
		if char_grid[P1_picker_pos] != "Random":
			if P2_phase != 0 and char_grid[P1_picker_pos] == char_grid[P2_picker_pos] and P1_palette_picked == P2_palette_picked:
				var char_name: String = char_grid[P1_picker_pos]
				P1_palette_picked = wrapi(P1_palette_picked + 1, 1, character_data[char_name]["palettes"].size() + 2) # wrap around pointer
				if P1_palette_picked == 1:
					$P1_Sprite.get_child(0).material = null # cannot use $P1_Sprite/SelectSprite since the name will be different
				else:
					$P1_Sprite.get_child(0).material = ShaderMaterial.new()
					$P1_Sprite.get_child(0).material.shader = Loader.loaded_palette_shader
					$P1_Sprite.get_child(0).material.set_shader_param("swap", character_data[char_name]["palettes"][str(P1_palette_picked)])
	
func P2_picked_character():
	if P2_picker_pos in char_grid:
		play_audio("ui_accept2", {})
		$P2_Picker/AnimationPlayer.play("RESET")
		$P2_FullArt/AnimationPlayer.play("flash")
		yield(get_tree(),"idle_frame")
		if Globals.assists == 1:
			P2_phase = 3
			$P2_Assist/Label/AnimationPlayer.play("flashing")
			$P2_Assist/AssistSelect.show()
		else:
			P2_phase = 1
			$P2_StageSelect.show()
		
		# if same character and palette, change palette automatically
		if char_grid[P2_picker_pos] != "Random":
			if P1_phase != 0 and char_grid[P1_picker_pos] == char_grid[P2_picker_pos] and P1_palette_picked == P2_palette_picked:
				var char_name: String = char_grid[P1_picker_pos]
				P2_palette_picked = wrapi(P2_palette_picked + 1, 1, character_data[char_name]["palettes"].size() + 2) # wrap around pointer
				if P2_palette_picked == 1:
					$P2_Sprite.get_child(0).material = null # cannot use $P1_Sprite/SelectSprite since the name will be different
				else:
					$P2_Sprite.get_child(0).material = ShaderMaterial.new()
					$P2_Sprite.get_child(0).material.shader = Loader.loaded_palette_shader
					$P2_Sprite.get_child(0).material.set_shader_param("swap", character_data[char_name]["palettes"][str(P2_palette_picked)])
		
		
func P1_unpicked_character():
	play_audio("ui_back", {})
	$P1_Picker/AnimationPlayer.play("flashing")
	yield(get_tree(),"idle_frame")
	if P1_phase == 1:
		$P1_StageSelect.hide()
	elif P1_phase == 3:
		$P1_Assist/AssistSelect.hide()
		$P1_Assist/Label/AnimationPlayer.play("gray")
	P1_phase = 0
	
func P2_unpicked_character():
	play_audio("ui_back", {})
	$P2_Picker/AnimationPlayer.play("flashing")
	yield(get_tree(),"idle_frame")
	if P2_phase == 1:
		$P2_StageSelect.hide()
	elif P2_phase == 3:
		$P2_Assist/AssistSelect.hide()
		$P2_Assist/Label/AnimationPlayer.play("gray")
	P2_phase = 0
	
# ------------------------------------------------------------------------------------------------------------------------
	
func move_stage_picker(P1_dir, P2_dir):
	if P1_phase == 1 and P1_dir.y != 0:
		shift_stage_list(0, P1_dir.y)
	if P2_phase == 1 and P2_dir.y != 0:
		shift_stage_list(1, P2_dir.y)
		

func shift_stage_list(player_ID, v_dir):
	if player_ID == 0: # player 1
		var first_child = $P1_StageSelect/StageList.get_child(0)
		var last_child = $P1_StageSelect/StageList.get_child(STAGE_LIST_SIZE - 1)
		
		if v_dir == 1: # move down, shift list upward
			if sound:
				play_audio("ui_move2", {"vol":-10})
			first_child.free() # remove 1st child
			var index = stage_array.find(last_child.stage_name) # find index of last child in stage_array
			index = wrapi(index + 1, 0, stage_array.size()) # get index of next stage in stage_array, wraparound
			var new_stagelabel = loaded_stagelabel.instance() # add new child
			$P1_StageSelect/StageList.add_child(new_stagelabel)
			new_stagelabel.stage_name = stage_array[index]
			new_stagelabel.text = stage_data[stage_array[index]].name
		elif v_dir == -1: # move up, shift list downward
			if sound:
				play_audio("ui_move2", {"vol":-10})
			last_child.free() # remove last child
			var index = stage_array.find(first_child.stage_name) # find index of first child in stage_array
			index = wrapi(index - 1, 0, stage_array.size()) # get index of previous stage in stage_array, wraparound
			var new_stagelabel = loaded_stagelabel.instance() # add new child
			$P1_StageSelect/StageList.add_child(new_stagelabel)
			$P1_StageSelect/StageList.move_child(new_stagelabel, 0) # make child the new first child
			new_stagelabel.stage_name = stage_array[index]
			new_stagelabel.text = stage_data[stage_array[index]].name
			
		$P1_Stage.texture = stage_data[$P1_StageSelect/StageList.get_child(3).stage_name].select # update stage texture
		for x in $P1_StageSelect/StageList.get_children(): # return color to normal
			x.modulate = Color(1.0, 1.0, 1.0)
		$P1_StageSelect/StageList.get_child(3).modulate = Color(1.5, 1.5, 1.5) # brighten stage pointed at
			
	elif player_ID == 1:
		var first_child = $P2_StageSelect/StageList.get_child(0)
		var last_child = $P2_StageSelect/StageList.get_child(STAGE_LIST_SIZE - 1)
		
		if v_dir == 1: # move down, shift list upward
			if sound:
				play_audio("ui_move2", {"vol":-10})
			first_child.free() # remove 1st child
			var index = stage_array.find(last_child.stage_name) # find index of last child in stage_array
			index = wrapi(index + 1, 0, stage_array.size()) # get index of next stage in stage_array, wraparound
			var new_stagelabel = loaded_stagelabel.instance() # add new child
			$P2_StageSelect/StageList.add_child(new_stagelabel)
			new_stagelabel.stage_name = stage_array[index]
			new_stagelabel.text = stage_data[stage_array[index]].name
		elif v_dir == -1: # move up, shift list downward
			if sound:
				play_audio("ui_move2", {"vol":-10})
			last_child.free() # remove last child
			var index = stage_array.find(first_child.stage_name) # find index of first child in stage_array
			index = wrapi(index - 1, 0, stage_array.size()) # get index of previous stage in stage_array, wraparound
			var new_stagelabel = loaded_stagelabel.instance() # add new child
			$P2_StageSelect/StageList.add_child(new_stagelabel)
			$P2_StageSelect/StageList.move_child(new_stagelabel, 0) # make child the new first child
			new_stagelabel.stage_name = stage_array[index]
			new_stagelabel.text = stage_data[stage_array[index]].name
			
		$P2_Stage.texture = stage_data[$P2_StageSelect/StageList.get_child(3).stage_name].select # update stage texture
		for x in $P2_StageSelect/StageList.get_children(): # return color to normal
			x.modulate = Color(1.0, 1.0, 1.0)
		$P2_StageSelect/StageList.get_child(3).modulate = Color(1.5, 1.5, 1.5) # brighten stage pointed at
	
func P1_picked_stage():
	play_audio("ui_accept2", {})
	$P1_Stage/AnimationPlayer.play("flash")
	yield(get_tree(),"idle_frame")
	P1_phase = 2
	$P1_StageSelect.hide()
	
func P2_picked_stage():
	play_audio("ui_accept2", {})
	$P2_Stage/AnimationPlayer.play("flash")
	yield(get_tree(),"idle_frame")
	P2_phase = 2
	$P2_StageSelect.hide()
	
func P1_unpicked_stage():
	if !battle_lock:
		play_audio("ui_back", {})
		yield(get_tree(),"idle_frame")
		P1_phase = 1
		$P1_StageSelect.show()
	
func P2_unpicked_stage():
	if !battle_lock:
		play_audio("ui_back", {})
		yield(get_tree(),"idle_frame")
		P2_phase = 1
		$P2_StageSelect.show()
		
# ------------------------------------------------------------------------------------------------------------------------
		
func move_assist_picker(P1_dir, P2_dir):
	if P1_phase == 3 and P1_dir.y != 0:
		shift_assist_list(0, P1_dir.y)
	if P2_phase == 3 and P2_dir.y != 0:
		shift_assist_list(1, P2_dir.y)

func P1_picked_assist():
	play_audio("ui_accept2", {})
	$P1_Assist/Back/Sprite/AnimationPlayer.play("flash")
	yield(get_tree(),"idle_frame")
	P1_phase = 1
	$P1_StageSelect.show()
	$P1_Assist/Label/AnimationPlayer.play("white")
	$P1_Assist/AssistSelect.hide()
	
func P2_picked_assist():
	play_audio("ui_accept2", {})
	$P2_Assist/Back/Sprite/AnimationPlayer.play("flash")
	yield(get_tree(),"idle_frame")
	P2_phase = 1
	$P2_StageSelect.show()
	$P2_Assist/Label/AnimationPlayer.play("white")
	$P2_Assist/AssistSelect.hide()
	
func P1_unpicked_assist():
	play_audio("ui_back", {})
	yield(get_tree(),"idle_frame")
	P1_phase = 3
	$P1_StageSelect.hide()
	$P1_Assist/Label/AnimationPlayer.play("flashing")
	$P1_Assist/AssistSelect.show()
	
func P2_unpicked_assist():
	play_audio("ui_back", {})
	yield(get_tree(),"idle_frame")
	P2_phase = 3
	$P2_StageSelect.hide()
	$P2_Assist/Label/AnimationPlayer.play("flashing")
	$P2_Assist/AssistSelect.show()

func shift_assist_list(player_ID, v_dir):
	if player_ID == 0: # player 1
		var first_child = $P1_Assist/AssistSelect/AssistList.get_child(0)
		var last_child = $P1_Assist/AssistSelect/AssistList.get_child(STAGE_LIST_SIZE - 1)
		
		if v_dir == 1: # move down, shift list upward
			if sound:
				play_audio("ui_move2", {"vol":-10})
			first_child.free() # remove 1st child
			var index = assist_array.find(last_child.stage_name) # find index of last child in assist_array
			index = wrapi(index + 1, 0, assist_array.size()) # get index of next assist in assist_array, wraparound
			var new_assistlabel = loaded_stagelabel.instance() # add new child
			$P1_Assist/AssistSelect/AssistList.add_child(new_assistlabel)
			new_assistlabel.stage_name = assist_array[index]
			new_assistlabel.text = assist_data[assist_array[index]].name
		elif v_dir == -1: # move up, shift list downward
			if sound:
				play_audio("ui_move2", {"vol":-10})
			last_child.free() # remove last child
			var index = assist_array.find(first_child.stage_name) # find index of first child in assist_array
			index = wrapi(index - 1, 0, assist_array.size()) # get index of previous assist in assist_array, wraparound
			var new_assistlabel = loaded_stagelabel.instance() # add new child
			$P1_Assist/AssistSelect/AssistList.add_child(new_assistlabel)
			$P1_Assist/AssistSelect/AssistList.move_child(new_assistlabel, 0) # make child the new first child
			new_assistlabel.stage_name = assist_array[index]
			new_assistlabel.text = assist_data[assist_array[index]].name
			
		$P1_Assist/Back/Sprite.texture = assist_data[$P1_Assist/AssistSelect/AssistList.get_child(3).stage_name].select # update assist texture
		for x in $P1_Assist/AssistSelect/AssistList.get_children(): # return color to normal
			x.modulate = Color(1.0, 1.0, 1.0)
		$P1_Assist/AssistSelect/AssistList.get_child(3).modulate = Color(1.5, 1.5, 1.5) # brighten assist pointed at
			
	elif player_ID == 1:
		var first_child = $P2_Assist/AssistSelect/AssistList.get_child(0)
		var last_child = $P2_Assist/AssistSelect/AssistList.get_child(STAGE_LIST_SIZE - 1)
		
		if v_dir == 1: # move down, shift list upward
			if sound:
				play_audio("ui_move2", {"vol":-10})
			first_child.free() # remove 1st child
			var index = assist_array.find(last_child.stage_name) # find index of last child in assist_array
			index = wrapi(index + 1, 0, assist_array.size()) # get index of next assist in assist_array, wraparound
			var new_assistlabel = loaded_stagelabel.instance() # add new child
			$P2_Assist/AssistSelect/AssistList.add_child(new_assistlabel)
			new_assistlabel.stage_name = assist_array[index]
			new_assistlabel.text = assist_data[assist_array[index]].name
		elif v_dir == -1: # move up, shift list downward
			if sound:
				play_audio("ui_move2", {"vol":-10})
			last_child.free() # remove last child
			var index = assist_array.find(first_child.stage_name) # find index of first child in assist_array
			index = wrapi(index - 1, 0, assist_array.size()) # get index of previous assist in assist_array, wraparound
			var new_assistlabel = loaded_stagelabel.instance() # add new child
			$P2_Assist/AssistSelect/AssistList.add_child(new_assistlabel)
			$P2_Assist/AssistSelect/AssistList.move_child(new_assistlabel, 0) # make child the new first child
			new_assistlabel.stage_name = assist_array[index]
			new_assistlabel.text = assist_data[assist_array[index]].name
			
		$P2_Assist/Back/Sprite.texture = assist_data[$P2_Assist/AssistSelect/AssistList.get_child(3).stage_name].select # update assist texture
		for x in $P2_Assist/AssistSelect/AssistList.get_children(): # return color to normal
			x.modulate = Color(1.0, 1.0, 1.0)
		$P2_Assist/AssistSelect/AssistList.get_child(3).modulate = Color(1.5, 1.5, 1.5) # brighten assist pointed at

# ------------------------------------------------------------------------------------------------------------------------

func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	
func start_battle():
	battle_lock = true
	
	# 50% chance of either stage picked
	if Globals.random.randi_range(0, 1) == 0:
		Globals.stage_ref = $P1_StageSelect/StageList.get_child(3).stage_name
	else:
		Globals.stage_ref = $P2_StageSelect/StageList.get_child(3).stage_name
#	Globals.stage_ref = selected_stage

	Globals.P1_char_ref[0] = char_grid[P1_picker_pos]
	Globals.P1_palette[0] = P1_palette_picked

	Globals.P2_char_ref[0] = char_grid[P2_picker_pos]
	Globals.P2_palette[0] = P2_palette_picked
	
	# saving last picked characters and stages
	var last_picked = {
		"P1_character" : P1_picker_pos,
		"P1_palette" : P1_palette_picked,
		"P1_stage" : $P1_StageSelect/StageList.get_child(3).stage_name,
		"P1_assist" : Globals.P1_assist,
		"P2_character" : P2_picker_pos,
		"P2_palette" : P2_palette_picked,
		"P2_stage" : $P2_StageSelect/StageList.get_child(3).stage_name,
		"P2_assist" : Globals.P2_assist,
	}
	
	if Globals.assists == 1:
		Globals.P1_assist = $P1_Assist/AssistSelect/AssistList.get_child(3).stage_name
		Globals.P2_assist = $P2_Assist/AssistSelect/AssistList.get_child(3).stage_name
		last_picked.P1_assist = Globals.P1_assist
		last_picked.P2_assist = Globals.P2_assist
	
	Settings.save_last_picked(last_picked)
	
	
	# handling random
	if Globals.P1_char_ref[0] == "Random":
		var character_array = char_grid.values()
		character_array.erase("Random")
		character_array.shuffle()
		Globals.P1_char_ref[0] = character_array[0]
		# random palette
		Globals.P1_palette[0] = Globals.random.randi_range(1, character_data[Globals.P1_char_ref[0]]["palettes"].size() + 1)
		# if same character and palette, shift to next palette
		if Globals.P1_char_ref[0] == Globals.P2_char_ref[0] and Globals.P1_palette[0] == Globals.P2_palette[0]:
			Globals.P1_palette[0] = wrapi(Globals.P1_palette[0] + 1, 1, character_data[Globals.P1_char_ref[0]]["palettes"].size() + 2)
	if Globals.P2_char_ref[0] == "Random":
		var character_array = char_grid.values()
		character_array.erase("Random")
		character_array.shuffle()
		Globals.P2_char_ref[0] = character_array[0]
		# random palette
		Globals.P2_palette[0] = Globals.random.randi_range(1, character_data[Globals.P2_char_ref[0]]["palettes"].size() + 1)
		# if same character and palette, shift to next palette
		if Globals.P1_char_ref[0] == Globals.P2_char_ref[0] and Globals.P1_palette[0] == Globals.P2_palette[0]:
			Globals.P2_palette[0] = wrapi(Globals.P2_palette[0] + 1, 1, character_data[Globals.P2_char_ref[0]]["palettes"].size() + 2)
		
	if Globals.stage_ref == "Random":
		var new_stage_array = stage_data.keys()
		new_stage_array.erase("Random")
		new_stage_array.shuffle()
		Globals.stage_ref = new_stage_array[0]
		
	if Globals.assists == 1:
		if Globals.P1_assist == "Random":
			var new_assist_array = assist_data.keys()
			new_assist_array.erase("Random")
			new_assist_array.shuffle()
			Globals.P1_assist = new_assist_array[0]
		if Globals.P2_assist == "Random":
			var new_assist_array = assist_data.keys()
			new_assist_array.erase("Random")
			new_assist_array.shuffle()
			Globals.P2_assist = new_assist_array[0]
	else:
		Globals.P1_assist = ""
		Globals.P2_assist = ""
		
	BGM.fade()
	$Transition.play("transit_to_battle")
	
	
func change_scene(new_scene: String): # called by animation
	Globals.next_scene = new_scene
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/LoadingScreen.tscn")
