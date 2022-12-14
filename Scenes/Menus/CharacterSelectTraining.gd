extends Node2D

const CHAR_GRID = {
	5 : "Gura",
	6 : "Random"
}

const STAGE_LIST_SIZE = 7
onready var loaded_stagelabel = load("res://Scenes/Menus/StageLabel.tscn")

var character_data = { # to be filled at _ready()
	"Random" : {
		"portrait" : ResourceLoader.load("res://Assets/UI/portrait_question.png"),
		"art" : ResourceLoader.load("res://Assets/UI/random.png"),
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
		"select_L" : ResourceLoader.load("res://Assets/UI/random_select_L.png"), 
		"select_R" : ResourceLoader.load("res://Assets/UI/random_select_R.png"), 
	}
#	"Aurora" : {
#		"select_L" : ResourceLoader.load("res://Stages/Aurora/Resources/select_L.png"), 
#		"select_R" : ResourceLoader.load("res://Stages/Aurora/Resources/select_R.png"), 
#	}
}
var stage_array

var sound := false
var battle_lock := false # set to true after starting battle, prevent certain actions like cancelling during the fade to black

var phase := 0 # 0 is picking characters, 1 is dummy picking character, 2 is picking stage
var P1_picker_pos := 5
var P1_palette_picked := 1
#var P1_input_style := 0

var P2_picker_pos := 5
var P2_palette_picked := 1
#var P2_input_style := 0

func _ready():
	Globals.pausing = false
	
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
				stage_data[stage_name]["select_L"] = ResourceLoader.load("res://Stages/" + stage_name + "/Resources/select_L.png")
				stage_data[stage_name]["select_R"] = ResourceLoader.load("res://Stages/" + stage_name + "/Resources/select_R.png")
			stage_name = dir.get_next()
	else: print("Error: Cannot open Stages folder from CharacterSelect.gd")
	
	stage_array = stage_data.keys()
	populate_stage_lists()
	$P1_StageSelect.hide()
	
	P1_changed_character()
	P2_changed_character()
	$P2_Picker.hide()
	
#	change_input_style($P1_InputStyle, 0)
#	change_input_style($P2_InputStyle, 0)
	
	# load last picked characters and stages
	var last_picked = Settings.load_last_picked()
#	var last_picked = {
#		"P1_character" : P1_picker_pos,
#		"P1_palette" : P1_palette_picked,
#		"P1_stage" : $P1_StageSelect/StageList.get_child(3).text,
#		"P2_character" : P2_picker_pos,
#		"P2_palette" : P2_palette_picked,
#		"P2_stage" : $P2_StageSelect/StageList.get_child(3).text,
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
		if P1_picker_pos in CHAR_GRID and "palettes" in character_data[CHAR_GRID[P1_picker_pos]]:
			P1_palette_picked = wrapi(last_picked.P1_palette, 1, character_data[CHAR_GRID[P1_picker_pos]]["palettes"].size() + 2) # wrap around pointer
			if P1_palette_picked == 1:
				$P1_Sprite.get_child(0).material = null # cannot use $P1_Sprite/SelectSprite since the name will be different
			else:
				$P1_Sprite.get_child(0).material = ShaderMaterial.new()
				$P1_Sprite.get_child(0).material.shader = Globals.loaded_palette_shader
				$P1_Sprite.get_child(0).material.set_shader_param("swap", \
						character_data[CHAR_GRID[P1_picker_pos]]["palettes"][str(P1_palette_picked)])
		
	if last_picked.P2_palette != null:
		if P2_picker_pos in CHAR_GRID and "palettes" in  character_data[CHAR_GRID[P2_picker_pos]]:
			P2_palette_picked = wrapi(last_picked.P2_palette, 1, character_data[CHAR_GRID[P2_picker_pos]]["palettes"].size() + 2) # wrap around pointer
			if P2_palette_picked == 1:
				$P2_Sprite.get_child(0).material = null
			else:
				$P2_Sprite.get_child(0).material = ShaderMaterial.new()
				$P2_Sprite.get_child(0).material.shader = Globals.loaded_palette_shader
				$P2_Sprite.get_child(0).material.set_shader_param("swap", \
						character_data[CHAR_GRID[P2_picker_pos]]["palettes"][str(P2_palette_picked)])

	if last_picked.P1_stage != null:
		if last_picked.P1_stage in stage_array:
			while $P1_StageSelect/StageList.get_child(3).text != last_picked.P1_stage:
				shift_stage_list(1)
			
	
