extends Node2D


var rematching := [false, false] # each correspond to a player
var returning_to_char_select := [false, false] # each correspond to a player

var replay


func _ready():
	
	BGM.bgm(BGM.common_music["victory"])
	
	$ReplayMenu.hide()
	
	Netcode.force_game_over_to_opponent(Globals.winner[0]) # just in case opponent is still playing due to rollback issues
	
	Netplay.player_list[Globals.winner[0]].wins += 1 # increment the win count
	$VictoryMenu/ColorRect/WinCounts/P1Profile.text = Netplay.player_list[0].profile_name
	$VictoryMenu/ColorRect/WinCounts/P1Wins.text = str(Netplay.player_list[0].wins)
	$VictoryMenu/ColorRect/WinCounts/P2Profile.text = Netplay.player_list[1].profile_name
	$VictoryMenu/ColorRect/WinCounts/P2Wins.text = str(Netplay.player_list[1].wins)
	
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	$AltInputs2.active = false # only controlled by original player 1, you
	
	# load the winner
	$Control/Winner.text = Netplay.get_profile_name_from_player_id(Globals.winner[0])
	$Control/Character.text = Globals.winner[1]
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
	for player_returning in $VictoryMenu/ReturningToCharSelect.get_children():
		player_returning.modulate.a = 0.0
	
	replay = ResourceLoader.load("res://Scenes/Menus/Replay.gd").new()
	replay.generate_replay()
	
	$ReplayMenu/ReplayList/Rename.load_button("Filename:", replay.data_name, $AltInputs2, 50, \
			$ReplayMenu/ReplayList/InvalidFilename/Label)

func _process(_delta):
	
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
		
	var returning := true
	for x in returning_to_char_select: # only if all players have returning_to_char_select = true does the game transit to char_select_net
		if !x:
			returning = false
			break
	if returning:
		BGM.fade()
		$Transition.play("transit_to_char_select_net")


func menu_ready():
	$AltInputs2.active = true
	
func focused(focused_node):
	if focused_node.get_parent().name == "VictoryList":
		$VictoryMenu/Cursor.global_position = Vector2(focused_node.rect_global_position.x - 48, \
				focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
		if focused_node.name != "Rematch":
			if rematching[Netplay.my_player_id()]:
				rpc("opponent_unset_rematch", Netplay.my_player_id())
		if focused_node.name != "ReturnToCharSelect":
			if returning_to_char_select[Netplay.my_player_id()]:
				rpc("opponent_unset_return_to_char_select", Netplay.my_player_id())
	elif focused_node.get_parent().name == "ReplayList":
		$ReplayMenu/Cursor.global_position = Vector2(focused_node.rect_global_position.x - 48, \
				focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"Rematch":
				if !rematching[Netplay.my_player_id()]:
					rpc("opponent_set_rematch", Netplay.my_player_id())
				else:
					rpc("opponent_unset_rematch", Netplay.my_player_id())
			"SaveReplay":
				play_audio("ui_accept", {"vol":-8})
				$ReplayMenu.show()
				$ReplayMenu/ReplayList/Rename.initial_focus()
			"ReturnToCharSelect":
				if !returning_to_char_select[Netplay.my_player_id()]:
					rpc("opponent_set_return_to_char_select", Netplay.my_player_id())
				else:
					rpc("opponent_unset_return_to_char_select", Netplay.my_player_id())
			"ReturnToNetplayMenu":
				play_audio("ui_accept", {"vol":-8})
				Netplay.stop_hosting_or_searching()
				$Transition.play("transit_to_netplay")
				
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
			
# ----------------------------------------------------------------------------------------------------------------------------------------
	
remote func opponent_set_rematch(player_ID):
	rematching[player_ID] = true
	$VictoryMenu/Rematching.get_node("P" + str(player_ID + 1)).modulate.a = 1.0
	rpc("set_rematch_acknowledged", player_ID)
	
remote func opponent_unset_rematch(player_ID):
	rematching[player_ID] = false
	$VictoryMenu/Rematching.get_node("P" + str(player_ID + 1)).modulate.a = 0.0
	rpc("unset_rematch_acknowledged", player_ID)
	
remote func set_rematch_acknowledged(player_ID):
	if !rematching[player_ID]:
		play_audio("ui_accept", {"vol":-8})
		rematching[player_ID] = true
		$VictoryMenu/Rematching.get_node("P" + str(player_ID + 1)).modulate.a = 1.0
	
remote func unset_rematch_acknowledged(player_ID):
	if rematching[player_ID]:
		play_audio("ui_back", {})
		rematching[player_ID] = false
		$VictoryMenu/Rematching.get_node("P" + str(player_ID + 1)).modulate.a = 0.0
	
# ----------------------------------------------------------------------------------------------------------------------------------------
	
remote func opponent_set_return_to_char_select(player_ID):
	returning_to_char_select[player_ID] = true
	$VictoryMenu/ReturningToCharSelect.get_node("P" + str(player_ID + 1)).modulate.a = 1.0
	rpc("set_return_to_char_select_acknowledged", player_ID)
	
remote func opponent_unset_return_to_char_select(player_ID):
	returning_to_char_select[player_ID] = false
	$VictoryMenu/ReturningToCharSelect.get_node("P" + str(player_ID + 1)).modulate.a = 0.0
	rpc("unset_return_to_char_select_acknowledged", player_ID)
	
remote func set_return_to_char_select_acknowledged(player_ID):
	if !returning_to_char_select[player_ID]:
		play_audio("ui_accept", {"vol":-8})
		returning_to_char_select[player_ID] = true
		$VictoryMenu/ReturningToCharSelect.get_node("P" + str(player_ID + 1)).modulate.a = 1.0
	
remote func unset_return_to_char_select_acknowledged(player_ID):
	if returning_to_char_select[player_ID]:
		play_audio("ui_back", {})
		returning_to_char_select[player_ID] = false
		$VictoryMenu/ReturningToCharSelect.get_node("P" + str(player_ID + 1)).modulate.a = 0.0

# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
	BGM.fade()
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)

func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	
	
func _player_disconnected(_id): # opponent disconnected
	_player_disconnected2()
	
func _server_disconnected():
	_player_disconnected2()
	
func _player_disconnected2(): # opponent disconnected
	play_audio("ui_deny", {"vol" : -9})
	rematching = [false, false]
	$VictoryMenu/Rematching/P1.modulate.a = 0.0
	$VictoryMenu/Rematching/P2.modulate.a = 0.0
	returning_to_char_select = [false, false]
	$VictoryMenu/ReturningToCharSelect/P1.modulate.a = 0.0
	$VictoryMenu/ReturningToCharSelect/P2.modulate.a = 0.0
	
	$VictoryMenu/VictoryList/Rematch.disabled = true
	$VictoryMenu/VictoryList/ReturnToCharSelect.disabled = true
	
	$Disconnect.show()
