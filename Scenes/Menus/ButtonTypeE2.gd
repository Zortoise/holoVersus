extends HBoxContainer

# used for Button Check!

var mapping: String
	
func load_button(button_text: String, initial_mapping: String): # called this at start to load in options
	$Label.text = button_text
	mapping = initial_mapping
	$Label2.text = mapping


