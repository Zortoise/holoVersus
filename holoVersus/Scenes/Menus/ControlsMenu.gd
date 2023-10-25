extends Node2D


const TAP_JUMP_OPTIONS = ["off", "on"]
const INPUT_BUFFER_OPTIONS = ["none", "1 frame", "2 frames", "3 frames", "4 frames", "5 frames", "6 frames"
		, "7 frames", "8 frames", "9 frames", "10 frames"]
const INPUT_ASSIST_OPTIONS = ["off", "on"]
const DEADZONE_OPTIONS = ["0.05", "0.10", "0.15", "0.20", "0.25", "0.30", "0.35", "0.40", "0.45", "0.50", "0.55", 
		"0.60", "0.65", "0.70", "0.75", "0.80", "0.85", "0.90", "0.95", "1.00"]
const DJ_FASTFALL_OPTIONS = ["off", "on"]

# for preset loader
const INITIAL_HELD_FRAMES = 10
const HELD_INTERVAL = 2
var loaded_preset_button = load("res://Scenes/Menus/ButtonTypeH.tscn")
var selected_preset := 0


var input_map = {} # set this by reading config files
var current_player := 0
var selected_mode := false # if true, is currently changing controls

var input_wait_node # when Popup is visible, wait for input then map it to this
var input_lock_time = 0

var fixed_deadzone := 0.2 # for joystick

var action_for_extra_button
var loaded_extra_button = load("res://Scenes/Menus/ButtonTypeE3.tscn")
const MAX_EXTRA_BUTTON_NUMBER = 18


func _ready():
	
	BGM.play_random_in_folder("Common/TitleThemes")

	for node in $PlayersList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	
	for list in ["ControlsListL", "ControlsListR"]:
		var nodes = get_node(list).get_children()
		for node in nodes:
			if node.is_in_group("has_focus"):
				node.connect("focused", self, "focused2")
			if node.is_in_group("has_trigger"):
				node.connect("triggered", self, "triggered2")
				
	for node in $ControlsListBottom.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused2")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
			
	for node in $ControlsListExtra.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused2")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
			
	for node in $PopUpExtra/ExtraButtonActions.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
			
	for node in $PopUpSave/SaveList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
			
	for node in $PopUpLoad/LoadList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
			
	for node in $PopUpRename/RenameList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
			

	
	input_map = Settings.load_input_map()
	
	$ControlsListL/Up.load_button("Up", Settings.button_to_string(input_map.P1_up))
	$ControlsListL/Down.load_button("Down", Settings.button_to_string(input_map.P1_down))
	$ControlsListL/Left.load_button("Left", Settings.button_to_string(input_map.P1_left))
	$ControlsListL/Right.load_button("Right", Settings.button_to_string(input_map.P1_right))
	$ControlsListL/Jump.load_button("Jump", Settings.button_to_string(input_map.P1_jump))
	$ControlsListL/Special.load_button("Special", Settings.button_to_string(input_map.P1_special))
	$ControlsListL/Unique.load_button("Unique", Settings.button_to_string(input_map.P1_unique))
	$ControlsListL/Pause.load_button("Pause", Settings.button_to_string(input_map.P1_pause))
	
	$ControlsListR/Light.load_button("Light", Settings.button_to_string(input_map.P1_light))
	$ControlsListR/Fierce.load_button("Fierce", Settings.button_to_string(input_map.P1_fierce))
	$ControlsListR/Dash.load_button("Dash", Settings.button_to_string(input_map.P1_dash))
	$ControlsListR/Aux.load_button("Aux", Settings.button_to_string(input_map.P1_aux))
	$ControlsListR/Block.load_button("Block", Settings.button_to_string(input_map.P1_block))
	$ControlsListR/RS_Up.load_button("RS Up", Settings.button_to_string(input_map.P1_rs_up))
	$ControlsListR/RS_Down.load_button("RS Down", Settings.button_to_string(input_map.P1_rs_down))
	$ControlsListR/RS_Left.load_button("RS Left", Settings.button_to_string(input_map.P1_rs_left))
	$ControlsListR/RS_Right.load_button("RS Right", Settings.button_to_string(input_map.P1_rs_right))
	
	$ControlsListBottom/TapJump.load_button("Up to Jump", TAP_JUMP_OPTIONS, input_map.P1_tapjump)
	$ControlsListBottom/DJFastfall.load_button("Down+Jump Fastfall", DJ_FASTFALL_OPTIONS, input_map.P1_dj_fastfall)
	$ControlsListBottom/InputBuffer.load_button("Input Buffer", INPUT_BUFFER_OPTIONS, input_map.P1_buffer)
	$ControlsListBottom/InputAssist.load_button("Input Assist", INPUT_ASSIST_OPTIONS, input_map.P1_input_assist)
	$ControlsListBottom/Deadzone.load_button("Deadzone", DEADZONE_OPTIONS, input_map.P1_deadzone)
	
	$PopUpSave/SaveList/PresetName.load_button("Preset Name", "", $AltInputs, 50, $PopUpSave/SaveList/InvalidFilename/Label)
	$PopUpRename/RenameList/Rename.load_button("Filename", "", $AltInputs, 50, $PopUpRename/RenameList/InvalidFilename/Label)
		
	$PlayersList/Player1.initial_focus()
	
	
