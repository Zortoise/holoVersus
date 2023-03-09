extends HBoxContainer

signal focused(focused_node)

var loaded_options := []
var option_pointer := 0

var sound := true
var disabled := false

var red_text_node # allow easy editing of the red text below the LineEdit
var alt_inputs_node # for easy disabling

var initial_activation := false # allow initial_focus() without triggering $Entry.grab_focus()

func _ready():
	add_to_group("has_focus")

func disable():
	disabled = true
	modulate.a = 0.5

func initial_focus(): # when loading in
	initial_activation = true
	sound = false
	grab_focus()
	sound = true
	
func load_button(button_text: String, loaded_entry: String, in_alt_inputs_node, in_max_length = null, in_red_text_node = null):
	# called this at start to load in options
	
	if in_max_length != null:
		$Entry.max_length = in_max_length
	
	$Button.text = button_text
	$Entry.text = loaded_entry
	alt_inputs_node = in_alt_inputs_node

		
	red_text_node = in_red_text_node
	red_text()
	
		
	
func red_text():
	if red_text_node != null:
		if !test_name():
			red_text_node.show()
		else:
			red_text_node.hide()
			
func test_name():
	if $Entry.text.length() == 0:
		return false
	if $Entry.text.is_valid_filename():
		return true
	else: return false
	
	
func _process(_delta): # manual triggering, as this is not a button node
	if Input.is_action_just_pressed("ui_accept") and has_focus() and !initial_activation:
		$Entry.grab_focus()
		$Entry.caret_position = $Entry.text.length()
	initial_activation = false

	
func remove_spaces_and_dots():
	while $Entry.text.begins_with(" "):
		$Entry.text = $Entry.text.trim_prefix(" ")
	while $Entry.text.ends_with(" ") or $Entry.text.ends_with("."):
		$Entry.text = $Entry.text.trim_suffix(" ")
		$Entry.text = $Entry.text.trim_suffix(".")
	
	
	
func is_valid(): # called by main node
	remove_spaces_and_dots()
	return test_name()
	
	
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
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)



func _on_Entry_text_entered(_new_text):
	play_audio("ui_accept2", {"vol":-5})
	initial_focus()
	remove_spaces_and_dots()
	red_text()

func _on_Entry_text_changed(_new_text):
	red_text()

func _on_Entry_focus_entered():
	alt_inputs_node.active = false
	play_audio("ui_accept", {"vol":-8})

func _on_Entry_focus_exited():
	alt_inputs_node.active = true
	remove_spaces_and_dots()
	red_text()

func _on_Entry_mouse_entered():
	grab_focus()
