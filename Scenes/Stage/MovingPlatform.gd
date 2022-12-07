extends Path2D


onready var box = $PathFollow2D/SoftPlatform

	
# move all movable entities on it too, no momentum, called by script extending this
func move_platform():
	# in_unit_offset is float between 0.0 and 1.0 for moving platform, bool for vanishing platform
	
	var unit_offset = call("movement_pattern")
	
	if !unit_offset is bool: # actual moving platform
		# get all riding entities
		var rider_boxes = []
		# get collision boxes of all grounded entities
		var character_boxes = get_tree().get_nodes_in_group("Grounded")
		for character_box in character_boxes:
			if is_riding(character_box): # check if riding
				rider_boxes.append(character_box)
		
		var old_position = $PathFollow2D.position # store old position
		$PathFollow2D.unit_offset = unit_offset # change offset
		$PathFollow2D.position.x = round($PathFollow2D.position.x) # round position into integer or hell awaits
		$PathFollow2D.position.y = round($PathFollow2D.position.y)
		var position_change = $PathFollow2D.position - old_position # use new position to calculate position_change vector
		
		# apply position_change vector to all riding entities
		for rider_box in rider_boxes:
			if rider_box.is_in_group("Players") or rider_box.is_in_group("Entities"):
				 # rider is player character
				# position_change need to be in integer!'
				var rider = rider_box.get_parent()
				rider.move_amount(position_change, rider_box, rider.get_node("SoftPlatformDBox"), Vector2.ZERO)
				# no need the velocity, grounded Entities always have SoftPlatformDBox
			else:
				rider_box.get_parent().position += position_change # for most other grounded entities, don't need to check for collision
						
	else: # vanishing platform
		
#		var old_position = $PathFollow2D.position # store old position
		if unit_offset:
			$PathFollow2D.unit_offset = 0.0
		elif !unit_offset:
			$PathFollow2D.unit_offset = 1.0
		$PathFollow2D.position.x = round($PathFollow2D.position.x)
		$PathFollow2D.position.y = round($PathFollow2D.position.y)

					
func is_riding(character_box):
			
# warning-ignore:unassigned_variable
	var my_box: Rect2
	my_box.position = box.rect_global_position
	my_box.size = box.rect_size
	
# warning-ignore:unassigned_variable
	var target_box: Rect2
	target_box.position = character_box.rect_global_position
	target_box.size = character_box.rect_size
	
	if my_box.intersects(target_box): # if already overlapping
		return false
	
	target_box.position += Vector2.DOWN # offset target box down 1 pixel
	
	if my_box.intersects(target_box): # if overlapping after offsetting while not already overlapping
		return true
	else:
		return false
		
# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"offset" : $PathFollow2D.unit_offset, # calculating it again from movement_pattern() can cause issues
	}
	return state_data

func load_state(stage_state_data): # move platform without moving riders
	$PathFollow2D.unit_offset = stage_state_data[name].offset # change offset to loaded one
	$PathFollow2D.position.x = round($PathFollow2D.position.x)
	$PathFollow2D.position.y = round($PathFollow2D.position.y)
	
#	var loaded_unit_offset = call("movement_pattern") # calculate with script extending this
#
#	$PathFollow2D.unit_offset = loaded_unit_offset # change offset to loaded one
#	$PathFollow2D.position.x = round($PathFollow2D.position.x)
#	$PathFollow2D.position.y = round($PathFollow2D.position.y)

