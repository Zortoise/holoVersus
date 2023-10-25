extends Node

const INITIAL_HELD_FRAMES = 10
const HELD_INTERVAL = 4

var active := true

onready var input_event = InputEventAction.new()

func _physics_process(_delta):
	if active:
		if Input.is_action_just_pressed("P1_up"):
			input_event.action = "ui_up"
			input_event.pressed = true
			Input.parse_input_event(input_event)
			$Up.start()
		if Input.is_action_pressed("P1_up") and $Up.time > INITIAL_HELD_FRAMES and \
				posmod($Up.time, HELD_INTERVAL) == 0:
			input_event.action = "ui_up"
			input_event.pressed = true
			Input.parse_input_event(input_event)
		if !Input.is_action_pressed("P1_up"):
			input_event.action = "ui_up"
			input_event.pressed = false
			Input.parse_input_event(input_event)
			$Up.stop()
			
		if Input.is_action_just_pressed("P1_down"):
			input_event.action = "ui_down"
			input_event.pressed = true
			Input.parse_input_event(input_event)
			$Down.start()
		if Input.is_action_pressed("P1_down") and $Down.time > INITIAL_HELD_FRAMES and \
				posmod($Down.time, HELD_INTERVAL) == 0:
			input_event.action = "ui_down"
			input_event.pressed = true
			Input.parse_input_event(input_event)
		if !Input.is_action_pressed("P1_down"):
			input_event.action = "ui_down"
			input_event.pressed = false
			Input.parse_input_event(input_event)
			$Down.stop()
			
		if Input.is_action_just_pressed("P1_left"):
			input_event.action = "ui_left"
			input_event.pressed = true
			Input.parse_input_event(input_event)
			$Left.start()
		if Input.is_action_pressed("P1_left") and $Left.time > INITIAL_HELD_FRAMES and \
				posmod($Left.time, HELD_INTERVAL) == 0:
			input_event.action = "ui_left"
			input_event.pressed = true
			Input.parse_input_event(input_event)
		if !Input.is_action_pressed("P1_left"):
			input_event.action = "ui_left"
			input_event.pressed = false
			Input.parse_input_event(input_event)
			$Left.stop()
			
		if Input.is_action_just_pressed("P1_right"):
			input_event.action = "ui_right"
			input_event.pressed = true
			Input.parse_input_event(input_event)
			$Right.start()
		if Input.is_action_pressed("P1_right") and $Right.time > INITIAL_HELD_FRAMES and \
				posmod($Right.time, HELD_INTERVAL) == 0:
			input_event.action = "ui_right"
			input_event.pressed = true
			Input.parse_input_event(input_event)
		if !Input.is_action_pressed("P1_right"):
			input_event.action = "ui_right"
			input_event.pressed = false
			Input.parse_input_event(input_event)
			$Right.stop()
			
		if Input.is_action_just_pressed("P1_light"):
			input_event.action = "ui_accept"
			input_event.pressed = true
			Input.parse_input_event(input_event)
		if !Input.is_action_pressed("P1_light"):
			input_event.action = "ui_accept"
			input_event.pressed = false
			Input.parse_input_event(input_event)
			
		if Input.is_action_just_pressed("P1_fierce"):
			input_event.action = "ui_cancel"
			input_event.pressed = true
			Input.parse_input_event(input_event)
		if !Input.is_action_pressed("P1_fierce"):
			input_event.action = "ui_cancel"
			input_event.pressed = false
			Input.parse_input_event(input_event)
