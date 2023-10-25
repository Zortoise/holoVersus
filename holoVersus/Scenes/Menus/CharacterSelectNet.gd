extends Node2D

var char_grid = {
}
var grid_dimensions = [0, 0]

const STAGE_LIST_SIZE = 7
onready var loaded_stagelabel = load("res://Scenes/Menus/StageLabel.tscn")

var character_data = { # to be filled at _ready()
	"Random" : {
		"portrait" : ResourceLoader.load("res://Assets/UI/portrait_question.png"),
		"art" : ResourceLoader.load("res://Assets/UI/random.png"),
		"name" : "Random"
	}
#	"Gura" : {
#		"portrait" : ResourceLoader.load("res://Characters/Gura/UI/portrait.png"), 
#		"art" : ResourceLoader.load("res://Characters/Gura/UI/full_art.png"),
#		"select_sprite" : load("res://Characters/Gura/SelectSprite.tscn"),
#		"palettes" : { 
#			"2" : ResourceLoader.load("res://Characters/Gura/Palettes/2.png")
#		} 
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
var battle_lock := false

var my_phase := 0 # 0 is picking characters, 1 is picking stage, 2 is finishing picking and waiting for opponent, 3 is picking assist
var my_picker_pos := 0
var my_palette_picked := 1

onready var my_player_id = Netplay.my_player_id()
#onready var my_player_id = 1 # this is for testing only
var opponent: String # "P1" or "P2"

var last_picked # store it for setting later

var my_stage
var my_fullart
var my_name
var my_sprite
var my_picker
var my_stageselect
var my_assist
var my_buttoncheck
var my_waiting
var my_ready

var opponent_payload = {}
var my_payload = {
	"character" : null,
	"palette" : null,
	"stage" : null,
	"assist" : "",
}


func _ready():
	
	BGM.play_random_in_folder("Common/CharSelectThemes")
	
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	# set up my player nodes
	var player = "P" + str(my_player_id + 1)
	my_stage = get_node(player + "_Stage")
	my_fullart = get_node(player + "_FullArt")
	my_name = get_node(player + "_Name")
	my_sprite = get_node(player + "_Sprite")
	my_picker = get_node(player + "_Picker")
	my_stageselect = get_node(player + "_StageSelect")
	my_assist = get_node(player + "_Assist")
	my_buttoncheck = get_node(player + "_ButtonCheck")
	my_waiting = get_node(player + "_Waiting")
	my_ready = get_node(player + "_Ready")
	match player:
		"P1":
			opponent = "P2"
#			my_stage_half = "select_L"
		"P2":
			opponent = "P1"
#			my_stage_half = "select_R"
	get_node(opponent + "_Stage").hide()
	get_node(opponent + "_FullArt").hide()
	get_node(opponent + "_Name").hide()
#	get_node(opponent + "_InputStyle").hide()
	get_node(opponent + "_Sprite").hide()
	get_node(opponent + "_Picker").free()
	get_node(opponent + "_StageSelect").free()
	if Globals.assists == 1:
		get_node(opponent + "_Assist").hide()
	else:
		get_node(opponent + "_Assist").queue_free()
	get_node(opponent + "_ButtonCheck").free()
	get_node(opponent + "_Waiting").free()
	get_node(opponent + "_Ready").free()
	
	# load characters
	var dir = Directory.new()
	if dir.open("res://Characters/") == OK:
		dir.list_dir_begin(true)
		var character_name = dir.get_next()
		while character_name != "":
			if !character_name.begins_with("."):
				character_data[character_name] = {}
				character_data[character_name]["portrait"] = ResourceLoader.load("res://Characters/" + character_name + "/UI/portrait.png")
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
	my_stageselect.hide()
	
	changed_character()

	if Globals.assists == 1:
		if dir.change_dir("res://Assists/") == OK:
			dir.list_dir_begin(true)
			var assist_name = dir.get_next()
			while assist_name != "":
				if !assist_name.begins_with("."):
					assist_data[assist_name] = {}
					assist_data[assist_name]["name"] = load("res://Assists/" + assist_name + "/UniqNPC.tscn").instance().NAME
					assist_data[assist_name]["select"] = ResourceLoader.load("res://Assists/" + assist_name + "/select.png")
				assist_name = dir.get_next()
		else: print("Error: Cannot open Assists folder from CharacterSelect.gd")
		
		assist_array = assist_data.keys()
		populate_assist_lists()
		my_assist.get_node("AssistSelect").hide()
	else:
		my_assist.queue_free()

	
	# load last picked characters and stages
	last_picked = Settings.load_last_picked()
	if last_picked != null:
		load_last_picked()
	
	sound = true # only switch on sound after initial setup of characters
	
	load_buttoncheck()
	my_waiting.show()
	
	
func load_last_picked():
	if last_picked.P1_character != null:
		my_picker_pos = last_picked.P1_character
		changed_character()

	if last_picked.P1_palette != null:
		if my_picker_pos in char_grid and "palettes" in character_data[char_grid[my_picker_pos]]:
			my_palette_picked = wrapi(last_picked.P1_palette, 1, character_data[char_grid[my_picker_pos]]["palettes"].size() + 2) # wrap around pointer
			if my_palette_picked == 1:
				my_sprite.get_child(0).material = null
			else:
				my_sprite.get_child(0).material = ShaderMaterial.new()
				my_sprite.get_child(0).material.shader = Loader.loaded_palette_shader
				my_sprite.get_child(0).material.set_shader_param("swap", \
						character_data[char_grid[my_picker_pos]]["palettes"][str(my_palette_picked)])
						
		
	if last_picked.P1_stage != null:
		if last_picked.P1_stage in stage_array:
			while my_stageselect.get_node("StageList").get_child(3).stage_name != last_picked.P1_stage:
				shift_stage_list(1)
				
	if Globals.assists == 1:
		if last_picked.P1_assist != "":
			if last_picked.P1_assist in assist_array:
				while my_assist.get_node("AssistSelect/AssistList").get_child(3).stage_name != last_picked.P1_assist:
					shift_assist_list(1)
					
	Globals.P1_assist = last_picked.P1_assist # temp
			
	
func populate_char_grid():
	
	var total = $Grid.get_child_count()
	grid_dimensions[0] = $Grid.columns # 10
	grid_dimensions[1] = int(ceil(total/grid_dimensions[0])) # 3
	
	var center_indexes = [] # 5, 15, 25
	var left_indexes = [] # 0, 10, 20
	var right_indexes = [] # 9, 19, 29
	var center_point = int(ceil((grid_dimensions[0] + 1) / 2.0)) - 1 # 5
	
	for y in grid_dimensions[1]:
		center_indexes.append(center_point + (y * grid_dimensions[0]))
		left_indexes.append(y * grid_dimensions[0])
		right_indexes.append(left_indexes[y] + grid_dimensions[0] - 1)
		
	var index_array = []
	for level in center_indexes.size():
		var current_coord = center_indexes[level]
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
		$Grid.get_child(character_number).texture = character_data[char_grid[character_number]]["portrait"]
		$Grid.get_child(character_number).modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	my_picker_pos = center_point - (1 - posmod(grid_dimensions[0], 2))
	
	
func populate_stage_lists():
	var stage_array_pointer := 0
	
	# remove test children
	for x in my_stageselect.get_node("StageList").get_children():
		x.free()
	
	for x in STAGE_LIST_SIZE:
		# add new labels
		var new_stagelabel = loaded_stagelabel.instance()
		my_stageselect.get_node("StageList").add_child(new_stagelabel)
		var new_stagelabel2 = loaded_stagelabel.instance()
		my_stageselect.add_child(new_stagelabel2)
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
		shift_stage_list(1)
		
	
func populate_assist_lists():
	var assist_array_pointer := 0
	
	# remove test children
	for x in my_assist.get_node("AssistSelect/AssistList").get_children():
		x.free()
	
	for x in STAGE_LIST_SIZE:
		# add new labels
		var new_assistlabel = loaded_stagelabel.instance()
		my_assist.get_node("AssistSelect/AssistList").add_child(new_assistlabel)
		# change text
		new_assistlabel.stage_name = assist_array[assist_array_pointer]
		new_assistlabel.text = assist_data[assist_array[assist_array_pointer]].name
		# next assist, wrap around
		assist_array_pointer += 1
		assist_array_pointer = wrapi(assist_array_pointer, 0, assist_array.size())
	
	# shift lists so that get_child(3) points to the first stage
	for x in 3:
		shift_assist_list(1)
		
		
func load_buttoncheck():
	
	my_buttoncheck.hide()
	
	var input_map = Settings.load_input_map()
	var TAP_JUMP_OPTIONS = ["off", "on"]
	var INPUT_BUFFER_OPTIONS = ["none", "1 frame", "2 frames", "3 frames", "4 frames", "5 frames", "6 frames"
			, "7 frames", "8 frames", "9 frames", "10 frames"]
	var INPUT_ASSIST_OPTIONS = ["off", "on"]
	var DJ_FASTFALL_OPTIONS = ["off", "on"]
	
	var grid = my_buttoncheck.get_node("ButtonCheckGrid")

	grid.get_node("Up").load_button("Up", Settings.button_to_string(input_map["P1_up"]))
	grid.get_node("Down").load_button("Down", Settings.button_to_string(input_map["P1_down"]))
	grid.get_node("Left").load_button("Left", Settings.button_to_string(input_map["P1_left"]))
	grid.get_node("Right").load_button("Right", Settings.button_to_string(input_map["P1_right"]))
	grid.get_node("Jump").load_button("Jump", Settings.button_to_string(input_map["P1_jump"]))

	grid.get_node("Light").load_button("Light", Settings.button_to_string(input_map["P1_light"]))
	grid.get_node("Fierce").load_button("Fierce", Settings.button_to_string(input_map["P1_fierce"]))
	grid.get_node("Dash").load_button("Dash", Settings.button_to_string(input_map["P1_dash"]))
	grid.get_node("Aux").load_button("Aux", Settings.button_to_string(input_map["P1_aux"]))
	grid.get_node("Block").load_button("Block", Settings.button_to_string(input_map["P1_block"]))
	grid.get_node("Special").load_button("Special", Settings.button_to_string(input_map["P1_special"]))
	grid.get_node("Unique").load_button("Unique", Settings.button_to_string(input_map["P1_unique"]))

	grid.get_node("TapJump2").text = TAP_JUMP_OPTIONS[input_map["P1_tapjump"]]
	grid.get_node("DJFastfall2").text = DJ_FASTFALL_OPTIONS[input_map["P1_dj_fastfall"]]
	grid.get_node("InputBuffer2").text = INPUT_BUFFER_OPTIONS[input_map["P1_buffer"]]
	grid.get_node("InputAssist2").text = INPUT_ASSIST_OPTIONS[input_map["P1_input_assist"]]


func _physics_process(_delta):	
		
	if Input.is_action_pressed("P1_special"): # reveal/hide button check
		my_buttoncheck.show()
	else:
		my_buttoncheck.hide()
	
	# directional keys
	var dir = $P1DirInputs.P1_dir
	
	move_picker(dir)
	move_stage_picker(dir)
	
	if Globals.assists == 1:
		move_assist_picker(dir)

	# change palette, in phase 0 only
	var p_dir = 0
	if Input.is_action_just_pressed("P1_aux"):
		p_dir -= 1
	if Input.is_action_just_pressed("P1_block"):
		p_dir += 1
	
	change_palette(p_dir)
	
	if Input.is_action_just_pressed("P1_light"): # select character/stage
		match my_phase:
			0:
				picked_character()
			1:
				picked_stage()
			3:
				picked_assist()

		
	if Input.is_action_just_pressed("P1_fierce"): # unselect character/stage
		match my_phase:
			1:
				if Globals.assists == 1:
					unpicked_assist()
				else:
					unpicked_character()
			3:
				unpicked_character()
				
#		if my_phase == 2:
#			pass # cannot unselect stage in netplay
	
	
	if !battle_lock:
		if opponent_payload.size() > 0: # opponent is ready
			my_waiting.hide()
			my_ready.show()
		
		if my_phase == 2 and opponent_payload.size() > 0:
			# reveal characters/stages, then start after a while
			battle_lock = true
			if get_tree().is_network_server():
				determine_char_and_stage()
				yield(get_tree().create_timer(0.5), "timeout") # wait a short while before revealing
				start_battle()
			
	
func move_picker(dir):
	
	if my_phase == 0:
		if dir.x == 1:
			my_picker_pos += 1
			if my_picker_pos == $Grid.columns: my_picker_pos = 0
			elif my_picker_pos == $Grid.columns * 2: my_picker_pos = $Grid.columns
			elif my_picker_pos == $Grid.columns * 3: my_picker_pos = $Grid.columns * 2
			changed_character()
		elif dir.x == -1:
			my_picker_pos -= 1
			if my_picker_pos == -1: my_picker_pos = $Grid.columns - 1
			elif my_picker_pos == $Grid.columns - 1: my_picker_pos = ($Grid.columns * 2) - 1
			elif my_picker_pos == ($Grid.columns * 2) - 1: my_picker_pos = ($Grid.columns * 3) - 1
			changed_character()
		if dir.y == 1:
			my_picker_pos += $Grid.columns
			if my_picker_pos >= $Grid.columns * 3: my_picker_pos -= $Grid.columns * 3
			changed_character()
		elif dir.y == -1:
			my_picker_pos -= $Grid.columns
			if my_picker_pos < 0: my_picker_pos += $Grid.columns * 3
			changed_character()
	
func changed_character():
	if sound:
		play_audio("ui_move2", {"vol":-10})
	my_palette_picked = 1 # reset picked palette
	my_picker.rect_position = $Grid.get_child(my_picker_pos).rect_global_position # move picker
	if my_picker_pos in char_grid: # update art/select sprite/name
		var char_name: String = char_grid[my_picker_pos]
		my_fullart.texture = character_data[char_name]["art"]
		if my_sprite.get_child_count() > 0:
			my_sprite.get_child(0).free()
		if "select_sprite" in character_data[char_name]:
			var new_sprite = character_data[char_name]["select_sprite"].instance()
			my_sprite.add_child(new_sprite)
			my_sprite.position.y -= (new_sprite.get_node("Feet").position.y - 23)
		my_name.text = character_data[char_name]["name"]
	else: # blank panel
		my_fullart.texture = null
		if my_sprite.get_child_count() > 0:
			my_sprite.get_child(0).free()
		my_name.text = ""

func change_palette(p_dir):
	
	if my_phase == 0 and p_dir != 0 and my_picker_pos in char_grid and my_sprite.get_child_count() > 0: # last one is just in case
		my_palette_picked += p_dir # move pointer
		play_audio("ui_move2", {"vol":-10})
		var char_name: String = char_grid[my_picker_pos]
		my_palette_picked = wrapi(my_palette_picked, 1, character_data[char_name]["palettes"].size() + 2) # wrap around pointer
		if my_palette_picked == 1:
			my_sprite.get_child(0).material = null # cannot use $P1_Sprite/SelectSprite since the name will be different
		else:
			my_sprite.get_child(0).material = ShaderMaterial.new()
			my_sprite.get_child(0).material.shader = Loader.loaded_palette_shader
			my_sprite.get_child(0).material.set_shader_param("swap", character_data[char_name]["palettes"][str(my_palette_picked)])


func picked_character():
	if my_picker_pos in char_grid:
		play_audio("ui_accept2", {})
		my_picker.get_node("AnimationPlayer").play("RESET")
		my_fullart.get_node("AnimationPlayer").play("flash")
		yield(get_tree(),"idle_frame")
		if Globals.assists == 1:
			my_phase = 3
			my_assist.get_node("AssistSelect").show()
			my_assist.get_node("Label/AnimationPlayer").play("flashing")
		else:
			my_phase = 1
			my_stageselect.show()
		
func unpicked_character():
	play_audio("ui_back", {})
	my_picker.get_node("AnimationPlayer").play("flashing")
	yield(get_tree(),"idle_frame")
	if Globals.assists == 1:
		my_assist.get_node("AssistSelect").hide()
		my_assist.get_node("Label/AnimationPlayer").play("gray")
	else:
		my_stageselect.hide()
	my_phase = 0

	
func move_stage_picker(dir):
	if my_phase == 1 and dir.y != 0:
		shift_stage_list(dir.y)
		
		
func shift_stage_list(v_dir):

	var first_child = my_stageselect.get_node("StageList").get_child(0)
	var last_child = my_stageselect.get_node("StageList").get_child(STAGE_LIST_SIZE - 1)
	
	if v_dir == 1: # move down, shift list upward
		if sound:
			play_audio("ui_move2", {"vol":-10})
		first_child.free() # remove 1st child
		var index = stage_array.find(last_child.stage_name) # find index of last child in stage_array
		index = wrapi(index + 1, 0, stage_array.size()) # get index of next stage in stage_array, wraparound
		var new_stagelabel = loaded_stagelabel.instance() # add new child
		my_stageselect.get_node("StageList").add_child(new_stagelabel)
		new_stagelabel.stage_name = stage_array[index]
		new_stagelabel.text = stage_data[stage_array[index]].name
	elif v_dir == -1: # move up, shift list downward
		if sound:
			play_audio("ui_move2", {"vol":-10})
		last_child.free() # remove last child
		var index = stage_array.find(first_child.stage_name) # find index of first child in stage_array
		index = wrapi(index - 1, 0, stage_array.size()) # get index of previous stage in stage_array, wraparound
		var new_stagelabel = loaded_stagelabel.instance() # add new child
		my_stageselect.get_node("StageList").add_child(new_stagelabel)
		my_stageselect.get_node("StageList").move_child(new_stagelabel, 0) # make child the new first child
		new_stagelabel.stage_name = stage_array[index]
		new_stagelabel.text = stage_data[stage_array[index]].name
		
	my_stage.texture = stage_data[my_stageselect.get_node("StageList").get_child(3).stage_name].select # update stage texture
	for x in my_stageselect.get_node("StageList").get_children(): # return color to normal
		x.modulate = Color(1.0, 1.0, 1.0)
	my_stageselect.get_node("StageList").get_child(3).modulate = Color(1.5, 1.5, 1.5) # brighten stage pointed at

	
func picked_stage():
	play_audio("ui_accept2", {})
	my_stage.get_node("AnimationPlayer").play("flash")
	yield(get_tree(),"idle_frame")
	my_phase = 2
	my_stageselect.hide()
	
	# cannot unpick stage in netplay, send payload here
	my_payload.character = char_grid[my_picker_pos]
	my_payload.palette = my_palette_picked
	my_payload.stage = my_stageselect.get_node("StageList").get_child(3).stage_name
	if Globals.assists == 1:
		my_payload.assist = my_assist.get_node("AssistSelect/AssistList").get_child(3).stage_name
	else:
		my_payload.assist = Globals.P1_assist # temp
		
	rpc("opponent_ready", my_payload)
	save_last_picked()
	
# ------------------------------------------------------------------------------------------------------------------------
		
func move_assist_picker(dir):
	if my_phase == 3 and dir.y != 0:
		shift_assist_list(dir.y)

func picked_assist():
	play_audio("ui_accept2", {})
	my_assist.get_node("Back/Sprite/AnimationPlayer").play("flash")
	yield(get_tree(),"idle_frame")
	my_phase = 1
	my_stageselect.show()
	my_assist.get_node("Label/AnimationPlayer").play("white")
	my_assist.get_node("AssistSelect").hide()
	
func unpicked_assist():
	play_audio("ui_back", {})
	yield(get_tree(),"idle_frame")
	my_phase = 3
	my_stageselect.hide()
	my_assist.get_node("Label/AnimationPlayer").play("flashing")
	my_assist.get_node("AssistSelect").show()


func shift_assist_list(v_dir):
	var first_child = my_assist.get_node("AssistSelect/AssistList").get_child(0)
	var last_child = my_assist.get_node("AssistSelect/AssistList").get_child(STAGE_LIST_SIZE - 1)
	
	if v_dir == 1: # move down, shift list upward
		if sound:
			play_audio("ui_move2", {"vol":-10})
		first_child.free() # remove 1st child
		var index = assist_array.find(last_child.stage_name) # find index of last child in assist_array
		index = wrapi(index + 1, 0, assist_array.size()) # get index of next assist in assist_array, wraparound
		var new_assistlabel = loaded_stagelabel.instance() # add new child
		my_assist.get_node("AssistSelect/AssistList").add_child(new_assistlabel)
		new_assistlabel.stage_name = assist_array[index]
		new_assistlabel.text = assist_data[assist_array[index]].name
	elif v_dir == -1: # move up, shift list downward
		if sound:
			play_audio("ui_move2", {"vol":-10})
		last_child.free() # remove last child
		var index = assist_array.find(first_child.stage_name) # find index of first child in assist_array
		index = wrapi(index - 1, 0, assist_array.size()) # get index of previous assist in assist_array, wraparound
		var new_assistlabel = loaded_stagelabel.instance() # add new child
		my_assist.get_node("AssistSelect/AssistList").add_child(new_assistlabel)
		my_assist.get_node("AssistSelect/AssistList").move_child(new_assistlabel, 0) # make child the new first child
		new_assistlabel.stage_name = assist_array[index]
		new_assistlabel.text = assist_data[assist_array[index]].name
		
	# update assist texture
	my_assist.get_node("Back/Sprite").texture = assist_data[my_assist.get_node("AssistSelect/AssistList").get_child(3).stage_name].select
	for x in my_assist.get_node("AssistSelect/AssistList").get_children(): # return color to normal
		x.modulate = Color(1.0, 1.0, 1.0)
	my_assist.get_node("AssistSelect/AssistList").get_child(3).modulate = Color(1.5, 1.5, 1.5) # brighten assist pointed at

# ------------------------------------------------------------------------------------------------------------------------
	
	
func save_last_picked():
	# save your last picked
	var new_last_picked
	if last_picked == null:
		new_last_picked = {
			"P1_character" : my_picker_pos, # character is saved as their position!
			"P1_palette" : my_payload.palette,
			"P1_stage" : my_payload.stage,
			"P1_assist" : my_payload.assist,
			"P2_character" : null,
			"P2_palette" : null,
			"P2_stage" : null,
			"P2_assist" : "",
		}
	else:
		new_last_picked = {
			"P1_character" : my_picker_pos,
			"P1_palette" : my_payload.palette,
			"P1_stage" : my_payload.stage,
			"P1_assist" : my_payload.assist,
			"P2_character" : last_picked.P2_character,
			"P2_palette" : last_picked.P2_palette,
			"P2_stage" : last_picked.P2_stage,
			"P2_assist" : last_picked.P2_assist,
		}
	Settings.save_last_picked(new_last_picked)
	
	
remote func opponent_ready(in_opponent_payload):
	opponent_payload = in_opponent_payload
	
	
func determine_char_and_stage():
	# processing picks
	# 50% chance of either stage picked
	if Globals.random.randi_range(0, 1) == 0:
		Globals.stage_ref = my_payload.stage
	else:
		Globals.stage_ref = opponent_payload.stage
		
	if opponent == "P2":
		Globals.P1_char_ref = my_payload.character
		Globals.P1_palette = my_payload.palette
		Globals.P1_assist = my_payload.assist
		Globals.P2_char_ref = opponent_payload.character
		Globals.P2_palette = opponent_payload.palette
		Globals.P2_assist = opponent_payload.assist
	else:
		Globals.P1_char_ref = opponent_payload.character
		Globals.P1_palette = opponent_payload.palette
		Globals.P1_assist = opponent_payload.assist
		Globals.P2_char_ref = my_payload.character
		Globals.P2_palette = my_payload.palette
		Globals.P2_assist = my_payload.assist
		
	# if both players picked the same character with the same palette, a random player will shift a palette
	if Globals.P1_char_ref != "Random" and Globals.P1_char_ref == Globals.P2_char_ref and Globals.P1_palette == Globals.P2_palette:
		if Globals.random.randi_range(0, 1) == 0:
			Globals.P1_palette = wrapi(Globals.P1_palette + 1, 1, character_data[Globals.P1_char_ref]["palettes"].size() + 2)
		else:
			Globals.P2_palette = wrapi(Globals.P2_palette + 1, 1, character_data[Globals.P2_char_ref]["palettes"].size() + 2)

	# handling random
	if Globals.P1_char_ref == "Random":
		var character_array = char_grid.values()
		character_array.erase("Random")
		character_array.shuffle()
		Globals.P1_char_ref = character_array[0]
		# random palette
		Globals.P1_palette = Globals.random.randi_range(1, character_data[Globals.P1_char_ref]["palettes"].size() + 1)
		# if same character and palette, shift to next palette
		if Globals.P1_char_ref == Globals.P2_char_ref and Globals.P1_palette == Globals.P2_palette:
			Globals.P1_palette = wrapi(Globals.P1_palette + 1, 1, character_data[Globals.P1_char_ref]["palettes"].size() + 2)
	if Globals.P2_char_ref == "Random":
		var character_array = char_grid.values()
		character_array.erase("Random")
		character_array.shuffle()
		Globals.P2_char_ref = character_array[0]
		# random palette
		Globals.P2_palette = Globals.random.randi_range(1, character_data[Globals.P2_char_ref]["palettes"].size() + 1)
		# if same character and palette, shift to next palette
		if Globals.P1_char_ref == Globals.P2_char_ref and Globals.P1_palette == Globals.P2_palette:
			Globals.P2_palette = wrapi(Globals.P2_palette + 1, 1, character_data[Globals.P2_char_ref]["palettes"].size() + 2)
#
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
		
#	rpc("guest_receive_picks", Globals.stage_ref, Globals.P1_char_ref, Globals.P1_palette, Globals.P1_input_style, \
#			Globals.P2_char_ref, Globals.P2_palette, Globals.P2_input_style)
	rpc("guest_receive_picks", Globals.stage_ref, Globals.P1_char_ref, Globals.P1_palette, Globals.P1_assist, \
			Globals.P2_char_ref, Globals.P2_palette, Globals.P2_assist)

		
puppet func guest_receive_picks(stage_ref, P1_char_ref, P1_palette, P1_assist, P2_char_ref, P2_palette, P2_assist):
	Globals.stage_ref = stage_ref
	Globals.P1_char_ref = P1_char_ref
	Globals.P1_palette = P1_palette
	Globals.P1_assist = P1_assist
	Globals.P2_char_ref = P2_char_ref
	Globals.P2_palette = P2_palette
	Globals.P2_assist = P2_assist
	
	yield(get_tree().create_timer(0.5 - Netplay.ping/2.0), "timeout") # wait a short while before revealing
	start_battle()
	
	
func start_battle():
	
#	my_payload.character
#	my_payload.palette
#	my_payload.stage
#	my_payload.assist
#
#	opponent_payload.character
#	opponent_payload.palette
#	opponent_payload.stage
#	opponent_payload.assist

	my_ready.hide()

	# 1st, reveal opponent's picks
	play_audio("ui_accept2", {})
	my_ready.hide()
	get_node(opponent + "_Stage").show()
	get_node(opponent + "_Stage/AnimationPlayer").play("flash")
	get_node(opponent + "_FullArt").show()
	get_node(opponent + "_FullArt/AnimationPlayer").play("flash")
	get_node(opponent + "_Name").show()
	get_node(opponent + "_Sprite").show()
	if Globals.assists == 1:
		get_node(opponent + "_Assist").show()
		get_node(opponent + "_Assist/AssistSelect").free()
		get_node(opponent + "_Assist/Label/AnimationPlayer").play("white")
		get_node(opponent + "_Assist/Back/Sprite/AnimationPlayer").play("flash")

	if opponent_payload.character != "Random":
		var char_name
		if opponent == "P1":
			char_name = Globals.P1_char_ref
		else:
			char_name = Globals.P2_char_ref
		get_node(opponent + "_FullArt").texture = character_data[char_name]["art"]
		if get_node(opponent + "_Sprite").get_child_count() > 0:
			get_node(opponent + "_Sprite").get_child(0).free()
		if "select_sprite" in character_data[char_name]:
			var new_sprite = character_data[char_name]["select_sprite"].instance()
			get_node(opponent + "_Sprite").add_child(new_sprite)
		get_node(opponent + "_Name").text = character_data[char_name]["name"]
	else: # opponent pick random character, hide their data
		get_node(opponent + "_FullArt").texture = character_data["Random"]["art"]
		if get_node(opponent + "_Sprite").get_child_count() > 0:
			get_node(opponent + "_Sprite").get_child(0).free()
		get_node(opponent + "_Name").text = "Random"
		
		
	# re-set palettes
	if $P1_Sprite.get_child_count() > 0:
		if Globals.P1_palette == 1:
			$P1_Sprite.get_child(0).material = null
		else:
			$P1_Sprite.get_child(0).material = ShaderMaterial.new()
			$P1_Sprite.get_child(0).material.shader = Loader.loaded_palette_shader
			$P1_Sprite.get_child(0).material.set_shader_param("swap", character_data[Globals.P1_char_ref]["palettes"][str(Globals.P1_palette)])

	if $P2_Sprite.get_child_count() > 0:
		if Globals.P2_palette == 1:
			$P2_Sprite.get_child(0).material = null
		else:
			$P2_Sprite.get_child(0).material = ShaderMaterial.new()
			$P2_Sprite.get_child(0).material.shader = Loader.loaded_palette_shader
			$P2_Sprite.get_child(0).material.set_shader_param("swap", character_data[Globals.P2_char_ref]["palettes"][str(Globals.P2_palette)])

	
#	if opponent == "P1":
	get_node(opponent + "_Stage").texture = stage_data[opponent_payload.stage]["select"] # update stage texture
#	else:
#		get_node(opponent + "_Stage").texture = stage_data[opponent_payload.stage]["select_R"]

	if Globals.assists == 1:
		if opponent_payload.assist != "Random":
			var assist_name
			if opponent == "P1":
				assist_name = Globals.P1_assist
			else:
				assist_name = Globals.P2_assist
			get_node(opponent + "_Assist/Back/Sprite").texture = assist_data[assist_name]["select"]
		else: # opponent pick random assist, hide their data
			get_node(opponent + "_Assist/Back/Sprite").texture = assist_data["Random"]["select"]

	BGM.fade()
	$Transition.play("transit_to_battle")

	
# ------------------------------------------------------------------------------------------------------------------------

func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	
func change_scene(new_scene: String): # called by animation
	Globals.next_scene = new_scene
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/LoadingScreen.tscn")
	
func _player_disconnected(_id): # opponent disconnected
	play_audio("ui_deny", {"vol" : -9})
	Netplay.connection_issue(2, self, "_player_disconnected2")
	
func _server_disconnected():
	play_audio("ui_deny", {"vol" : -9})
	Netplay.connection_issue(2, self, "_player_disconnected2")
	
func _player_disconnected2(): # opponent disconnected
	play_audio("ui_back", {})
	$Transition.play("transit_to_netplay")
	Netplay.stop_hosting_or_searching()
