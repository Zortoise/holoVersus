extends CanvasModulate

const GGANCHOR_OPTIONS = ["100%", "75%", "50%", "25%", "0%", "Off"]
const REGEN_OPTIONS = ["Off", "On"]
const INPUT_VIEWER_OPTIONS = ["Off", "On"]
const HITBOX_VIEWER_OPTIONS = ["Off", "On"]
const FRAME_VIEWER_OPTIONS = ["Off", "On"]

var last_picked = null

func _ready():
	hide()
	$CanvasLayer.hide()
	$CanvasLayer/Cursor.hide()
	$CanvasLayer/Control.hide()
	$CanvasLayer/TrainingControl.hide()
	$AltInputs.active = false
	
	if !Globals.training_mode:
		for node in $CanvasLayer/Control/PauseList.get_children():
			if node.is_in_group("has_focus"):
				node.connect("focused", self, "focused")
			if node.is_in_group("has_trigger"):
				node.connect("triggered", self, "triggered")
				
		if Globals.survival_level != null:
			$CanvasLayer/Control/PauseList/ReturnToCharSelect.text = "Return to Survival Menu"
	
	else:
		$CanvasLayer/TrainingControl/TrainingList.show()
		$CanvasLayer/TrainingControl/TrainingSettings.hide()
		
		$CanvasLayer/TrainingControl/TrainingList/LoadState.disabled = true
	
		for node in $CanvasLayer/TrainingControl/TrainingList.get_children():
			if node.is_in_group("has_focus"):
				node.connect("focused", self, "focused")
			if node.is_in_group("has_trigger"):
				node.connect("triggered", self, "triggered")
		for node in $CanvasLayer/TrainingControl/TrainingSettings.get_children():
			if node.is_in_group("has_focus"):
				node.connect("focused", self, "focused")
			if node.is_in_group("has_trigger"):
				node.connect("triggered", self, "triggered")
		
		var training_settings = Settings.load_training_settings() # set up loaded values
		$CanvasLayer/TrainingControl/TrainingSettings/GuardGaugeAnchor.load_button("Guard Gauge Anchor", \
				GGANCHOR_OPTIONS, training_settings.gganchor)
		$CanvasLayer/TrainingControl/TrainingSettings/Regeneration.load_button("Regeneration", \
				REGEN_OPTIONS, training_settings.regen)
		$CanvasLayer/TrainingControl/TrainingSettings/InputViewer.load_button("Input Viewer", \
				INPUT_VIEWER_OPTIONS, training_settings.input_viewer)
		$CanvasLayer/TrainingControl/TrainingSettings/HitboxViewer.load_button("Hitbox Viewer", \
				HITBOX_VIEWER_OPTIONS, training_settings.hitbox_viewer)
		$CanvasLayer/TrainingControl/TrainingSettings/FrameDataViewer.load_button("Frame Data Viewer", \
				FRAME_VIEWER_OPTIONS, training_settings.frame_viewer)
		set_training_settings()

func set_training_settings():
	Globals.training_settings.gganchor = $CanvasLayer/TrainingControl/TrainingSettings/GuardGaugeAnchor.option_pointer
	Globals.training_settings.regen = $CanvasLayer/TrainingControl/TrainingSettings/Regeneration.option_pointer
	Globals.training_settings.input_viewer = $CanvasLayer/TrainingControl/TrainingSettings/InputViewer.option_pointer
	Globals.training_settings.hitbox_viewer = $CanvasLayer/TrainingControl/TrainingSettings/HitboxViewer.option_pointer
	Globals.training_settings.frame_viewer = $CanvasLayer/TrainingControl/TrainingSettings/FrameDataViewer.option_pointer

func open():
	get_tree().paused = true
	show()
	$CanvasLayer.show()
	$AltInputs.active = true
	get_parent().play_audio("ui_accept2", {})
	
	$CanvasLayer/Cursor.show()
	if !Globals.training_mode:
		$CanvasLayer/Control.show()
		$CanvasLayer/Control/PauseList/Resume.initial_focus()
	else:
		$CanvasLayer/TrainingControl.show()
		$CanvasLayer/TrainingControl/TrainingList.show()
		$CanvasLayer/TrainingControl/TrainingSettings.hide()
		if last_picked == null:
			$CanvasLayer/TrainingControl/TrainingList/Resume.initial_focus()
		else:
			last_picked.initial_focus()
	
