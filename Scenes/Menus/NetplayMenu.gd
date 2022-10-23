extends Node2D


func _ready():
	for node in $NetplayList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$NetplayList.get_node(Globals.net_menu_focus).initial_focus()
	
	var net_game_config = Netplay.load_net_game_config_common() # set up loaded values
	$NetplayList/ProfileName.load_button("Profile Name:", net_game_config.name, $AltInputs, false, $NetplayList/NameRequired/Label)
	$NetplayList/PortNumber.load_button("Port Number:", str(net_game_config.port), $AltInputs, true, $NetplayList/PortRequired/Label)
	

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		play_audio("ui_back", {})
		$Transition.play("transit_to_main")

func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"Host":
				if $NetplayList/ProfileName/Entry.text.length() > 0 and \
						$NetplayList/PortNumber/Entry.text.length() > 0:
					play_audio("ui_accept", {"vol":-8})
					save_config()
					$Transition.play("transit_to_host")
					Globals.net_menu_focus = triggered_node.name
				else:
					play_audio("ui_deny", {"vol" : -9})
			"Search":
				if $NetplayList/ProfileName/Entry.text.length() > 0 and \
						$NetplayList/PortNumber/Entry.text.length() > 0:
					play_audio("ui_accept", {"vol":-8})
					save_config()
					$Transition.play("transit_to_search")
					Globals.net_menu_focus = triggered_node.name
				else:
					play_audio("ui_deny", {"vol" : -9})
			"Return":
				play_audio("ui_back", {})
				$Transition.play("transit_to_main")
			
func save_config():
	Netplay.port_number = int($NetplayList/PortNumber/Entry.text)
	Netplay.profile_name = $NetplayList/ProfileName/Entry.text
	var new_net_game_config = {
			"name" : Netplay.profile_name,
			"port" : Netplay.port_number,
		}
	Netplay.save_net_game_config_common(new_net_game_config)
			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)
	
func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	
