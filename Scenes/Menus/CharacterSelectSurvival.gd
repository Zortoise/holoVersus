extends Node2D

var char_grid = {
#	5 : "Gura",
#	6 : "Random"
}
var grid_dimensions = [0, 0]

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

var stage_select

var stage_data = { # to be filled at _ready()
	"Random" : {
		"name" : "Random",
		"select" : ResourceLoader.load("res://Assets/UI/random_select.png"), 
	}
#	"Aurora" : {
#		"select" : ResourceLoader.load("res://Stages/Aurora/Resources/select.png"), 
#	}
}
var stage_array

var sound := false
var battle_lock := false # set to true after starting battle, prevent certain actions like cancelling during the fade to black

var P1_phase := 0 # 0 is picking characters, 1 is finishing picking and waiting for opponent
var P1_picker_pos := 5
var P1_palette_picked := 1
#var P1_input_style := 0

var P2_phase := 0
var P2_picker_pos := 5
var P2_palette_picked := 1
#var P2_input_style := 0

func _ready():
	Globals.pausing = false
	
	BGM.bgm(BGM.common_music["char_select"])
	
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
				character_data[character_name]["name"] = load("res://Characters/" + character_name + "/" + character_name + ".tscn").instance().NAME
				
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
	
	var level = load("res://Levels/" + Globals.survival_level + ".tscn").instance()
	stage_select = ResourceLoader.load("res://Stages/" + level.STAGE + "/Resources/select.png")
	$P1_Stage.texture = stage_select
	$P2_Stage.texture = stage_select
	
	if Globals.player_count == 1:
		$P2_FullArt.hide()
		$P2_Name.hide()
		$P2_Sprite.hide()
		$P2_Picker.hide()
		$Background/TriangleR.hide()
	
	P1_changed_character()
	if Globals.player_count > 0:
		P2_changed_character()
	
	
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
	if Globals.player_count > 0:
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
		
	if Globals.player_count > 0:
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


func populate_char_grid():
	
	var total = $Grid.get_child_count()
	grid_dimensions[0] = $Grid.columns
	grid_dimensions[1] = int(ceil(total/grid_dimensions[0]))
	
	var center_indexes = [] # 5, 17, 29
	var left_indexes = []
	var right_indexes = []
	var center_point = int((grid_dimensions[0] - 1) / 2.0)
	
	for y in grid_dimensions[1]:
		center_indexes.append(center_point + (y * grid_dimensions[0]))
		left_indexes.append(y * grid_dimensions[0])
		right_indexes.append(left_indexes[y] + grid_dimensions[0] - 1)
		
	var index_array = []
	for level in center_indexes.size():
		var current_coord = center_indexes[level]
		var changer := 1
		while current_coord >= left_indexes[level] and current_coord <= right_indexes[level]:
			index_array.append(current_coord)
			current_coord += changer
			changer = -changer
			if changer < 0: changer -= 1
			else: changer += 1
			
	var char_names = []
	for character in character_data.keys(): # get Random to the back
		if character != "Random":
			char_names.append(character)
	if posmod(char_names.size(), 2) != 0:
		char_names.append("Random")
	else:
		char_names.insert(char_names.size() - 1, "Random") # to ensure Random is the rightmost one

	for char_pos in char_names.size():
		char_grid[index_array[char_pos]] = char_names[char_pos]
	
	for character_number in char_grid.keys():
		$Grid.get_child(character_number).texture = character_data[char_grid[character_number]]["portrait"]
		$Grid.get_child(character_number).modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	P1_picker_pos = center_indexes[0]
	P2_picker_pos = center_indexes[0] # WIP, later change to +1
	
		
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
		grid.get_node("Special").load_button("Special", Settings.button_to_string(input_map["P" + player_index + "_special"]))
		grid.get_node("Unique").load_button("Unique", Settings.button_to_string(input_map["P" + player_index + "_unique"]))

		grid.get_node("TapJump2").text = TAP_JUMP_OPTIONS[input_map["P" + player_index + "_tapjump"]]
		grid.get_node("DJFastfall2").text = DJ_FASTFALL_OPTIONS[input_map["P" + player_index + "_dj_fastfall"]]
		grid.get_node("InputBuffer2").text = INPUT_BUFFER_OPTIONS[input_map["P" + player_index + "_buffer"]]
		grid.get_node("InputAssist2").text = INPUT_ASSIST_OPTIONS[input_map["P" + player_index + "_input_assist"]]


func _physics_process(_delta):
	
	if Globals.player_count == 1:
		if P1_phase == 0:
			if Input.is_action_just_pressed("P1_fierce"):
				play_audio("ui_back", {})
				$Transition.play("transit_to_survival")
	else:
	
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
		
	if Input.is_action_pressed("P1_special"): # reveal/hide button check
		$P1_ButtonCheck.show()
	else:
		$P1_ButtonCheck.hide()
		
	if Globals.player_count == 2:
		if Input.is_action_pressed("P2_special"):
			$P2_ButtonCheck.show()
		else:
			$P2_ButtonCheck.hide()
		
	
	# directional keys
	var P1_dir = $P1DirInputs.P1_dir
		
	var P2_dir := Vector2.ZERO
	if Globals.player_count == 2:
		P2_dir = $P2DirInputs.P2_dir
	
	move_pickers(P1_dir, P2_dir)

	# change palette, in phase 0 only
	var P1_p_dir = 0
	if Input.is_action_just_pressed("P1_aux"):
		P1_p_dir -= 1
	if Input.is_action_just_pressed("P1_block"):
		P1_p_dir += 1

	var P2_p_dir = 0
	if Globals.player_count == 2:
		if Input.is_action_just_pressed("P2_aux"):
			P2_p_dir -= 1
		if Input.is_action_just_pressed("P2_block"):
			P2_p_dir += 1
	
	change_palette(P1_p_dir, P2_p_dir)
		
	
	if Input.is_action_just_pressed("P1_light"): # select character
		if P1_phase == 0:
			P1_picked_character()
	if Globals.player_count == 2:
		if Input.is_action_just_pressed("P2_light"): # select character
			if P2_phase == 0:
				P2_picked_character()
		
	if Input.is_action_just_pressed("P1_fierce"): # unselect character
		if P1_phase == 1:
			P1_unpicked_character()
	if Globals.player_count == 2:
		if Input.is_action_just_pressed("P2_fierce"): # unselect character
			if P2_phase == 1:
				P2_unpicked_character()

	if Globals.player_count == 2:
		if P1_phase == 1 and P2_phase == 1: 
			start_battle()
	else:
		if P1_phase == 1:
			start_battle()
	