func populate_char_grid():
	for character_number in CHAR_GRID.keys():
		$Grid.get_child(character_number).texture = character_data[CHAR_GRID[character_number]]["portrait"]
		$Grid.get_child(character_number).modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	
func populate_stage_lists():
	var stage_array_pointer := 0
	
	# remove test children
	for x in $P1_StageSelect/StageList.get_children():
		x.free()
	
	for x in STAGE_LIST_SIZE:
		# add new labels
		var new_stagelabel = loaded_stagelabel.instance()
		$P1_StageSelect/StageList.add_child(new_stagelabel)
		# change text
		new_stagelabel.text = stage_array[stage_array_pointer]
		# next stage, wrap around
		stage_array_pointer += 1
		stage_array_pointer = wrapi(stage_array_pointer, 0, stage_array.size())
	
	# shift lists so that get_child(3) points to the first stage
	for x in 3:
		shift_stage_list(1)
		
		
func load_buttoncheck():
	
	$P1_ButtonCheck.hide()
	
	var input_map = Settings.load_input_map()
	var TAP_JUMP_OPTIONS = ["off", "on"]
	var INPUT_BUFFER_OPTIONS = ["none", "1 frame", "2 frames", "3 frames", "4 frames", "5 frames", "6 frames"
			, "7 frames", "8 frames", "9 frames", "10 frames"]
	var DJ_FASTFALL_OPTIONS = ["off", "on"]
	
	for player_ID in [0]:
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
		grid.get_node("Special").load_button("Special", Settings.button_to_string(input_map["P" + player_index + "_special"]))
		grid.get_node("Unique").load_button("Unique", Settings.button_to_string(input_map["P" + player_index + "_unique"]))

		grid.get_node("TapJump2").text = TAP_JUMP_OPTIONS[input_map["P" + player_index + "_tapjump"]]
		grid.get_node("DJFastfall2").text = DJ_FASTFALL_OPTIONS[input_map["P" + player_index + "_dj_fastfall"]]
		grid.get_node("InputBuffer2").text = INPUT_BUFFER_OPTIONS[input_map["P" + player_index + "_buffer"]]


func _physics_process(_delta):
	
	if phase == 0:
		if Input.is_action_just_pressed("P1_fierce"):
			play_audio("ui_back", {})
			$Transition.play("transit_to_training")
		
	if Input.is_action_pressed("P1_special"): # reveal/hide button check
		$P1_ButtonCheck.show()
	else:
		$P1_ButtonCheck.hide()
		
	# directional keys
	var dir = $P1DirInputs.P1_dir
	
	move_pickers(dir)
	move_stage_picker(dir)

	# change palette, in phase 0 only
	var p_dir = 0
	if Input.is_action_just_pressed("P1_aux"):
		p_dir -= 1
	if Input.is_action_just_pressed("P1_block"):
		p_dir += 1
	
	change_palette(p_dir)
		
	if Input.is_action_just_pressed("P1_light"): # select character/stage
		if phase == 0:
			P1_picked_character()
		if phase == 1:
			P2_picked_character()
		if phase == 2 and !battle_lock:
			picked_stage()
		
	if Input.is_action_just_pressed("P1_fierce"): # unselect character/stage
		if phase == 1:
			P1_unpicked_character()
		if phase == 2 and !battle_lock:
			P2_unpicked_character()
			
