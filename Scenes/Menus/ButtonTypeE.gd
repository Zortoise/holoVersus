extends HBoxContainer

signal focused(focused_node)
signal triggered(triggered_node)

var mapping: String

var time := 0.0

var sound := true

var input_lock_first_frame := false # when using initial_focus(), lock 1st frame to prevent double firing

func _ready():
	add_to_group("has_focus")
	add_to_group("has_trigger")

func initial_focus(): # when swapping to sub menu
	sound = false
	input_lock_first_frame = true
	grab_focus()
	sound = true
	
func load_button(button_text: String, initial_mapping: String): # called this at start to load in options
	$Button.text = button_text
	mapping = initial_mapping
	$Button2.text = mapping
	
func map(new_mapping):
	mapping = new_mapping
	$Button2.text = mapping
	
func _process(_delta): # manual triggering, as this is not a button node
	if Input.is_action_just_pressed("ui_accept") and has_focus() and !input_lock_first_frame:
		emit_signal("triggered", self)
	elif input_lock_first_frame: input_lock_first_frame = false
	
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