func _input(event): # remapping input when PopUp is visible
	if $PopUp.visible:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_ESCAPE and input_wait_node.name.begins_with("RS"):
				var key_name = "P" + str(current_player + 1) + "_" + input_wait_node.name.to_lower()
				play_audio("ui_deny", {"vol" : -5})
				input_map[key_name] = null
				input_wait_node.map("")
				$PopUp.hide()
				input_lock_time = 2
			else:
				var key_name = "P" + str(current_player + 1) + "_" + input_wait_node.name.to_lower()

	#			for key in input_map: # search for repeated inputs for current player, skip itself
	#				if key.begins_with("P" + str(current_player + 1)) and key != key_name and input_map[key] == event.scancode:
	#					$PopUp/Label2/AnimationPlayer.stop()
	#					$PopUp/Label2/AnimationPlayer.play("default")
	#					play_audio("ui_deny", {"vol" : -5})
	#					return

				play_audio("ui_accept2", {"vol":-4})
				input_map[key_name] = event.scancode
				
				input_wait_node.map(Settings.button_to_string(event.scancode))
				$PopUp.hide()
				input_lock_time = 2 # need to wait some time before returning focus to prevent double firing
				# can't use yield(get_tree(),"idle_frame") or call_deferred() for this... need 2 frames
			
		elif event is InputEventJoypadButton and event.pressed:
			
			var key_name = "P" + str(current_player + 1) + "_" + input_wait_node.name.to_lower()

#			for key in input_map: # search for repeated inputs for current player, skip itself
#				if key.begins_with("P" + str(current_player + 1)) and key != key_name and input_map[key] is Array and \
#					input_map[key].hash() == [event.device, event.button_index].hash():
#					$PopUp/Label2/AnimationPlayer.stop()
#					$PopUp/Label2/AnimationPlayer.play("default")
#					play_audio("ui_deny", {"vol" : -5})
#					return

			play_audio("ui_accept2", {"vol":-4})
			input_map[key_name] = [event.device, event.button_index]
			
			input_wait_node.map(Settings.button_to_string([event.device, event.button_index]))
			$PopUp.hide()
			input_lock_time = 2
			
		elif event is InputEventJoypadMotion and abs(event.axis_value) >= fixed_deadzone:
			
			var key_name = "P" + str(current_player + 1) + "_" + input_wait_node.name.to_lower()
			
