extends Node2D

func _ready():
	BGM.bgm(BGM.common_music["title_theme"])
	
	$Background/Title/Version.text = Globals.VERSION
	
	if Globals.startup:
		$Transition.play("start_transit_in")
		Globals.startup = false
	
	for node in $MainMenuList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$MainMenuList.get_node(Globals.main_menu_focus).initial_focus()

	
func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)
	
func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"Survival":
				Globals.main_menu_focus = triggered_node.name
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_survival")
			"Local":
				Globals.main_menu_focus = triggered_node.name
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_local")
			"Netplay":
				Globals.main_menu_focus = triggered_node.name
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_netplay")
			"Training":
				Globals.main_menu_focus = triggered_node.name
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_training")
			"Settings":
				Globals.main_menu_focus = triggered_node.name
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_settings")
			"Controls":
				Globals.main_menu_focus = triggered_node.name
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_controls")
			"Quit":
				get_tree().quit()
	
func change_scene(new_scene: String): # called by animation
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)


	


