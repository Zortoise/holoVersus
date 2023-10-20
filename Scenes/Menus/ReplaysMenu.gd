extends Node2D

const INITIAL_HELD_FRAMES = 10
const HELD_INTERVAL = 2

var loaded_replay_button = load("res://Scenes/Menus/ButtonTypeH.tscn")
var selected_replay := 0


func _ready():
	
	BGM.play_common("TitleThemes")
	
	for node in $ReplaysList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$ReplaysList/SelectReplay.initial_focus()
	
	for node in $RenameMenu/RenameList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$RenameMenu/RenameList/Rename.load_button("Filename", "", $AltInputs, null, \
			$RenameMenu/RenameList/InvalidFilename/Label)
			
	for node in $DeleteMenu/DeleteList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")

	load_replays()
	
	$RenameMenu.hide()
	$DeleteMenu.hide()
	
	
func load_replays(): # load in the replays in the Replays directory
	
	unselect_all()
	
	for x in $SavedReplays/ReplaysScroll/ReplaysList2.get_child_count():
		$SavedReplays/ReplaysScroll/ReplaysList2.get_child(0).free()
	
	var dir = Directory.new()
	if dir.dir_exists("user://Replays"):
		if dir.open("user://Replays") == OK:
			dir.list_dir_begin(true)
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".tres"):
					var replay = ResourceLoader.load("user://Replays/" + file_name)
					var replay_button = loaded_replay_button.instance()
					$SavedReplays/ReplaysScroll/ReplaysList2.add_child(replay_button)
					replay_button.load_button(replay, "user://Replays/" + file_name)
				file_name = dir.get_next()
		else:
			print("Error: Cannot open Replays folder")
			
	for node in $SavedReplays/ReplaysScroll/ReplaysList2.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
			
	
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		match $SavedReplays.get_focus_owner().get_parent().name:
			"ReplaysList2":
				$ReplaysList/SelectReplay.initial_focus()
				play_audio("ui_back", {})
			"RenameList":
				$ReplaysList/RenameReplay.initial_focus()
				play_audio("ui_back", {})
				$RenameMenu.hide()
			"DeleteList":
				$ReplaysList/DeleteReplay.initial_focus()
				play_audio("ui_back", {})
				$DeleteMenu.hide()
			_:
				play_audio("ui_back", {})
				$Transition.play("transit_to_settings")
	
	
func _physics_process(_delta): # I can't believe I have to do this to get keyboard scrolling to work...
	if $SavedReplays.get_focus_owner().get_parent().name == "ReplaysList2":
		
		var dir = 0
		
		if Input.is_action_pressed("ui_up"):
			if $SavedReplays/Up.playing == false:
				dir -= 1
				$SavedReplays/Up.start()
			elif $SavedReplays/Up.time > INITIAL_HELD_FRAMES and posmod($SavedReplays/Up.time, HELD_INTERVAL) == 0:
				dir -= 1
		else:
			$SavedReplays/Up.stop()
			
		if Input.is_action_pressed("ui_down"):
			if $SavedReplays/Down.playing == false:
				dir += 1
				$SavedReplays/Down.start()
			elif $SavedReplays/Down.time > INITIAL_HELD_FRAMES and posmod($SavedReplays/Down.time, HELD_INTERVAL) == 0:
				dir += 1
		else:
			$SavedReplays/Down.stop()

		if dir != 0:	
			var focus = $SavedReplays.get_focus_owner().get_position_in_parent()
			if dir < 0 and focus > 0:
				$SavedReplays/ReplaysScroll/ReplaysList2.get_child(focus - 1).grab_focus()
			if dir > 0 and focus < $SavedReplays/ReplaysScroll/ReplaysList2.get_child_count() - 1:
				$SavedReplays/ReplaysScroll/ReplaysList2.get_child(focus + 1).grab_focus()
			
	
