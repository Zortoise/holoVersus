extends Node2D

var searching := false

func _ready():
	
	BGM.play_common("TitleThemes")
	
	for node in $SearchList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$SearchList/Search.initial_focus()
	
# warning-ignore:return_value_discarded
	$SearchList/IPOfHost/Entry.connect("text_changed", self, "_on_Entry_text_changed")
	$SearchList/IPOfHost/Entry.secret = true
	
	var net_game_config = Netplay.load_net_game_config_guest() # set up loaded values
	$SearchList/IPOfHost.load_button("Host's IP:", net_game_config.host_ip, $AltInputs, false, $SearchList/IPRequired/Label)

	$Background/Grid/Port2.text = str(Netplay.port_number)
	
# warning-ignore:return_value_discarded
	Netplay.connect("update_player_list", self, "_on_update_player_list")
	
	
func _on_update_player_list(): # received filled player list from host, join lobby
	$Transition.play("transit_to_join")
	

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if searching:
			searching = false
			play_audio("ui_back", {})
			$Searching/AnimationPlayer.play("RESET")
			Netplay.stop_hosting_or_searching()
		else:
			play_audio("ui_back", {})
			$Transition.play("transit_to_netplay")
			Netplay.stop_hosting_or_searching()

func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"Paste":
				play_audio("ui_accept", {"vol":-8})
				$SearchList/IPOfHost/Entry.text = OS.get_clipboard()
				if searching:
					searching = false
					$Searching/AnimationPlayer.play("RESET")
			"Search":
				if $SearchList/IPOfHost/Entry.text.length() == 0:
					play_audio("ui_deny", {"vol" : -9})
				else:
					if !searching:
						searching = true
						play_audio("ui_accept", {"vol":-8})
						var new_net_game_config = {
							"host_ip" : $SearchList/IPOfHost/Entry.text,
						}
						Netplay.save_net_game_config_guest(new_net_game_config)
						$Searching/AnimationPlayer.play("fading")
						Netplay.start_searching($SearchList/IPOfHost/Entry.text)
					else:
						searching = false
						play_audio("ui_back", {})
						$Searching/AnimationPlayer.play("RESET")
						Netplay.stop_hosting_or_searching()
			"Return":
				searching = false
				play_audio("ui_back", {})
				$Transition.play("transit_to_netplay")
				Netplay.stop_hosting_or_searching()
			
func _on_Entry_text_changed(_new_text): # stop searching if text is changed
		if searching:
			searching = false
			$Searching/AnimationPlayer.play("RESET")
			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
	Globals.next_scene = new_scene
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/LoadingScreen.tscn")
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	
