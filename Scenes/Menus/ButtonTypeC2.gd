extends HBoxContainer

signal focused(focused_node)
signal shifted(shifted_node)

const INITIAL_HELD_FRAMES = 10
const HELD_INTERVAL = 4

var loaded_options := []
var option_pointer := 0

var sound := true
var disabled := false

func _ready():
	add_to_group("has_focus")
	
func disable():
	disabled = true
	modulate.a = 0.5

func initial_focus(): # when loading in
	sound = false
	grab_focus()
	sound = true
	
func load_button(button_text: String, in_loaded_options: Array, initial_pointer = 0): # called this at start to load in options
	$Button.text = button_text
	loaded_options = in_loaded_options
	option_pointer = initial_pointer
	$Selection.text = str(loaded_options[option_pointer])
	
func change_pointer(new_pointer):
	option_pointer = new_pointer
	$Selection.text = str(loaded_options[new_pointer])
		
func _physics_process(_delta):
	if has_focus():
		
		var dir = 0
		
		if Input.is_action_just_pressed("ui_left"):
			dir -= 1
			$Left.start()
		if !(Input.is_action_pressed("ui_left") or $PickerArrowL.pressed):
			$Left.stop()
			
		if Input.is_action_just_pressed("ui_right"):
			dir += 1
			$Right.start()
		if !(Input.is_action_pressed("ui_right") or $PickerArrowR.pressed):
			$Right.stop()
			
		if (Input.is_action_pressed("ui_left") or $PickerArrowL.pressed) and $Left.time > INITIAL_HELD_FRAMES and \
				posmod($Left.time, HELD_INTERVAL) == 0:
			dir -= 1
		if (Input.is_action_pressed("ui_right") or $PickerArrowR.pressed) and $Right.time > INITIAL_HELD_FRAMES and \
				posmod($Right.time, HELD_INTERVAL) == 0:
			dir += 1
			
		if dir != 0:
			shift_selection(dir)
			

func _on_PickerArrowL_pressed():
	shift_selection(-1)
	$Left.start()
func _on_PickerArrowR_pressed():
	shift_selection(1)
	$Right.start()

func shift_selection(dir):
	if !disabled:
		option_pointer = wrapi(option_pointer + dir, 0, loaded_options.size())
		$Selection.text = str(loaded_options[option_pointer])
		play_audio("ui_move2", {"vol":-8})
		emit_signal("shifted", self)
	
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
	
	
func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)

