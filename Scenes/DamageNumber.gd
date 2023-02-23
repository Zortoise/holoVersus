extends Node2D

const MAX_HEIGHT = -50
const FADE_HEIGHT = -40
const RED = Color(1.5, 0.2, 0.2)
const GRAY = Color(0.75, 0.75, 0.75)
const GREEN = Color(0.65, 1.5, 0.65)

var free := false
var number := 0
var color = null

func init(in_number: int, in_position: Vector2, in_color = null):
	number = in_number
	position = in_position
	color = in_color
	$Label.text = str(number)
	match color:
		Globals.dmg_num_col.RED:
			$Label.modulate = RED
		Globals.dmg_num_col.GRAY:
			$Label.modulate = GRAY
		Globals.dmg_num_col.GREEN:
			$Label.modulate = GREEN

func simulate():
	$Label.rect_position.y -= 1
	if $Label.rect_position.y <= MAX_HEIGHT:
		free = true
	elif $Label.rect_position.y < FADE_HEIGHT:
		$Label.modulate.a = (MAX_HEIGHT - $Label.rect_position.y) / float(MAX_HEIGHT - FADE_HEIGHT)

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"free" : free,
		"position" : position,
		"number" : number,
		"color" : color,
		"height" : $Label.rect_position.y,
	}
	return state_data
	
func load_state(state_data):
	free = state_data.free
	position = state_data.position
	number = state_data.number
	color = state_data.color
	$Label.text = str(number)
	$Label.rect_position.y = state_data.height
	match color:
		Globals.dmg_num_col.RED:
			$Label.modulate = RED
		Globals.dmg_num_col.GRAY:
			$Label.modulate = GRAY
		Globals.dmg_num_col.GREEN:
			$Label.modulate = GREEN
	if $Label.rect_position.y < FADE_HEIGHT:
			$Label.modulate.a = (MAX_HEIGHT - $Label.rect_position.y) / float(MAX_HEIGHT - FADE_HEIGHT)
	
#--------------------------------------------------------------------------------------------------
