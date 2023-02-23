extends Node2D


func _ready():
	
	$AltInputs.active = false
	

	# load the winner
	$P1_FullArt.texture = ResourceLoader.load("res://Characters/" + Globals.P1_char_ref + "/UI/full_art.png")
	$Background/Triangle.modulate = Color(0.73, 0.19, 0.27)
	
	if Globals.player_count == 2:
		$P2_FullArt.texture = ResourceLoader.load("res://Characters/" + Globals.P2_char_ref + "/UI/full_art.png")
		$Background/Triangle2.modulate = Color(0.22, 0.48, 0.82)
	else:
		$P2_FullArt.hide()
		$Background/Triangle2.modulate = Color(0.73, 0.19, 0.27)

	
	for node in $VictoryMenu/VictoryList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$VictoryMenu/VictoryList/ReturnToSurvival.initial_focus()
	

func menu_ready():
	$AltInputs.active = true
	
func focused(focused_node):
	$VictoryMenu/Cursor.global_position = Vector2(focused_node.rect_global_position.x - 48, \
			focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)


func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"ReturnToSurvival":
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_survival")
			"ReturnToMainMenu":
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_main_menu")
			
			
# ------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)

func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)