#			for key in input_map: # search for repeated inputs for current player, skip itself
#				if key.begins_with("P" + str(current_player + 1)) and key != key_name and input_map[key] is Array and \
#					input_map[key].hash() == [event.device, event.axis, axis_sign].hash():
#					$PopUp/Label2/AnimationPlayer.stop()
#					$PopUp/Label2/AnimationPlayer.play("default")
#					play_audio("ui_deny", {"vol" : -5})
#					return
				
			play_audio("ui_accept2", {"vol":-4})
			input_map[key_name] = [event.device, event.axis, sign(event.axis_value)]
			
			input_wait_node.map(Settings.button_to_string([event.device, event.axis, sign(event.axis_value)]))
			$PopUp.hide()
			input_lock_time = 2
			
			
	elif $PopUpExtra2.visible:
		if event is InputEventKey and event.pressed:
			play_audio("ui_accept2", {"vol":-4})
			var extra_button = [action_for_extra_button, event.scancode]
			input_map["P" + str(current_player + 1) + "_extra_buttons"].append(extra_button)
			$PopUpExtra2.hide()
			input_lock_time = 2 # need to wait some time before returning focus to prevent double firing
			input_wait_node = $ControlsListExtra/AddButton
			load_extra_buttons()
			
		elif event is InputEventJoypadButton and event.pressed:
			play_audio("ui_accept2", {"vol":-4})
			var extra_button = [action_for_extra_button, [event.device, event.button_index]]
			input_map["P" + str(current_player + 1) + "_extra_buttons"].append(extra_button)
			$PopUpExtra2.hide()
			input_lock_time = 2 # need to wait some time before returning focus to prevent double firing
			input_wait_node = $ControlsListExtra/AddButton
			load_extra_buttons()
			
		elif event is InputEventJoypadMotion and abs(event.axis_value) >= fixed_deadzone:
			play_audio("ui_accept2", {"vol":-4})
			var extra_button = [action_for_extra_button, [event.device, event.axis, sign(event.axis_value)]]
			input_map["P" + str(current_player + 1) + "_extra_buttons"].append(extra_button)
			$PopUpExtra2.hide()
			input_lock_time = 2 # need to wait some time before returning focus to prevent double firing
			input_wait_node = $ControlsListExtra/AddButton
			load_extra_buttons()
		
			

func _physics_process(_delta):
	if input_lock_time > 0:
		input_lock_time -= 1
		if input_lock_time <= 0:
			input_wait_node.initial_focus() # regrab focus to the old node before PopUp appears
			
	# moving up/down in loaded preset list
	if $PopUpLoad.visible and $PopUpLoad/SavedPresets.get_focus_owner().get_parent().name == "PresetsList":
		
		var dir = 0
		
		if Input.is_action_pressed("ui_up"):
			if $PopUpLoad/SavedPresets/Up.playing == false:
				dir -= 1
				$PopUpLoad/SavedPresets/Up.start()
			elif $PopUpLoad/SavedPresets/Up.time > INITIAL_HELD_FRAMES and posmod($PopUpLoad/SavedPresets/Up.time, HELD_INTERVAL) == 0:
				dir -= 1
		else:
			$PopUpLoad/SavedPresets/Up.stop()
			
		if Input.is_action_pressed("ui_down"):
			if $PopUpLoad/SavedPresets/Down.playing == false:
				dir += 1
				$PopUpLoad/SavedPresets/Down.start()
			elif $PopUpLoad/SavedPresets/Down.time > INITIAL_HELD_FRAMES and posmod($PopUpLoad/SavedPresets/Down.time, HELD_INTERVAL) == 0:
				dir += 1
		else:
			$PopUpLoad/SavedPresets/Down.stop()

		var focus = $PopUpLoad/SavedPresets.get_focus_owner().get_position_in_parent()
		if dir < 0 and focus > 0:
			$PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child(focus - 1).grab_focus()
		elif dir > 0 and focus < $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child_count() - 1:
			$PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child(focus + 1).grab_focus()
				
	
func _process(_delta):
	if !$PopUp.visible and input_lock_time <= 0:

		if Input.is_action_just_pressed("ui_cancel"):
			if $PopUpExtra.visible:
				play_audio("ui_back", {})
				$PopUpExtra.hide()
				$ControlsListExtra/AddButton.initial_focus()
			elif $PopUpSave.visible:
				play_audio("ui_back", {})
				$PopUpSave.hide()
				$ControlsListBottom/SavePreset.initial_focus()
			elif $PopUpRename.visible:
				play_audio("ui_back", {})
				$PopUpLoad.hide()
				$PopUpLoad/LoadList/RenamePreset.initial_focus()
			elif $PopUpLoad.visible:
				play_audio("ui_back", {})
				$PopUpLoad.hide()
				$ControlsListBottom/LoadPreset.initial_focus()
			elif $ControlsListExtra2.get_focus_owner().get_parent() != null and \
					$ControlsListExtra2.get_focus_owner().get_parent().name == "ControlsListExtra2":
				play_audio("ui_back", {})
				$ControlsListExtra/RemoveButton.initial_focus()
			elif !selected_mode:
				update_player_input()
				Settings.save_input_map(input_map)
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_main")
			else:
				switch_mode(false)
				play_audio("ui_back", {})
				$PlayersList.get_node("Player" + str(current_player + 1)).initial_focus()

			
