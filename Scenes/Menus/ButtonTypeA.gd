extends Button


signal focused(focused_node)
signal triggered(triggered_node)

var sound := true

func _ready():
	add_to_group("has_focus")
	add_to_group("has_trigger")

func initial_focus(): # when loading in
	sound = false
	grab_focus()
	sound = true

func _on_focus_entered():
	if sound:
		play_audio("ui_move", {"vol":-12})
	emit_signal("focused", self)
	modulate = Color(1.5, 1.5, 1.5)
	
func _on_focus_exited():
	modulate = Color(1.0, 1.0, 1.0)
	
func _on_mouse_entered():
	grab_focus()
	
func _on_pressed():
	emit_signal("triggered", self)
	
func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
