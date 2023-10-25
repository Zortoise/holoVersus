extends Button

const INITIAL_HELD_FRAMES = 10
const HELD_INTERVAL = 4

signal focused(focused_node)
signal triggered(triggered_node)


var sound := true
var selected := false
var resource
var filepath := ""


func _ready():
	add_to_group("has_focus")
	add_to_group("has_trigger")
	modulate.a = 0.7
	unselect()

func initial_focus(): # when loading in
	sound = false
	grab_focus()
	sound = true
	
func load_button(in_resource, in_filepath: String):
	resource = in_resource
	text = resource.data_name
	
	filepath = in_filepath # for easy rename/delete
			
	
func select():
	set("custom_colors/font_color", Color(0.94, 0.94, 0.94))
	set("custom_colors/font_color_focus", Color(0.94, 0.94, 0.94))
	set("custom_colors/font_color_hover", Color(0.94, 0.94, 0.94))
	set("custom_colors/font_color_pressed", Color(0.94, 0.94, 0.94))
	set("custom_fonts/font", load("res://Scenes/Menus/ButtonTypeHSelectB.tres"))
	selected = true
	modulate.a = 1.0

func unselect():
	set("custom_colors/font_color", Color(0.12, 0.12, 0.12))
	set("custom_colors/font_color_focus", Color(0.12, 0.12, 0.12))
	set("custom_colors/font_color_hover", Color(0.12, 0.12, 0.12))
	set("custom_colors/font_color_pressed", Color(0.12, 0.12, 0.12))
	set("custom_fonts/font", load("res://Scenes/Menus/ButtonTypeHSelectA.tres"))
	selected = false
	modulate.a = 0.7

func _on_focus_entered():
	if sound:
		play_audio("ui_move", {"vol":-12})
	emit_signal("focused", self)
	modulate.a = 1.0
	
func _on_focus_exited():
	if !selected:
		modulate.a = 0.7
	
func _on_mouse_entered():
	grab_focus()
	
func _on_pressed():
	emit_signal("triggered", self)
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