#	if P1_phase == 2 and P2_phase == 2: # both players have picked characters and stages
#		start_battle()
	
	
func move_pickers(dir):
	
	if phase == 0:
		if dir.x == 1:
			P1_picker_pos += 1
			if P1_picker_pos == 12: P1_picker_pos = 0
			elif P1_picker_pos == 24: P1_picker_pos = 12
			elif P1_picker_pos == 36: P1_picker_pos = 24
			P1_changed_character()
		elif dir.x == -1:
			P1_picker_pos -= 1
			if P1_picker_pos == -1: P1_picker_pos = 11
			elif P1_picker_pos == 11: P1_picker_pos = 23
			elif P1_picker_pos == 23: P1_picker_pos = 35
			P1_changed_character()
		if dir.y == 1:
			P1_picker_pos += 12
			if P1_picker_pos >= 36: P1_picker_pos -= 36
			P1_changed_character()
		elif dir.y == -1:
			P1_picker_pos -= 12
			if P1_picker_pos < 0: P1_picker_pos += 36
			P1_changed_character()
		
	if phase == 1:
		if dir.x == 1:
			P2_picker_pos += 1
			if P2_picker_pos == 12: P2_picker_pos = 0
			elif P2_picker_pos == 24: P2_picker_pos = 12
			elif P2_picker_pos == 36: P2_picker_pos = 24
			P2_changed_character()
		elif dir.x == -1:
			P2_picker_pos -= 1
			if P2_picker_pos == -1: P2_picker_pos = 11
			elif P2_picker_pos == 11: P2_picker_pos = 23
			elif P2_picker_pos == 23: P2_picker_pos = 35
			P2_changed_character()
		if dir.y == 1:
			P2_picker_pos += 12
			if P2_picker_pos >= 36: P2_picker_pos -= 36
			P2_changed_character()
		elif dir.y == -1:
			P2_picker_pos -= 12
			if P2_picker_pos < 0: P2_picker_pos += 36
			P2_changed_character()		
	
func P1_changed_character():
	if sound:
		play_audio("ui_move2", {"vol":-12})
	P1_palette_picked = 1 # reset picked palette
	$P1_Picker.rect_position = $Grid.get_child(P1_picker_pos).rect_global_position # move picker
	if P1_picker_pos in CHAR_GRID: # update art/select sprite/name
		var char_name: String = CHAR_GRID[P1_picker_pos]
		$P1_FullArt.texture = character_data[char_name]["art"]
		if $P1_Sprite.get_child_count() > 0:
			$P1_Sprite.get_child(0).free()
		if "select_sprite" in character_data[char_name]:
			var new_sprite = character_data[char_name]["select_sprite"].instance()
			$P1_Sprite.add_child(new_sprite)
		$P1_Name.text = char_name
	else: # blank panel
		$P1_FullArt.texture = null
		if $P1_Sprite.get_child_count() > 0:
			$P1_Sprite.get_child(0).free()
		$P1_Name.text = ""
	
func P2_changed_character():
	if sound:
		play_audio("ui_move2", {"vol":-12})
	P2_palette_picked = 1 # reset picked palette
	$P2_Picker.rect_position = $Grid.get_child(P2_picker_pos).rect_global_position # move picker
	if P2_picker_pos in CHAR_GRID:
		var char_name: String = CHAR_GRID[P2_picker_pos]
		$P2_FullArt.texture = character_data[char_name]["art"]
		if $P2_Sprite.get_child_count() > 0:
			$P2_Sprite.get_child(0).free()
		if "select_sprite" in character_data[char_name]:
			var new_sprite = character_data[char_name]["select_sprite"].instance()
			$P2_Sprite.add_child(new_sprite)
		$P2_Name.text = char_name
	else:
		$P2_FullArt.texture = null
		if $P2_Sprite.get_child_count() > 0:
			$P2_Sprite.get_child(0).free()
		$P2_Name.text = ""
	

