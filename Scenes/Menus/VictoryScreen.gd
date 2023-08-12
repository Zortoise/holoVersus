extends Node2D


var rematching := [false, false] # each correspond to a player

var replay


func _ready():
	
	BGM.bgm(BGM.common_music["victory"])
	
	$ReplayMenu.hide()
	
	$AltInputs.active = false
	
	# load the winner
	$Control/Winner.text = "Player " + str(Globals.winner[0] + 1)
	$Control/Character.text = Globals.winner[2]
	$FullArt.texture = ResourceLoader.load("res://Characters/" + Globals.winner[1] + "/UI/full_art.png")
	match Globals.winner[0]:
		0:
			$Background/Triangle.modulate = Color(0.73, 0.19, 0.27)
			$Background/Triangle2.modulate = Color(0.73, 0.19, 0.27)
		1:
			$Background/Triangle.modulate = Color(0.22, 0.48, 0.82)
			$Background/Triangle2.modulate = Color(0.22, 0.48, 0.82)
	
	for node in $VictoryMenu/VictoryList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$VictoryMenu/VictoryList/Rematch.initial_focus()
	
	for node in $ReplayMenu/ReplayList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	
	for player_rematching in $VictoryMenu/Rematching.get_children():
		player_rematching.modulate.a = 0.0
		
	replay = ResourceLoader.load("res://Scenes/Menus/Replay.gd").new()
	replay.generate_replay()
	
	$ReplayMenu/ReplayList/Rename.load_button("Filename:", replay.data_name, $AltInputs, 50, \
			$ReplayMenu/ReplayList/InvalidFilename/Label)
	

func _process(_delta):
	
	if $VictoryMenu/VictoryList/Rematch.has_focus():
		if Input.is_action_just_pressed("P1_light") and rematching[0] == false:
			play_audio("ui_accept", {"vol":-8})
			set_rematch(0)
		if Input.is_action_just_pressed("P1_fierce") and rematching[0] == true:
			play_audio("ui_back", {})
			unset_rematch(0)
		if Input.is_action_just_pressed("P2_light") and rematching[1] == false:
			play_audio("ui_accept", {"vol":-8})
			set_rematch(1)
		if Input.is_action_just_pressed("P2_fierce") and rematching[1] == true:
			play_audio("ui_back", {})
			unset_rematch(1)
	
	if Input.is_action_just_pressed("ui_cancel") and $ReplayMenu/ReplayList.get_focus_owner().get_parent().name == "ReplayList":
		play_audio("ui_back", {})
		$ReplayMenu.hide()
		$VictoryMenu/VictoryList/SaveReplay.initial_focus()
		
	
	var rematch := true
	for x in rematching: # only if all players have rematching = true does the game transit to rematch
		if !x:
			rematch = false
			break
	if rematch:
		$Transition.play("transit_to_rematch")


func menu_ready():
	$AltInputs.active = true
	
func focused(focused_node):
	if focused_node.get_parent().name == "VictoryList":
		$VictoryMenu/Cursor.global_position = Vector2(focused_node.rect_global_position.x - 48, \
				focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
		if focused_node.name != "Rematch":
			unset_rematch(0)
			unset_rematch(1)
	elif focused_node.get_parent().name == "ReplayList":
		$ReplayMenu/Cursor.global_position = Vector2(focused_node.rect_global_position.x - 48, \
				focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"SaveReplay":
				play_audio("ui_accept", {"vol":-8})
				$ReplayMenu.show()
				$ReplayMenu/ReplayList/Rename.initial_focus()
			"ReturnToCharSelect":
				play_audio("ui_accept", {"vol":-8})
				BGM.fade()
				$Transition.play("transit_to_char_select")
			"ReturnToMainMenu":
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_main")
				
			"Save":
				if $ReplayMenu/ReplayList/Rename.is_valid():
					play_audio("ui_accept2", {})
					replay.save_replay($ReplayMenu/ReplayList/Rename/Entry.text)
					$ReplayMenu.hide()
					$VictoryMenu/VictoryList/SaveReplay.initial_focus()
					$VictoryMenu/VictoryList/SaveReplay.disabled = true
					$VictoryMenu/VictoryList/SaveReplay.text = "Replay saved!"
				else:
					play_audio("ui_deny", {"vol" : -9})
			"Cancel":
				play_audio("ui_back", {})
				$ReplayMenu.hide()
				$VictoryMenu/VictoryList/SaveReplay.initial_focus()
			
			
func set_rematch(player_ID):
	rematching[player_ID] = true
	$VictoryMenu/Rematching.get_node("P" + str(player_ID + 1)).modulate.a = 1.0
	
func unset_rematch(player_ID):
	rematching[player_ID] = false
	$VictoryMenu/Rematching.get_node("P" + str(player_ID + 1)).modulate.a = 0.0
			
# ------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
	BGM.fade()
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)

func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)


