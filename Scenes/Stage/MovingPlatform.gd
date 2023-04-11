extends Node2D


onready var box = $MPlatform/SoftPlatform

	
# move all movable entities on it too, no momentum, called by script extending this
func move_platform():
	# in_unit_offset is float between 0.0 and 1.0 for moving platform, bool for vanishing platform
	
	var new_position: Vector2 = call("movement_pattern")
	
	if get("TYPE") == Em.moving_platform.MOVING: # actual moving platform
		# get all riding entities
		var rider_boxes = []
		# get collision boxes of all grounded entities
		var collision_boxes = get_tree().get_nodes_in_group("Grounded")
		for collision_box in collision_boxes:
			if Detection.is_riding(box, collision_box): # check if riding
				rider_boxes.append(collision_box)
		
		var old_position = $MPlatform.position # store old position
		$MPlatform.position = new_position # move platform
		var position_change: Vector2 = new_position - old_position # use new position to calculate position_change vector
		
		# apply position_change vector to all riding entities
		for rider_box in rider_boxes:
			if rider_box.is_in_group("Players") or rider_box.is_in_group("Mobs") or rider_box.is_in_group("Entities"):
				 # rider is player character/grounded entity
				# position_change need to be in integer!'
				var rider = rider_box.get_parent()
				rider.move_amount(position_change)
				if rider.has_method("set_true_position"):
					rider.call("set_true_position")
				# no need the velocity, grounded Entities always have SoftPlatformDBox
			else:
				rider_box.get_parent().position += position_change # for grounded sfx, don't need to check for collision
						
	elif get("TYPE") == Em.moving_platform.WARPING: # teleporting platform, vanishing platforms just warp offstage
		$MPlatform.position = new_position # move platform


					
#func is_riding(platform_box, character_box):
#
#	var my_box := Rect2(platform_box.rect_global_position, platform_box.rect_size)
#	var target_box := Rect2 (character_box.rect_global_position, character_box.rect_size)
#
#	if my_box.intersects(target_box): # if already overlapping
#		return false
#
#	target_box.position += Vector2.DOWN # offset target box down 1 pixel
#
#	if my_box.intersects(target_box): # if overlapping after offsetting while not already overlapping
#		return true
#	else:
#		return false
		
# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

#func load_state():
#	$MPlatform.position = call("movement_pattern")

func save_state():
	var state_data = {
		"position" : $MPlatform.position, # must save and not recalculate, or could cause desync
	}
	return state_data

func load_state(stage_state_data): # move platform without moving riders
	$MPlatform.position = stage_state_data[name].position
	