func switch_mode(select):
	if selected_mode != select:
		selected_mode = select
		if select:
			$Cursor2.show()
			for node in $PlayersList.get_children():
				if !node is Label:
					node.focus_mode = 1
			for list in ["ControlsListL", "ControlsListR", "ControlsListBottom"]:
				var nodes = get_node(list).get_children()
				for node in nodes:
					if !node is Label:
						node.focus_mode = 2
		else:
			$Cursor2.hide()
			for node in $PlayersList.get_children():
				if !node is Label:
					node.focus_mode = 2
			for list in ["ControlsListL", "ControlsListR", "ControlsListBottom"]:
				var nodes = get_node(list).get_children()
				for node in nodes:
					if !node is Label:
						node.focus_mode = 1
			
			
func update_player_input():
	var player_index = str(current_player + 1)
	# save player's data into "input_map"
	input_map["P" + player_index + "_tapjump"] = $ControlsListBottom/TapJump.option_pointer
	input_map["P" + player_index + "_dj_fastfall"] = $ControlsListBottom/DJFastfall.option_pointer
	input_map["P" + player_index + "_buffer"] = $ControlsListBottom/InputBuffer.option_pointer
	input_map["P" + player_index + "_input_assist"] = $ControlsListBottom/InputAssist.option_pointer
	input_map["P" + player_index + "_deadzone"] = $ControlsListBottom/Deadzone.option_pointer
			
func load_player_input():
	var player_index = str(current_player + 1)
	
	$ControlsListL/Up.map(Settings.button_to_string(input_map["P" + player_index + "_up"]))
	$ControlsListL/Down.map(Settings.button_to_string(input_map["P" + player_index + "_down"]))
	$ControlsListL/Left.map(Settings.button_to_string(input_map["P" + player_index + "_left"]))
	$ControlsListL/Right.map(Settings.button_to_string(input_map["P" + player_index + "_right"]))
	$ControlsListL/Jump.map(Settings.button_to_string(input_map["P" + player_index + "_jump"]))
	$ControlsListL/Special.map(Settings.button_to_string(input_map["P" + player_index + "_special"]))
	$ControlsListL/Unique.map(Settings.button_to_string(input_map["P" + player_index + "_unique"]))
	$ControlsListL/Pause.map(Settings.button_to_string(input_map["P" + player_index + "_pause"]))
	
	$ControlsListR/Light.map(Settings.button_to_string(input_map["P" + player_index + "_light"]))
	$ControlsListR/Fierce.map(Settings.button_to_string(input_map["P" + player_index + "_fierce"]))
	$ControlsListR/Dash.map(Settings.button_to_string(input_map["P" + player_index + "_dash"]))
	$ControlsListR/Aux.map(Settings.button_to_string(input_map["P" + player_index + "_aux"]))
	$ControlsListR/Block.map(Settings.button_to_string(input_map["P" + player_index + "_block"]))
	$ControlsListR/RS_Up.map(Settings.button_to_string(input_map["P" + player_index + "_rs_up"]))
	$ControlsListR/RS_Down.map(Settings.button_to_string(input_map["P" + player_index + "_rs_down"]))
	$ControlsListR/RS_Left.map(Settings.button_to_string(input_map["P" + player_index + "_rs_left"]))
	$ControlsListR/RS_Right.map(Settings.button_to_string(input_map["P" + player_index + "_rs_right"]))
	
	$ControlsListBottom/TapJump.change_pointer(input_map["P" + player_index + "_tapjump"])
	$ControlsListBottom/DJFastfall.change_pointer(input_map["P" + player_index + "_dj_fastfall"])
	$ControlsListBottom/InputBuffer.change_pointer(input_map["P" + player_index + "_buffer"])
	$ControlsListBottom/InputAssist.change_pointer(input_map["P" + player_index + "_input_assist"])
	$ControlsListBottom/Deadzone.change_pointer(input_map["P" + player_index + "_deadzone"])
	
	load_extra_buttons()
	
	
