extends Node

const INITIAL_HELD_FRAMES = 10
const HELD_INTERVAL = 4

var P2_dir := Vector2.ZERO


func _physics_process(_delta):
	
	P2_dir = Vector2.ZERO
	if Input.is_action_just_pressed("P2_left"):
		P2_dir.x -= 1
		$Left.start()
	if Input.is_action_pressed("P2_left") and $Left.time > INITIAL_HELD_FRAMES and posmod($Left.time, HELD_INTERVAL) == 0:
		P2_dir.x -= 1
	if Input.is_action_just_released("P2_left"):
		$Left.stop()
		
	if Input.is_action_just_pressed("P2_right"):
		P2_dir.x += 1
		$Right.start()
	if Input.is_action_pressed("P2_right") and $Right.time > INITIAL_HELD_FRAMES and posmod($Right.time, HELD_INTERVAL) == 0:
		P2_dir.x += 1
	if Input.is_action_just_released("P2_right"):
		$Right.stop()
		
	if Input.is_action_just_pressed("P2_up"):
		P2_dir.y -= 1
		$Up.start()
	if Input.is_action_pressed("P2_up") and $Up.time > INITIAL_HELD_FRAMES and posmod($Up.time, HELD_INTERVAL) == 0:
		P2_dir.y -= 1
	if Input.is_action_just_released("P2_up"):
		$Up.stop()
		
	if Input.is_action_just_pressed("P2_down"):
		P2_dir.y += 1
		$Down.start()
	if Input.is_action_pressed("P2_down") and $Down.time > INITIAL_HELD_FRAMES and posmod($Down.time, HELD_INTERVAL) == 0:
		P2_dir.y += 1
	if Input.is_action_just_released("P2_down"):
		$Down.stop()