func move_pickers(P1_dir, P2_dir):
	
	if P1_phase == 0:
		if P1_dir.x == 1:
			P1_picker_pos += 1
			if P1_picker_pos == $Grid.columns: P1_picker_pos = 0
			elif P1_picker_pos == $Grid.columns * 2: P1_picker_pos = $Grid.columns
			elif P1_picker_pos == $Grid.columns * 3: P1_picker_pos = $Grid.columns * 2
			P1_changed_character()
		elif P1_dir.x == -1:
			P1_picker_pos -= 1
			if P1_picker_pos == -1: P1_picker_pos = $Grid.columns - 1
			elif P1_picker_pos == $Grid.columns - 1: P1_picker_pos = ($Grid.columns * 2) - 1
			elif P1_picker_pos == ($Grid.columns * 2) - 1: P1_picker_pos = ($Grid.columns * 3) - 1
			P1_changed_character()
		if P1_dir.y == 1:
			P1_picker_pos += $Grid.columns
			if P1_picker_pos >= $Grid.columns * 3: P1_picker_pos -= $Grid.columns * 3
			P1_changed_character()
		elif P1_dir.y == -1:
			P1_picker_pos -= $Grid.columns
			if P1_picker_pos < 0: P1_picker_pos += $Grid.columns * 3
			P1_changed_character()
		
	if P2_phase == 0:
		if P2_dir.x == 1:
			P2_picker_pos += 1
			if P2_picker_pos == $Grid.columns: P2_picker_pos = 0
			elif P2_picker_pos == $Grid.columns * 2: P2_picker_pos = $Grid.columns
			elif P2_picker_pos == $Grid.columns * 3: P2_picker_pos = $Grid.columns * 2
			P2_changed_character()
		elif P2_dir.x == -1:
			P2_picker_pos -= 1
			if P2_picker_pos == -1: P2_picker_pos = $Grid.columns - 1
			elif P2_picker_pos == $Grid.columns - 1: P2_picker_pos = ($Grid.columns * 2) - 1
			elif P2_picker_pos == ($Grid.columns * 2) - 1: P2_picker_pos = ($Grid.columns * 3) - 1
			P2_changed_character()
		if P2_dir.y == 1:
			P2_picker_pos += $Grid.columns
			if P2_picker_pos >= $Grid.columns * 3: P2_picker_pos -= $Grid.columns * 3
			P2_changed_character()
		elif P2_dir.y == -1:
			P2_picker_pos -= $Grid.columns
			if P2_picker_pos < 0: P2_picker_pos += $Grid.columns * 3
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
		P1_phase = 1
		
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
		P2_phase = 1
		
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
	P1_phase = 0
	
func P2_unpicked_character():
	play_audio("ui_back", {})
	$P2_Picker/AnimationPlayer.play("flashing")
	yield(get_tree(),"idle_frame")
	P2_phase = 0
	
	

# ------------------------------------------------------------------------------------------------------------------------

func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	
func start_battle():
	battle_lock = true
	
	
	Globals.P1_char_ref = char_grid[P1_picker_pos]
	Globals.P1_palette = P1_palette_picked
#	Globals.P1_input_style = P1_input_style
	Globals.P2_char_ref = char_grid[P2_picker_pos]
	Globals.P2_palette = P2_palette_picked
#	Globals.P2_input_style = P2_input_style
	
	
	# saving last picked characters and stages
	var last_picked = Settings.load_last_picked()
#	var last_picked = {
#		"P1_character" : P1_picker_pos,
#		"P1_palette" : P1_palette_picked,
#		"P1_stage" : $P1_StageSelect/StageList.get_child(3).stage_name,
#		"P2_character" : P2_picker_pos,
#		"P2_palette" : P2_palette_picked,
#		"P2_stage" : $P2_StageSelect/StageList.get_child(3).stage_name,
#	}
	if last_picked == null: # set up if no last_picked
		last_picked = {
				"P1_character" : null,
				"P1_palette" : null,
				"P1_stage" : null,
				"P2_character" : null,
				"P2_palette" : null,
				"P2_stage" : null,
			}
	last_picked["P1_character"] = P1_picker_pos
	last_picked["P1_palette"] = P1_palette_picked
	if Globals.player_count > 1:
		last_picked["P2_character"] = P2_picker_pos
		last_picked["P2_palette"] = P2_palette_picked
	Settings.save_last_picked(last_picked)
	
	
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
		
	BGM.fade()
	$Transition.play("transit_to_battle")
	
	
func change_scene(new_scene: String): # called by animation
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)