func change_palette(p_dir):
	
	if phase == 0 and p_dir != 0 and P1_picker_pos in CHAR_GRID and $P1_Sprite.get_child_count() > 0: # last one is just in case
		P1_palette_picked += p_dir # move pointer
		play_audio("ui_move2", {"vol":-12})
		var char_name: String = CHAR_GRID[P1_picker_pos]
		P1_palette_picked = wrapi(P1_palette_picked, 1, character_data[char_name]["palettes"].size() + 2) # wrap around pointer
		if P1_palette_picked == 1:
			$P1_Sprite.get_child(0).material = null # cannot use $P1_Sprite/SelectSprite since the name will be different
		else:
			$P1_Sprite.get_child(0).material = ShaderMaterial.new()
			$P1_Sprite.get_child(0).material.shader = Globals.loaded_palette_shader
			$P1_Sprite.get_child(0).material.set_shader_param("swap", character_data[char_name]["palettes"][str(P1_palette_picked)])
			
	if phase == 1 and p_dir != 0 and P2_picker_pos in CHAR_GRID and $P2_Sprite.get_child_count() > 0: # last one is just in case
		P2_palette_picked += p_dir # move pointer
		play_audio("ui_move2", {"vol":-12})
		var char_name: String = CHAR_GRID[P2_picker_pos]
		P2_palette_picked = wrapi(P2_palette_picked, 1, character_data[char_name]["palettes"].size() + 2) # wrap around pointer
		
		if P2_palette_picked == 1:
			$P2_Sprite.get_child(0).material = null
		else:
			$P2_Sprite.get_child(0).material = ShaderMaterial.new()
			$P2_Sprite.get_child(0).material.shader = Globals.loaded_palette_shader
			$P2_Sprite.get_child(0).material.set_shader_param("swap", character_data[char_name]["palettes"][str(P2_palette_picked)])


func P1_picked_character():
	if P1_picker_pos in CHAR_GRID:
		play_audio("ui_accept2", {"vol":-5})
		$P1_Picker/AnimationPlayer.play("RESET")
		$P1_FullArt/AnimationPlayer.play("flash")
		yield(get_tree(),"idle_frame")
		phase = 1
		$P2_Picker.show()
	
func P2_picked_character():
	if P2_picker_pos in CHAR_GRID:
		play_audio("ui_accept2", {"vol":-5})
		$P2_Picker/AnimationPlayer.play("RESET")
		$P2_FullArt/AnimationPlayer.play("flash")
		yield(get_tree(),"idle_frame")
		phase = 2
		$P1_StageSelect.show()
		
		# if same character and palette, change palette automatically
		if CHAR_GRID[P2_picker_pos] != "Random":
			if CHAR_GRID[P1_picker_pos] == CHAR_GRID[P2_picker_pos] and P1_palette_picked == P2_palette_picked:
				var char_name: String = CHAR_GRID[P1_picker_pos]
				P2_palette_picked = wrapi(P2_palette_picked + 1, 1, character_data[char_name]["palettes"].size() + 2) # wrap around pointer
				if P2_palette_picked == 1:
					$P2_Sprite.get_child(0).material = null # cannot use $P1_Sprite/SelectSprite since the name will be different
				else:
					$P2_Sprite.get_child(0).material = ShaderMaterial.new()
					$P2_Sprite.get_child(0).material.shader = Globals.loaded_palette_shader
					$P2_Sprite.get_child(0).material.set_shader_param("swap", character_data[char_name]["palettes"][str(P2_palette_picked)])
		
func P1_unpicked_character():
	play_audio("ui_back", {})
	$P1_Picker/AnimationPlayer.play("flashing")
	yield(get_tree(),"idle_frame")
	phase = 0
	$P2_Picker.hide()
	
func P2_unpicked_character():
	play_audio("ui_back", {})
	$P2_Picker/AnimationPlayer.play("flashing")
	yield(get_tree(),"idle_frame")
	phase = 1
	$P1_StageSelect.hide()
	
	
func move_stage_picker(dir):
	if phase == 2 and dir.y != 0:
		shift_stage_list(dir.y)

	