func close(yielding = true):
	hide()
	$CanvasLayer.hide()
	$CanvasLayer/Cursor.hide()
	if !Globals.training_mode:
		$CanvasLayer/Control.hide()
	else:
		$CanvasLayer/TrainingControl.hide()
	$AltInputs.active = false
	if yielding: # prevent double-firing
		yield(get_tree().create_timer(0.15), "timeout")
	get_tree().paused = false
	Globals.pausing = false
	
func _process(_delta):
	if visible and Input.is_action_just_pressed("ui_cancel"):
		if $CanvasLayer/TrainingControl/TrainingSettings.visible:
			get_parent().play_audio("ui_accept2", {})
			$CanvasLayer/TrainingControl/TrainingList.show()
			$CanvasLayer/TrainingControl/TrainingSettings.hide()
			$CanvasLayer/TrainingControl/TrainingList/TrainingSettings.initial_focus()
			last_picked = $CanvasLayer/TrainingControl/TrainingList/TrainingSettings
			set_training_settings()
		else:
			get_parent().play_audio("ui_back", {})
			close()
		
func focused(focused_node):
	$CanvasLayer/Cursor.global_position = Vector2(focused_node.rect_global_position.x - 48, \
			focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func triggered(triggered_node):
	last_picked = triggered_node
	
	match triggered_node.name:
		"Resume":
			get_parent().play_audio("ui_back", {})
			close()
		"ReturnToCharSelect":
			get_parent().play_audio("ui_accept", {"vol":-8})
			close(false)
			if Globals.survival_level != null:
				get_node("../Transition").play("transit_to_survival")
			elif !Globals.training_mode:
				get_node("../Transition").play("transit_to_char_select")
			else:
				get_node("../Transition").play("transit_to_char_select_training")
		"ReturnToMainMenu":
			get_parent().play_audio("ui_accept", {"vol":-8})
			close(false)
			get_node("../Transition").play("transit_to_main")
			
		"LoadState":
			get_parent().play_audio("ui_accept", {"vol":-8})
			close()
			if Globals.Game.playback_mode == false:
				if Globals.Game.training_save_state != null:
					Globals.Game.load_state(Globals.Game.training_save_state, false)
					Globals.Game.true_frametime = Globals.Game.frametime
					Globals.Game.match_input_log.set_end_frametime(Globals.Game.frametime)
					Globals.Game.emit_signal("loaded_state") # to tell text to show message
				else:
					print("Error: Saved game state not found")
		"SaveState":
			get_parent().play_audio("ui_accept", {"vol":-8})
			close()
			Globals.Game.save_state("training_save_state")
			Globals.Game.emit_signal("saved_state") 
			$CanvasLayer/TrainingControl/TrainingList/LoadState.disabled = false
		"SwapControls":
			get_parent().play_audio("ui_accept", {"vol":-8})
			close()
			var player_1 = Globals.Game.get_player_node(0)
			var player_2 = Globals.Game.get_player_node(1)
			
			if player_1.player_ID == 0: player_1.set_player_id(1)
			elif player_1.player_ID == 1: player_1.set_player_id(0)
			
			if player_2.player_ID == 0: player_2.set_player_id(1)
			elif player_2.player_ID == 1: player_2.set_player_id(0)
		"TrainingSettings":
			get_parent().play_audio("ui_accept", {"vol":-8})
			$CanvasLayer/TrainingControl/TrainingList.hide()
			$CanvasLayer/TrainingControl/TrainingSettings.show()
			$CanvasLayer/TrainingControl/TrainingSettings/GuardGaugeAnchor.initial_focus()
		"Return":
			get_parent().play_audio("ui_accept", {"vol":-8})
			$CanvasLayer/TrainingControl/TrainingList.show()
			$CanvasLayer/TrainingControl/TrainingSettings.hide()
			$CanvasLayer/TrainingControl/TrainingList/TrainingSettings.initial_focus()
			last_picked = $CanvasLayer/TrainingControl/TrainingList/TrainingSettings
			set_training_settings()

# ------------------------------------------------------------------------------------------------------------

#func play_audio(audio_ref, aux_data):
#	var new_audio = Loader.loaded_ui_audio_scene.instance()
#	get_tree().get_root().add_child(new_audio)
#	new_audio.init(audio_ref, aux_data)
	
