extends HBoxContainer

signal focused(focused_node)

var loaded_options := []
var option_pointer := 0

var sound := true
var disabled := false

var red_text_node # allow easy editing of the red text below the LineEdit
var alt_inputs_node # for easy disabling
var numbers_only := false

func _ready():
	add_to_group("has_focus")

func disable():
	disabled = true
	modulate.a = 0.5

func initial_focus(): # when loading in
	sound = false
	grab_focus()
	sound = true
	
func load_button(button_text: String, loaded_entry: String, in_alt_inputs_node, in_numbers_only = false, \
		in_red_text_node = null):
	# called this at start to load in options
	
	$Button.text = button_text
	$Entry.text = loaded_entry
	alt_inputs_node = in_alt_inputs_node
	numbers_only = in_numbers_only
	
	if numbers_only:
		$Entry.max_length = 5
		
	red_text_node = in_red_text_node
	red_text()
	
		
	
func red_text():
	if red_text_node != null:
		if $Entry.text.length() == 0:
			red_text_node.show()
		else:
			red_text_node.hide()
	
func _process(_delta): # manual triggering, as this is not a button node
	if Input.is_action_just_pressed("ui_accept") and has_focus():
		$Entry.grab_focus()
		$Entry.caret_position = $Entry.text.length()

	
func _on_focus_entered():
	if sound:
		play_audio("ui_move", {"vol":-12})
	emit_signal("focused", self)
	if !disabled:
		$Button.modulate = Color(1.5, 1.5, 1.5)
	
func _on_focus_exited():
	if !disabled:
		$Button.modulate = Color(1.0, 1.0, 1.0)
	
func _on_mouse_entered():
	grab_focus()
	
func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)



func _on_Entry_text_entered(new_text):
	play_audio("ui_accept2", {"vol":-5})
	initial_focus()
	if numbers_only:
		$Entry.text = str(int(new_text))
		red_text()

func _on_Entry_text_changed(_new_text):
	red_text()

func _on_Entry_focus_entered():
	alt_inputs_node.active = false
	play_audio("ui_accept", {"vol":-8})

func _on_Entry_focus_exited():
	alt_inputs_node.active = true
	if numbers_only:
		$Entry.text = str(int($Entry.text))
		red_text()

func _on_Entry_mouse_entered():
	grab_focus()