func shift_stage_list(v_dir):
	var first_child = $P1_StageSelect/StageList.get_child(0)
	var last_child = $P1_StageSelect/StageList.get_child(STAGE_LIST_SIZE - 1)
	
	if v_dir == 1: # move down, shift list upward
		if sound:
			play_audio("ui_move2", {"vol":-12})
		first_child.free() # remove 1st child
		var index = stage_array.find(last_child.text) # find index of last child in stage_array
		index = wrapi(index + 1, 0, stage_array.size()) # get index of next stage in stage_array, wraparound
		var new_stagelabel = loaded_stagelabel.instance() # add new child
		$P1_StageSelect/StageList.add_child(new_stagelabel)
		new_stagelabel.text = stage_array[index]
	elif v_dir == -1: # move up, shift list downward
		if sound:
			play_audio("ui_move2", {"vol":-12})
		last_child.free() # remove last child
		var index = stage_array.find(first_child.text) # find index of first child in stage_array
		index = wrapi(index - 1, 0, stage_array.size()) # get index of previous stage in stage_array, wraparound
		var new_stagelabel = loaded_stagelabel.instance() # add new child
		$P1_StageSelect/StageList.add_child(new_stagelabel)
		$P1_StageSelect/StageList.move_child(new_stagelabel, 0) # make child the new first child
		new_stagelabel.text = stage_array[index]
		
	$P1_Stage.texture = stage_data[$P1_StageSelect/StageList.get_child(3).text].select_L # update stage texture
	$P2_Stage.texture = stage_data[$P1_StageSelect/StageList.get_child(3).text].select_R # update stage texture
	for x in $P1_StageSelect/StageList.get_children(): # return color to normal
		x.modulate = Color(1.0, 1.0, 1.0)
	$P1_StageSelect/StageList.get_child(3).modulate = Color(1.5, 1.5, 1.5) # brighten stage pointed at

func picked_stage():
	play_audio("ui_accept2", {"vol":-5})
	$P1_Stage/AnimationPlayer.play("flash")
	$P2_Stage/AnimationPlayer.play("flash")
	$P1_StageSelect.hide()
	battle_lock = true
	yield(get_tree().create_timer(0.5), "timeout") # wait a short while before starting
	start_battle()


# ------------------------------------------------------------------------------------------------------------------------

func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	
func start_battle():

	Globals.stage_ref = $P1_StageSelect/StageList.get_child(3).text

	Globals.P1_char_ref = CHAR_GRID[P1_picker_pos]
	Globals.P1_palette = P1_palette_picked
	Globals.P2_char_ref = CHAR_GRID[P2_picker_pos]
	Globals.P2_palette = P2_palette_picked
	
	# saving last picked characters and stages
	var last_picked = {
		"P1_character" : P1_picker_pos,
		"P1_palette" : P1_palette_picked,
		"P1_stage" : $P1_StageSelect/StageList.get_child(3).text,
		"P2_character" : P2_picker_pos,
		"P2_palette" : P2_palette_picked,
		"P2_stage" : $P1_StageSelect/StageList.get_child(3).text,
	}
	Settings.save_last_picked(last_picked)
	
	# handling random
	if Globals.P1_char_ref == "Random":
		var character_array = CHAR_GRID.values()
		character_array.erase("Random")
		character_array.shuffle()
		Globals.P1_char_ref = character_array[0]
		# random palette
		Globals.P1_palette = Globals.random.randi_range(1, character_data[Globals.P1_char_ref]["palettes"].size() + 1)
		# if same character and palette, shift to next palette
		if Globals.P1_char_ref == Globals.P2_char_ref and Globals.P1_palette == Globals.P2_palette:
			Globals.P1_palette = wrapi(Globals.P1_palette + 1, 1, character_data[Globals.P1_char_ref]["palettes"].size() + 2)
	if Globals.P2_char_ref == "Random":
		var character_array = CHAR_GRID.values()
		character_array.erase("Random")
		character_array.shuffle()
		Globals.P2_char_ref = character_array[0]
		# random palette
		Globals.P2_palette = Globals.random.randi_range(1, character_data[Globals.P2_char_ref]["palettes"].size() + 1)
		# if same character and palette, shift to next palette
		if Globals.P1_char_ref == Globals.P2_char_ref and Globals.P1_palette == Globals.P2_palette:
			Globals.P2_palette = wrapi(Globals.P2_palette + 1, 1, character_data[Globals.P2_char_ref]["palettes"].size() + 2)
		
	if Globals.stage_ref == "Random":
		var new_stage_array = stage_data.keys()
		new_stage_array.erase("Random")
		new_stage_array.shuffle()
		Globals.stage_ref = new_stage_array[0]
	
	Globals.time_limit = 0
	Globals.training_mode = true
	$Transition.play("transit_to_battle")
	
	
func change_scene(new_scene: String): # called by animation
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)