func load_extra_buttons():
	for x in $ControlsListExtra2.get_child_count(): # first remove all children
		$ControlsListExtra2.remove_child($ControlsListExtra2.get_child(0))
		
	for extra_button in input_map["P" + str(current_player + 1) + "_extra_buttons"]:
		var new_label = loaded_extra_button.instance()
		new_label.load_button(extra_button)
		$ControlsListExtra2.add_child(new_label)
		
	for node in $ControlsListExtra2.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused4")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered4")


func focused(focused_node):
	match focused_node.get_parent().name:
		"PlayersList":
			$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
			switch_mode(false)
			for node in $PlayersList.get_children():
				node.modulate = Color(1.0, 1.0, 1.0) # focused node will change its own modulate after this
			match focused_node.name:
				"Player1":
					update_player_input()
					current_player = 0
					load_player_input()
				"Player2":
					update_player_input()
					current_player = 1
					load_player_input()
		"ExtraButtonActions":
			$PopUpExtra/Cursor.position = Vector2(focused_node.rect_global_position.x - 48, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
		"SaveList":
			$PopUpSave/Cursor.position = Vector2(focused_node.rect_global_position.x - 48, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
		"LoadList":
			$PopUpLoad/Cursor.position = Vector2(focused_node.rect_global_position.x - 48, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
		"RenameList":
			$PopUpRename/Cursor.position = Vector2(focused_node.rect_global_position.x - 48, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
					
	for node in $ControlsListExtra2.get_children():
		node.focus_mode = 0
					

func focused2(focused_node): # for sub menu
	$Cursor2.position = Vector2(focused_node.rect_global_position.x - 48, \
			focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
	switch_mode(true)
	
	var current_player_node = $PlayersList.get_node("Player" + str(current_player + 1))
	current_player_node.modulate = Color(1.5, 1.5, 1.5) # highlight current player
	$Cursor.position = Vector2(current_player_node.rect_global_position.x - 48, \
			current_player_node.rect_global_position.y + current_player_node.rect_size.y / 2.0)
			
	for node in $ControlsListExtra2.get_children():
		node.focus_mode = 0
	
	
func focused3(focused_node): # for preset list
	yield(get_tree(),"idle_frame") # allow ScrollContainer to follow scroll before moving the cursor
	$PopUpLoad/Cursor.position = Vector2(focused_node.rect_global_position.x - 58, \
			focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
	for node in $ControlsListExtra2.get_children():
		node.focus_mode = 0
			
			
func focused4(focused_node): # for extra buttons
	$Cursor2.position = Vector2(focused_node.rect_global_position.x - 48, \
			focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)



func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.get_parent().name:
			"PlayersList", "ControlsListBottom", "ControlsListExtra":
				match triggered_node.name:
					"Player1", "Player2", "Player3", "Player4":
						play_audio("ui_accept", {"vol":-8})
						$ControlsListL/Up.initial_focus()
					"AddButton":
						if $ControlsListExtra2.get_child_count() < MAX_EXTRA_BUTTON_NUMBER:
							play_audio("ui_accept", {"vol":-8})
							$PopUpExtra.show()
							$PopUpExtra/ExtraButtonActions/Up.initial_focus()
						else:
							play_audio("ui_deny", {"vol" : -5})
					"RemoveButton":
						if $ControlsListExtra2.get_child_count() > 0:
							play_audio("ui_accept", {"vol":-8})
							for node in $ControlsListExtra2.get_children():
								node.focus_mode = 2
							$ControlsListExtra2.get_child(0).initial_focus()
						else:
							play_audio("ui_deny", {"vol" : -5})
					"ClearButtons":
						play_audio("ui_accept", {"vol":-8})
						input_map["P" + str(current_player + 1) + "_extra_buttons"] = []
						load_extra_buttons()
					"Save":
						update_player_input()
						Settings.save_input_map(input_map)
						play_audio("ui_accept", {"vol":-8})
						$Transition.play("transit_to_main")
					"Discard":
						play_audio("ui_back", {})
						$Transition.play("transit_to_main")
					"LoadPreset":
						play_audio("ui_accept", {"vol":-8})
						load_preset_list()
						$PopUpLoad.show()
						$PopUpLoad/LoadList/SelectPreset.initial_focus()
					"SavePreset":
						play_audio("ui_accept", {"vol":-8})
						$PopUpSave.show()
						$PopUpSave/SaveList/PresetName/Entry.text = ""
						$PopUpSave/SaveList/PresetName.red_text()
						$PopUpSave/SaveList/PresetName.initial_focus()
						
			"ExtraButtonActions":
				match triggered_node.name:
					"CancelSelection":
						play_audio("ui_back", {})
						$PopUpExtra.hide()
						$ControlsListExtra/AddButton.initial_focus()
					_:
						action_for_extra_button = triggered_node.name.to_lower()
						play_audio("ui_accept", {"vol":-8})
						$PopUpExtra.hide()
						$PopUpExtra2.show()
						$PopUpExtra2/Label.text = "Press input to map \n\"" + triggered_node.name + "\" to..."
						
			"SaveList":
				match triggered_node.name:
					"ConfirmSavePreset":
						play_audio("ui_accept2", {})
						save_preset()
						$PopUpSave.hide()
						$ControlsListBottom/SavePreset.initial_focus()
					"CancelSavePreset":
						play_audio("ui_back", {})
						$PopUpSave.hide()
						$ControlsListBottom/SavePreset.initial_focus()
				
			"LoadList":
				match triggered_node.name:
					"SelectPreset":
						if $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child_count() > 0:
							play_audio("ui_accept", {"vol":-8})
							$PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child(selected_preset).grab_focus()
						else:
							play_audio("ui_deny", {"vol" : -5})
					"ConfirmLoadPreset":
						play_audio("ui_accept2", {})
						$PopUpLoad.hide()
						$ControlsListBottom/LoadPreset.initial_focus()
						load_selected_preset()
					"RenamePreset":
						play_audio("ui_accept", {"vol":-8})
						$PopUpRename.show()
						$PopUpRename/RenameList/Rename.initial_focus()
					"DeletePreset":
						play_audio("ui_accept2", {})
						delete_preset()
					"CancelLoadPreset":
						play_audio("ui_back", {})
						$PopUpLoad.hide()
						$ControlsListBottom/LoadPreset.initial_focus()
						
			"RenameList":
				match triggered_node.name:
					"SaveName":
						if $PopUpRename/RenameList/Rename.is_valid():
							play_audio("ui_accept2", {})
							rename_preset()
							$PopUpRename.hide()
							$PopUpLoad/LoadList/RenamePreset.initial_focus()
						else:
							play_audio("ui_deny", {"vol" : -5})
					"CancelRename":
						$PopUpLoad/LoadList/RenamePreset.initial_focus()
						play_audio("ui_back", {})
						$PopUpRename.hide()
					
			
func triggered2(triggered_node): # for sub menu
	$PopUp.show()
	$PopUp.grab_focus()
	input_wait_node = triggered_node # for regrabbing focus
	$PopUp/Label.text = "Press input to map \n\"" + input_wait_node.name + "\" to..."
	if triggered_node.name.begins_with("RS"):
		$PopUp/RSLabel.show()
	else: $PopUp/RSLabel.hide()
	play_audio("ui_accept", {"vol":-8})
	
	
func triggered3(triggered_node): # for preset list
	play_audio("ui_accept", {"vol":-8})
	set_selected(triggered_node)
	$PopUpLoad/LoadList/SelectPreset.initial_focus()
	
	
func triggered4(triggered_node): # for deleting extra buttons
	play_audio("ui_accept2", {"vol":-4})
#	print(input_map["P" + str(current_player + 1) + "_extra_buttons"])
#	print(triggered_node.extra_button_stored)
	input_map["P" + str(current_player + 1) + "_extra_buttons"].erase(triggered_node.extra_button_stored)
	load_extra_buttons()
	$ControlsListExtra/RemoveButton.initial_focus()
	

		
# CONTROL PRESETS ----------------------------------------------------------------------------------------------------------------------------------------

		
func save_preset():
	var preset_name = $PopUpSave/SaveList/PresetName/Entry.text
	
	var new_preset = load("res://Scenes/Menus/ControlPreset.gd").new()
	new_preset.create_preset(current_player, input_map, preset_name)

func load_preset_list(): # load in the presets in the Presets directory
	unselect_all_presets()
	
	for x in $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child_count():
		$PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child(0).free()

	var dir = Directory.new()
	if dir.dir_exists("user://Presets"):
		if dir.open("user://Presets") == OK:
			dir.list_dir_begin(true)
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var preset = ResourceLoader.load("user://Presets/" + file_name)
					var preset_button = loaded_preset_button.instance()
					$PopUpLoad/SavedPresets/PresetsScroll/PresetsList.add_child(preset_button)
					preset_button.load_button(preset, "user://Presets/" + file_name)
				file_name = dir.get_next()
		else:
			print("Error: Cannot open Presets folder")
			
	for node in $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused3")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered3")


func unselect_all_presets():
	for node in $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_children():
		node.unselect()
	selected_preset = 0
	
	$PopUpLoad/LoadList/ConfirmLoadPreset.disabled = true
	$PopUpLoad/LoadList/RenamePreset.disabled = true
	$PopUpLoad/LoadList/DeletePreset.disabled = true
	
	
	
func set_selected(selected_node):
	for node in $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_children():
		node.unselect()
	selected_node.select()
	selected_preset = selected_node.get_position_in_parent()
	
	$PopUpLoad/LoadList/ConfirmLoadPreset.disabled = false
	$PopUpLoad/LoadList/RenamePreset.disabled = false
	$PopUpLoad/LoadList/DeletePreset.disabled = false
	
	
func delete_preset():
	var old_filepath = $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child(selected_preset).filepath
# warning-ignore:return_value_discarded
	OS.move_to_trash(ProjectSettings.globalize_path(old_filepath))
	load_preset_list()
	
	
func rename_preset():
	var new_name = $PopUpRename/RenameList/Rename/Entry.text
	var old_filepath = $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child(selected_preset).filepath
	
	var dir = Directory.new()
	
	var new_name2 = new_name
	var new_filepath = "user://Presets/" + new_name2 + ".tres" # set filepath
	var value := 2
	while dir.file_exists(new_filepath): # if there is already a replay of the same name, increment the name
		new_name2 = new_name + str(value)
		new_filepath = "user://Presets/" + new_name2 + ".tres"
		value += 1
	
	dir.rename(old_filepath, new_filepath) # change the filepath
	
	var loaded_preset = ResourceLoader.load(new_filepath) # change the internal name and resave it
	loaded_preset.data_name = new_name2
# warning-ignore:return_value_discarded
	ResourceSaver.save(new_filepath, loaded_preset)
	
	load_preset_list()
	
	var node_to_select = find_from_filepath(new_filepath) # reselect the renamed node
	if node_to_select != null:
		set_selected(node_to_select)
		
		
func find_from_filepath(filepath_to_find: String):
	for node in $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_children():
		if node.filepath == filepath_to_find:
			return node
	print("Error: Unable to find replay from filepath")
	
	
func load_selected_preset():
	var preset = $PopUpLoad/SavedPresets/PresetsScroll/PresetsList.get_child(selected_preset).resource
	Settings.set_input_preset(input_map, current_player, preset.preset)
	load_player_input()
	
#func set_preset(_shifted_node): # preset was changed
#	input_map["P" + str(current_player + 1) + "_preset"] = $ControlsListBottom/Presets.option_pointer
#	if PRESET_OPTIONS[input_map["P" + str(current_player + 1) + "_preset"]] in Settings.INPUT_PRESETS:
#		Settings.set_input_preset(input_map, current_player, PRESET_OPTIONS[input_map["P" + str(current_player + 1) + "_preset"]])
#		load_player_input()

# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
	Globals.next_scene = new_scene
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/LoadingScreen.tscn")
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)

