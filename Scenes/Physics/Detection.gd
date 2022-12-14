extends Node

# autoload, global functions for detecting objects using detect boxes


func detect_duo(box1, box2): # basic testing whether 2 boxes intersect, both are nodes like ColorRect
# warning-ignore:unassigned_variable
	var detect_box: Rect2
	detect_box.position = box1.rect_global_position
	detect_box.size = box1.rect_size
# warning-ignore:unassigned_variable
	var target_box: Rect2
	target_box.position = box2.rect_global_position
	target_box.size = box2.rect_size
	if detect_box.intersects(target_box):
		return true
	else: return false
	

# search for collision boxes in groups_to_comb for boxes that intersect with input boxes
# may be offseted by a unit vector
# return true if found intersected stuff
func detect_bool(box_array: Array, groups_to_comb: Array, offset = Vector2.ZERO):
	for box in box_array:
# warning-ignore:unassigned_variable
		var detect_box: Rect2 # need to do this since need global position
		detect_box.position = box.rect_global_position + offset
		detect_box.size = box.rect_size
		for group_name in groups_to_comb:
			var array = get_tree().get_nodes_in_group(group_name)
			for x in array:
# warning-ignore:unassigned_variable
				var target_box: Rect2 # need to do this since need global position
				target_box.position = x.rect_global_position
				target_box.size = x.rect_size
				if detect_box.intersects(target_box):
					return true
	return false

	
# return array of found intersected stuff, return the parents of the intersected boxes
func detect_return(box_array: Array, groups_to_comb: Array, offset = Vector2.ZERO):
	var bodies = []
	for box in box_array:
# warning-ignore:unassigned_variable
		var detect_box: Rect2 # need to do this since need global position
		detect_box.position = box.rect_global_position + offset
		detect_box.size = box.rect_size
		for group_name in groups_to_comb:
			var array = get_tree().get_nodes_in_group(group_name)
			for x in array:
# warning-ignore:unassigned_variable
				var target_box: Rect2 # need to do this since need global position
				target_box.position = x.rect_global_position
				target_box.size = x.rect_size
				if detect_box.intersects(target_box) and x.get_parent() != box.get_parent() \
						and !x.get_parent() in bodies: # skip box's owner and repeats
					bodies.append(x.get_parent())
	return bodies
	
	
# find a wall at a certain height in a certain direction within a certain range
func wall_finder(global_pos: Vector2, facing, finding_range = 15):
	# create a point
	var point = Vector2(global_pos)
	var wall_array = get_tree().get_nodes_in_group("SolidPlatforms")
	
	for x in finding_range:
		for wall in wall_array:
# warning-ignore:unassigned_variable
			var target_box: Rect2 # need to do this since need global position
			target_box.position = wall.rect_global_position
			target_box.size = wall.rect_size
			if target_box.has_point(point): # wall found
				point.x -= facing
				return point
		point.x += facing
		
	return null # no walls found
	
	
# for offset, +ve x means right, +ve y means down
# for v_bias, 0 = closest to center, 1 = highest, -1 = lowest
# for h_bias, 0 = closest to center, 1 = furthest, -1 = nearest
func ground_finder(global_pos: Vector2, facing, offset: Vector2, detect_size: Vector2, v_bias = 0, h_bias = 0):
	
# warning-ignore:unassigned_variable
	var found_pos: Vector2
	
	# 1st, create a detect box centered at that offset
	var origin = Vector2(global_pos.x + (facing * offset.x), global_pos.y + offset.y)
# warning-ignore:unassigned_variable
	var detect_box: Rect2
	detect_box.position = Vector2(origin.x - round(detect_size.x/2.0), origin.y - round(detect_size.y/2.0))
	detect_box.size = detect_size
	Globals.Game.get_node("PolygonDrawer").extra_boxes.append(detect_box) # draw the box out
	
	# 2nd, get intersecting platform boxes and get the one closest to the vertical level needed
	var found_platform_box
	var best_value
	match v_bias:
		0: best_value = round(detect_box.size.y / 2.0) # for closest, compare distance to center horizontal line of detect box
		1: best_value = detect_box.position.y + detect_box.size.y # for highest, compare highest
		-1: best_value = detect_box.position.y
	
	var platform_boxes = get_tree().get_nodes_in_group("SolidPlatforms") + get_tree().get_nodes_in_group("SoftPlatforms")
	for platform_box in platform_boxes:
# warning-ignore:unassigned_variable
		var target_box: Rect2 # need to do this since need global position
		target_box.position = platform_box.rect_global_position
		target_box.size = platform_box.rect_size
		
		# conditions, must intersect and top surface must be within detect_box's height
		if detect_box.intersects(target_box) and target_box.position.y > detect_box.position.y and \
				target_box.position.y < detect_box.position.y + detect_box.size.y:

			match v_bias:
				0: # find closest to detect_box's center horizontal line
					var distance = abs(target_box.position.y - origin.y)
					if  distance < best_value:
						found_platform_box = target_box
						best_value = distance
				1: # find highest
					if target_box.position.y < best_value:
						found_platform_box = target_box
						best_value = target_box.position.y
				-1: # find lowest
					if target_box.position.y > best_value:
						found_platform_box = target_box
						best_value = target_box.position.y
						
	if found_platform_box == null: return null # no platforms found
	
	found_pos.y = found_platform_box.position.y # y-coordinate found
	
	# 3th, use Rect2.clip() and get get point on top side of resulting Rect2 closest to center (depending on h_bias)
	var clipped_box = detect_box.clip(found_platform_box)
	var leftmost_pt = clipped_box.position.x
	var rightmost_pt = clipped_box.position.x + clipped_box.size.x
	
	h_bias *= facing # this changes h_bias to 1 = right, -1 = left
	match h_bias:
		0: # find closest to origin.x
			if leftmost_pt > origin.x:
				found_pos.x = leftmost_pt
			elif rightmost_pt < origin.x:
				found_pos.x = rightmost_pt
			else:
				found_pos.x = origin.x
		1: # find rightmost
			found_pos.x = rightmost_pt
		-1: # find leftmost
			found_pos.x = leftmost_pt
			
	return found_pos
	# for ground burst wave type attacks, make a Point2D controller with a facing and timestamps, it does ground_finder() with 1 pixel width boxes
	# at certain offsets, will stop if fail to find ground