func focused(focused_node):
	match focused_node.get_parent().name:
		"ReplaysList2":
			yield(get_tree(),"idle_frame") # allow ScrollContainer to follow scroll before moving the cursor
			$Cursor.position = Vector2(focused_node.rect_global_position.x - 58, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
		"RenameList":
			$RenameMenu/Cursor.position = Vector2(focused_node.rect_global_position.x - 48, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
		"DeleteList":
			$DeleteMenu/Cursor.position = Vector2(focused_node.rect_global_position.x - 48, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
		_:
			$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, \
					focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)


func triggered(triggered_node):
	if !$Transition.is_playing():
		if triggered_node.get_parent().name == "ReplaysList2":
			play_audio("ui_accept", {"vol":-8})
			set_selected(triggered_node)
			$ReplaysList/SelectReplay.initial_focus()
		else:
			match triggered_node.name:
				"SelectReplay":
					if $SavedReplays/ReplaysScroll/ReplaysList2.get_child_count() > 0:
						play_audio("ui_accept", {"vol":-8})
						$SavedReplays/ReplaysScroll/ReplaysList2.get_child(selected_replay).grab_focus()
					else:
						play_audio("ui_deny", {"vol" : -9})
				"WatchReplay":
					play_audio("ui_accept2", {})
					watch_replay()
				"RenameReplay":
					play_audio("ui_accept", {"vol":-8})
					$RenameMenu.show()
					$RenameMenu/RenameList/Rename.initial_focus()
				"SaveName":
					if $RenameMenu/RenameList/Rename.is_valid():
						play_audio("ui_accept2", {})
						rename_replay()
						$ReplaysList/RenameReplay.initial_focus()
						$RenameMenu.hide()
					else:
						play_audio("ui_deny", {"vol" : -9})
				"CancelRename":
					$ReplaysList/RenameReplay.initial_focus()
					play_audio("ui_back", {})
					$RenameMenu.hide()
				"DeleteReplay":
					play_audio("ui_accept", {"vol":-8})
					$DeleteMenu.show()
					$DeleteMenu/DeleteList/CancelDelete.initial_focus()
				"Delete":
					play_audio("ui_accept2", {})
					delete_replay()
					$ReplaysList/DeleteReplay.initial_focus()
					$DeleteMenu.hide()
				"CancelDelete":
					$ReplaysList/DeleteReplay.initial_focus()
					play_audio("ui_back", {})
					$DeleteMenu.hide()
				"Return":
					play_audio("ui_back", {})
					$Transition.play("transit_to_settings")
					
					
func unselect_all():
	for node in $SavedReplays/ReplaysScroll/ReplaysList2.get_children():
		node.unselect()
	selected_replay = 0
	$ReplayInfo.hide()
	$Mismatch.hide()
	
	$ReplaysList/WatchReplay.disabled = true
	$ReplaysList/RenameReplay.disabled = true
	$ReplaysList/DeleteReplay.disabled = true
	
	
func find_from_filepath(filepath_to_find: String):
	for node in $SavedReplays/ReplaysScroll/ReplaysList2.get_children():
		if node.filepath == filepath_to_find:
			return node
	print("Error: Unable to find replay from filepath")


func set_selected(selected_node):
	for node in $SavedReplays/ReplaysScroll/ReplaysList2.get_children():
		node.unselect()
	selected_node.select()
	selected_replay = selected_node.get_position_in_parent()

	$ReplayInfo.show()
	$ReplayInfo/HSplitContainer/DateTime2.text = selected_node.resource.datetime
	$ReplayInfo/HSplitContainer3/Version2.text = selected_node.resource.version
	if selected_node.resource.netgame == true:
		$ReplayInfo/HSplitContainer2.modulate.a = 1.0
		$ReplayInfo/HSplitContainer2/Player1Name.text = selected_node.resource.P1_profile
		$ReplayInfo/HSplitContainer4.modulate.a = 1.0
		$ReplayInfo/HSplitContainer4/Player2Name.text = selected_node.resource.P2_profile
	else:
		$ReplayInfo/HSplitContainer2.modulate.a = 0.0
		$ReplayInfo/HSplitContainer4.modulate.a = 0.0
		
	if selected_node.resource.version != Globals.VERSION:
		$Mismatch.show()
	else:
		$Mismatch.hide()
		
	$ReplaysList/WatchReplay.disabled = false
	$ReplaysList/RenameReplay.disabled = false
	$ReplaysList/DeleteReplay.disabled = false
	
	
func watch_replay():
	Globals.watching_replay = true
	var replay = $SavedReplays/ReplaysScroll/ReplaysList2.get_child(selected_replay).resource
	
	Globals.stage_ref = replay.stage_ref
	Globals.P1_char_ref = replay.P1_char_ref
	Globals.P1_palette = replay.P1_palette
	Globals.P1_assist = replay.P1_assist
#	Globals.P1_input_style = replay.P1_input_style
	Globals.P2_char_ref = replay.P2_char_ref
	Globals.P2_palette = replay.P2_palette
	Globals.P2_assist = replay.P2_assist
#	Globals.P2_input_style = replay.P2_input_style
	Globals.starting_stock_pts = replay.starting_stock_pts
	Globals.time_limit = replay.time_limit
	Globals.assists = replay.assists
	Globals.static_stage = replay.static_stage
	Globals.music = replay.music # WIP
	Globals.replay_input_log = replay.input_log
	Globals.orig_rng_seed = replay.orig_rng_seed
	Settings.input_buffer_time = replay.input_buffer_time
	Settings.tap_jump = replay.tap_jump
	Settings.dj_fastfall = replay.dj_fastfall
	Settings.input_assist = replay.input_assist
	
	if replay.netgame == true:
		Globals.replay_is_netgame = true
		Globals.replay_profiles[0] = replay.P1_profile
		Globals.replay_profiles[1] = replay.P2_profile
	else:
		Globals.replay_is_netgame = false
		Globals.replay_profiles = ["", ""]
		
	BGM.fade()
	$Transition.play("transit_to_battle")
	
	
func rename_replay():
	var new_name = $RenameMenu/RenameList/Rename/Entry.text
	var old_filepath = $SavedReplays/ReplaysScroll/ReplaysList2.get_child(selected_replay).filepath
	
	var dir = Directory.new()
	
	var new_name2 = new_name
	var new_filepath = "user://Replays/" + new_name2 + ".tres" # set filepath
	var value := 2
	while dir.file_exists(new_filepath): # if there is already a replay of the same name, increment the name
		new_name2 = new_name + str(value)
		new_filepath = "user://Replays/" + new_name2 + ".tres"
		value += 1
	
	dir.rename(old_filepath, new_filepath) # change the filepath
	
	var loaded_replay = ResourceLoader.load(new_filepath) # change the internal name and resave it
	loaded_replay.data_name = new_name2
# warning-ignore:return_value_discarded
	ResourceSaver.save(new_filepath, loaded_replay)
	
	load_replays()
	
	var node_to_select = find_from_filepath(new_filepath) # reselect the renamed node
	if node_to_select != null:
		set_selected(node_to_select)
#		node_to_select.initial_focus()
	

func delete_replay():
	var old_filepath = $SavedReplays/ReplaysScroll/ReplaysList2.get_child(selected_replay).filepath
# warning-ignore:return_value_discarded
	OS.move_to_trash(ProjectSettings.globalize_path(old_filepath))
	load_replays()
	
			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
	Globals.next_scene = new_scene
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/LoadingScreen.tscn")
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	

