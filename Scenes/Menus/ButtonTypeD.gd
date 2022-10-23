extends HBoxContainer

signal focused(focused_node)

var value

var time := 0.0

var sound := true
var disabled := false

func _ready():
	add_to_group("has_focus")

func disable():
	disabled = true
	$SliderBar/Slider.editable = false
	modulate.a = 0.5

func initial_focus(): # when loading in
	sound = false
	grab_focus()
	sound = true
	
func load_button(button_text: String, initial_value = 70): # called this at start to load in options
	$Button.text = button_text
	value = initial_value
	$SliderBar/Slider.value = value
	$SliderBar.value = value
	
func _process(delta): # move slider left/right
	time += delta
	var dir = 0
	if Input.is_action_pressed("ui_left"):
		dir -= 1
	if Input.is_action_pressed("ui_right"):
		dir += 1
	if dir != 0 and time > 0.1: # one input every 0.1 sec
		time = 0
		if has_focus() and !disabled:
			value += dir * 5
			$SliderBar/Slider.value = value
			$SliderBar.value = value
	
	
func _on_focus_entered():
	if sound:
		play_audio("ui_move", {"vol":-12})
	emit_signal("focused", self)
	if !disabled:
		modulate = Color(1.5, 1.5, 1.5)
	
func _on_focus_exited():
	if !disabled:
		modulate = Color(1.0, 1.0, 1.0)
	
func _on_mouse_entered():
	grab_focus()

func _on_Slider_value_changed(_value):
	value = $SliderBar/Slider.value
	$SliderBar.value = value

	
func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)

