extends Control


var P1_phase := 0 # 0 is picking cards, 1 is leaving shop and waiting for partner
var P1_picker_pos := [0, 1]
var P1_held_timer := 0

var P2_phase := 0
var P2_picker_pos := [0, 3]
var P2_held_timer := 0

onready var loaded_card_scene := load("res://Scenes/Survival/Card.tscn") # placeholder

#func _ready():
#	Inventory.stock_pool()
#	open_shop()

func open_shop():
	reset()
	Inventory.open_shop()
	load_cards()
	blank_description(0)
	blank_description(1)
	$AnimationPlayer.play("open")
	

func load_cards(): # load all cards in shop and hands of both players
	for x in 5:
#		var new_card = Globals.Game.LevelControl.loaded_card_scene.instance()
		var new_card = loaded_card_scene.instance()
		new_card.init(Inventory.shop[x])
		$Shop.get_node("Card" + str(x + 1)).add_child(new_card)
		
	for x in Inventory.inventory[0].size():
		var new_card = loaded_card_scene.instance()
		new_card.init(Inventory.inventory[0][x], true)
		$P1/Hand.get_node("Card" + str(x + 1)).add_child(new_card)
		
	if Globals.player_count > 1:
		for x in Inventory.inventory[1].size():
			var new_card = loaded_card_scene.instance()
			new_card.init(Inventory.inventory[1][x], true)
			$P2/Hand.get_node("Card" + str(x + 1)).add_child(new_card)

func reset(): # reset pickers at the start
	P1_phase = 0
	
	if Globals.player_count == 1:
		P1_picker_pos = [0, 2]
	else:
		P2_phase = 0
		P1_picker_pos = [0, 1]
		P2_picker_pos = [0, 3]
		
		
func update_pickers(): # called by AnimationPlayer when pickers are to appear
	P1_changed_card(false)
	P2_changed_card(false)


func clear_cards(): # called by AnimationPlayer after closing animation is over
	for node in $Shop:
		node.get_child(0).queue_free()
		
	for node in $P1/Hand:
		node.get_child(0).queue_free()
		
	if Globals.player_count > 1:
		for node in $P2/Hand:
			node.get_child(0).queue_free()
	
		

func _physics_process(_delta):
	if visible:
		
		# directional keys
		var P1_dir = $P1DirInputs.P1_dir
		var P2_dir = $P2DirInputs.P2_dir
		
		move_pickers(P1_dir, P2_dir)
	
		$P1/Box/ProgressBar.value = P1_held_timer
		if P1_held_timer > 0 and $P1/Box/Action/AnimationPlayer.current_animation != "flash":
			$P1/Box/Action/AnimationPlayer.play("flash")
		elif P1_held_timer == 0 and $P1/Box/Action/AnimationPlayer.current_animation != "RESET":
			$P1/Box/Action/AnimationPlayer.play("RESET")

		if P1_picker_pos[0] == 0:
			if Input.is_action_pressed("P1_light"):
				P1_held_timer = int(min(P1_held_timer + 2, 45))
			else:
				P1_held_timer = 0
		elif P1_picker_pos[0] == 1:
			if Input.is_action_pressed("P1_fierce"):
				P1_held_timer = int(min(P1_held_timer + 1, 45))
			else:
				P1_held_timer = 0
			
	
	
		if Input.is_action_just_pressed("P1_light"):
			if P1_phase == 0 and P1_picker_pos[0] == 2:
				P1_phase = 1
		
		if Input.is_action_just_pressed("P1_fierce"):
			if P1_phase == 1:
				P1_phase = 0
				
		if Globals.player_count > 1:
			$P2/Box/ProgressBar.value = P2_held_timer
			if P2_held_timer > 0 and $P2/Box/Action/AnimationPlayer.current_animation != "flash":
				$P2/Box/Action/AnimationPlayer.play("flash")
			elif P1_held_timer == 0 and $P1/Box/Action/AnimationPlayer.current_animation != "RESET":
				$P2/Box/Action/AnimationPlayer.play("RESET")
			
			if P2_picker_pos[0] == 0:
				if Input.is_action_pressed("P2_light"):
					P2_held_timer = int(min(P2_held_timer + 2, 45))
				else:
					P2_held_timer = 0
			elif P2_picker_pos[0] == 1:
				if Input.is_action_pressed("P2_fierce"):
					P2_held_timer = int(min(P2_held_timer + 1, 45))
				else:
					P2_held_timer = 0
			
			
			if Input.is_action_just_pressed("P2_light"):
				if P2_phase == 0 and P2_picker_pos[0] == 2:
					P2_phase = 1
			
			if Input.is_action_just_pressed("P2_fierce"):
				if P2_phase == 1:
					P2_phase = 0
	
	
