extends CanvasModulate

func _ready():
	hide()
	$CanvasLayer/Control.hide()
	$AltInputs.active = false
	
	for node in $CanvasLayer/Control/PauseList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")

func open():
	get_tree().paused = true
	show()
	$CanvasLayer/Control.show()
	$AltInputs.active = true
	$CanvasLayer/Control/PauseList/Resume.initial_focus()
	play_audio("ui_accept2", {"vol":-5})
	
func close(yielding = true):
	hide()
	$CanvasLayer/Control.hide()
	$AltInputs.active = false
	if yielding: # prevent double-firing
		yield(get_tree().create_timer(0.15), "timeout")
	get_tree().paused = false
	Globals.pausing = false
	
func _process(_delta):
	if visible and Input.is_action_just_pressed("ui_cancel"):
		play_audio("ui_back", {})
		close()
		
func focused(focused_node):
	$CanvasLayer/Control/Cursor.global_position = Vector2(focused_node.rect_global_position.x - 48, \
			focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func triggered(triggered_node):
	match triggered_node.name:
		"Resume":
			play_audio("ui_back", {})
			close()
		"ReturnToCharSelect":
			play_audio("ui_accept", {"vol":-8})
			close(false)
			get_node("../Transition").play("transit_to_char_select")
		"ReturnToMainMenu":
			play_audio("ui_accept", {"vol":-8})
			close(false)
			get_node("../Transition").play("transit_to_main")

# ------------------------------------------------------------------------------------------------------------

func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	
