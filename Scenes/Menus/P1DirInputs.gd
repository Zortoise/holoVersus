extends Node

const INITIAL_HELD_FRAMES = 10
const HELD_INTERVAL = 4

var P1_dir := Vector2.ZERO


func _physics_process(_delta):
	
	P1_dir = Vector2.ZERO
	if Input.is_action_just_pressed("P1_left"):
		P1_dir.x -= 1
		$Left.start()
	if Input.is_action_pressed("P1_left") and $Left.time > INITIAL_HELD_FRAMES and posmod($Left.time, HELD_INTERVAL) == 0:
		P1_dir.x -= 1
	if Input.is_action_just_released("P1_left"):
		$Left.stop()
		
	if Input.is_action_just_pressed("P1_right"):
		P1_dir.x += 1
		$Right.start()
	if Input.is_action_pressed("P1_right") and $Right.time > INITIAL_HELD_FRAMES and posmod($Right.time, HELD_INTERVAL) == 0:
		P1_dir.x += 1
	if Input.is_action_just_released("P1_right"):
		$Right.stop()
		
	if Input.is_action_just_pressed("P1_up"):
		P1_dir.y -= 1
		$Up.start()
	if Input.is_action_pressed("P1_up") and $Up.time > INITIAL_HELD_FRAMES and posmod($Up.time, HELD_INTERVAL) == 0:
		P1_dir.y -= 1
	if Input.is_action_just_released("P1_up"):
		$Up.stop()
		
	if Input.is_action_just_pressed("P1_down"):
		P1_dir.y += 1
		$Down.start()
	if Input.is_action_pressed("P1_down") and $Down.time > INITIAL_HELD_FRAMES and posmod($Down.time, HELD_INTERVAL) == 0:
		P1_dir.y += 1
	if Input.is_action_just_released("P1_down"):
		$Down.stop()