func move_pickers(P1_dir, P2_dir):
	
	if P1_phase == 0:
		
		if P1_dir.x != 0:
			var orig = P1_picker_pos.duplicate()
			P1_picker_pos[1] += P1_dir.x
			P1_picker_pos[1] = int(clamp(P1_picker_pos[1], 0, get_x_limit(0, P1_picker_pos[0])))
			if P1_picker_pos != orig:
				P1_changed_card()
				# hand card bring to front
				if P1_picker_pos[0] == 1: $P1/Hand.get_child(P1_picker_pos[1]).show_behind_parent = false
				if orig[0] == 1: $P1/Hand.get_child(orig[1]).show_behind_parent = true
				
		if P1_dir.y != 0:
			var orig = P1_picker_pos.duplicate()
			P1_picker_pos[0] += P1_dir.y
			P1_picker_pos[0] = int(clamp(P1_picker_pos[0], 0, 2))
			# if no cards, skip hand level
			if P1_picker_pos[0] == 1 and Inventory.inventory[0].size() == 0:
				P1_picker_pos[0] += P1_dir.y
			if P1_picker_pos != orig:
				match int(P1_picker_pos[0]): # clamp x-coord
					0:
						P1_picker_pos[1] = 0
					1:
						P1_picker_pos[1] = Inventory.inventory[0].size() - 1
					2:
						P1_picker_pos[1] = 0
				P1_changed_card()
				# hand card bring to front
				if P1_picker_pos[0] == 1: $P1/Hand.get_child(P1_picker_pos[1]).show_behind_parent = false
				if orig[0] == 1: $P1/Hand.get_child(orig[1]).show_behind_parent = true
		
		
	if P2_phase == 0:
		
		if P2_dir.x != 0:
			var orig = P2_picker_pos.duplicate()
			if P2_picker_pos[0] == 1: 
				P2_picker_pos[1] -= P2_dir.x # other direction for P2
			else:
				P2_picker_pos[1] += P2_dir.x
			P2_picker_pos[1] = int(clamp(P2_picker_pos[1], 0, get_x_limit(1, P2_picker_pos[0])))
			if P2_picker_pos != orig:
				P2_changed_card()
				# hand card bring to front
				if P2_picker_pos[0] == 1: $P2/Hand.get_child(P2_picker_pos[1]).show_behind_parent = false
				if orig[0] == 1: $P2/Hand.get_child(orig[1]).show_behind_parent = true
				
		if P2_dir.y != 0:
			var orig = P2_picker_pos.duplicate()
			P2_picker_pos[0] += P2_dir.y
			P2_picker_pos[0] = int(clamp(P2_picker_pos[0], 0, 2))
			# if no cards, skip hand level
			if P2_picker_pos[0] == 1 and Inventory.inventory[1].size() == 0:
				P2_picker_pos[0] += P2_dir.y
			if P2_picker_pos != orig:
				match int(P2_picker_pos[0]): # clamp x-coord
					0:
						P2_picker_pos[1] = 4
					1:
						P2_picker_pos[1] = Inventory.inventory[1].size() - 1
					2:
						P2_picker_pos[1] = 0
				P2_changed_card()
				# hand card bring to front
				if P2_picker_pos[0] == 1: $P2/Hand.get_child(P2_picker_pos[1]).show_behind_parent = false
				if orig[0] == 1: $P2/Hand.get_child(orig[1]).show_behind_parent = true
			
			
func P1_changed_card(sound := true): # update card currently being hovered over
	P1_held_timer = 0
	if sound:
		get_parent().play_audio("ui_move2", {"vol":-12})
	$P1/Picker.position = get_position_of_card(0, P1_picker_pos)  # move picker
	
	# update description
	match int(P1_picker_pos[0]):
		0:
			update_description(0, Inventory.shop[int(P1_picker_pos[1])])
		1:
			update_description(0, Inventory.inventory[0][int(P1_picker_pos[1])], false)
		2:
			blank_description(0)
	
	
func P2_changed_card(sound := true): # update card currently being hovered over
	P2_held_timer = 0
	if sound:
		get_parent().play_audio("ui_move2", {"vol":-12})
	$P2/Picker.position = get_position_of_card(1, P2_picker_pos)  # move picker
	
	# update description
	match int(P2_picker_pos[0]):
		0:
			update_description(1, Inventory.shop[int(P2_picker_pos[1])])
		1:
			update_description(1, Inventory.inventory[1][int(P2_picker_pos[1])], false)
		2:
			blank_description(1)
			
	
func update_description(player: int, card_ref: int, shop := true): # update name and description on box
	var box = get_node("P" + str(player + 1) + "/Box")
	box.get_node("Name").text = Cards.DATABASE[card_ref].name
	box.get_node("Type").text = "Type: Enchance"
	box.get_node("Description").text = Inventory.get_describe(card_ref)
	if shop:
		box.get_node("Action").text = "Hold Light to Purchase"
		box.get_node("Action").self_modulate = Color(0.89, 0.81, 0.47)
		box.get_node("ProgressBar").self_modulate = Color(0.89, 0.81, 0.47)
	else:
		box.get_node("Action").text = "Hold Fierce to Discard"
		box.get_node("Action").self_modulate = Color(0.93, 0.29, 0.29)
		box.get_node("ProgressBar").self_modulate = Color(0.93, 0.29, 0.29)
	box.get_node("ProgressBar").show()
	
	
func blank_description(player: int): # for when LEAVE SHOP is hovered over
	var box = get_node("P" + str(player + 1) + "/Box")
	box.get_node("Name").text = ""
	box.get_node("Type").text = ""
	box.get_node("Description").text = ""
	box.get_node("Action").text = ""
	box.get_node("ProgressBar").hide()
	
	
func get_x_limit(player: int, level: int): # to limit horizontal picker movement
	match level:
		0:
			return 4
		1:
			return Inventory.inventory[player].size() - 1
		2:
			return 0

	
func get_position_of_card(player: int, coords: Array): # to move picker to
	match int(coords[0]):
		0:
			return $Shop.get_child(coords[1]).position
		1:
			match player:
				0:
					return $P1/Hand.get_child(coords[1]).position
				1:
					return $P2/Hand.get_child(coords[1]).position
		2:
			match player:
				0:
					return $P1/LeaveSpot.position
				1:
					return $P2/LeaveSpot.position
	
# ------------------------------------------------------------------------------------------------------------

#func play_audio(audio_ref, aux_data):
#	var new_audio = Globals.loaded_ui_audio_scene.instance()
#	get_tree().get_root().add_child(new_audio)
#	new_audio.init(audio_ref, aux_data)
