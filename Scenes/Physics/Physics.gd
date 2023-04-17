extends Node2D
# let every moveable object extend this script


func get_collision_box(): # returns a ColorRect node
	if has_node("PlayerCollisionBox"):
		return get_node("PlayerCollisionBox")
	elif has_node("EntityCollisionBox"):
		return get_node("EntityCollisionBox")
	else:
		print("Error: No CollisionBox.")
		
func get_soft_dbox(collision_box) -> Rect2:
	if !collision_box.is_in_group("Grounded"): # non-grounded objects uses collision_box as their soft_dbox
		return Rect2(collision_box.rect_global_position, collision_box.rect_size)
	
	var soft_dbox := Rect2(collision_box.rect_global_position, collision_box.rect_size)
	soft_dbox.position.y = soft_dbox.position.y + soft_dbox.size.y - 1
	soft_dbox.size.y = 1
	return soft_dbox


# soft_platform_dbox is needed to phase through soft platforms
func move(ledge_stop = false): # uses the object's velocity
	
	if get("velocity").x == 0 and get("velocity").y == 0:
#		if is_in_wall(soft_platform_dbox):
#			return [false, true, false]
		return [false, false, false]
	
	call("move_true_position", get("velocity")) # first, move the true position
	var target_position: Vector2 = call("get_rounded_position")  # then get the new target position derived from the true position
	
	var move_amount = Vector2.ZERO # get the number of pixels to move horziontally/vertically from target position - current position
	move_amount.x = target_position.x - position.x
	move_amount.y = target_position.y - position.y
	
	# quick check
#	var test_rect := Rect2(collision_box.rect_global_position, collision_box.rect_size)
#	var test_rect2 := Rect2(soft_platform_dbox.rect_global_position, soft_platform_dbox.rect_size)
#	test_rect.position.x += move_amount.x
#	test_rect.position.y += move_amount.y
#	test_rect2.position.x += move_amount.x
#	test_rect2.position.y += move_amount.y
#	if check_test_rect(test_rect, test_rect2, checklist_enum, ledge_stop):
#		position = target_position
#		return [false, false, false]
	
	var results = move_amount(move_amount, ledge_stop) # move and change the velocity as needed
	
	if position != target_position: # unable to reach target_position (collision, pushing, etc), set true position to current position
		call("set_true_position")
	
#	if is_in_wall(soft_platform_dbox):
#		results[1] = true
	
	return results # [landing_check, collision_check, ledgedrop_check]

	
func move_amount(move_amount:Vector2, ledge_stop := false):
	# will only collide with other players if owner of collision_box is a player
	
	var collision_box = get_collision_box()
	var checklist_enum: Array = create_checklist_enum()
	
	# just in case...
	move_amount.x = int(move_amount.x)
	move_amount.y = int(move_amount.y)
	
	var landing_check := false
	var collision_check := false
	var ledgedrop_check := false
	
#	var offstage_check := false
	
	if "grounded" in self and !get("grounded"):
		ledge_stop = false
	var offstage_stop := false
	if collision_box.is_in_group("Players"):
		offstage_stop = true
	
	# horizontal_movement
	if move_amount.x != 0:
# warning-ignore:narrowing_conversion
		var results = linear_move(collision_box, true, move_amount.x, checklist_enum, ledge_stop, offstage_stop)
		# linear_move(collision_box, horizontal: bool, move_amount: int, checklist_enum: Array, ledgestop: bool, offstage_stop: bool)
		if results[1]:
			collision_check = true
			get("velocity").x = 0
		if results[2]:
			ledgedrop_check = true
			get("velocity").x = 0
		if results[3]:
#			offstage_check = true
			get("velocity").x = 0
		if results[4]: # hit another player
			get("velocity").x = FMath.percent(get("velocity").x, get("PLAYER_PUSH_SLOWDOWN")) # slow you down a little more
			
			
	if move_amount.y != 0:
# warning-ignore:narrowing_conversion
		var results = linear_move(collision_box, false, move_amount.y, checklist_enum, ledge_stop, offstage_stop)
		if results[1]:
			collision_check = true
			get("velocity").y = 0
		if results[0]:
			landing_check = true
			get("velocity").y = 0
		if results[3]:
#			offstage_check = true
			get("velocity").x = 0
			
#	if offstage_check:
	check_offstage(collision_box)
			
	return [landing_check, collision_check, ledgedrop_check]
	
#	while move_amount.x != 0:
#		if ledge_stop and is_against_ledge(soft_platform_dbox, sign(move_amount.x)): # if ledge_stop is true, ledges will stop movement
#			if !manual_move:
#				get("velocity").x = 0
#			ledgedrop_check = true
#			break
#		# velocity.x can be stopped by walls and players (for characters)
#		elif !is_against_wall(collision_box, soft_platform_dbox, sign(move_amount.x), checklist):
#
#			# for players, has to test collision with other players as well
#			if collision_box.is_in_group("Players") or collision_box.is_in_group("Mobs"):
#
#				var colliding_characters = get_colliding_characters_side(collision_box, checklist, sign(move_amount.x))
#				if colliding_characters.size() == 0: # no collision with other players
#					position.x += sign(move_amount.x)
#					move_amount.x -= sign(move_amount.x)
#				else:
#					for colliding_character in colliding_characters: # push collided player 1 pixel while you lose 1 move_amount
#						if colliding_character.has_node("SoftPlatformDBox"):
#							colliding_character.move_amount(Vector2(sign(move_amount.x), 0), colliding_character.get_node("PlayerCollisionBox"), \
#								colliding_character.get_node("SoftPlatformDBox"), colliding_character.create_checklist_enum())
#						else:
#							colliding_character.move_amount(Vector2(sign(move_amount.x), 0), colliding_character.get_node("PlayerCollisionBox"), \
#								colliding_character.get_node("PlayerCollisionBox"), colliding_character.create_checklist_enum())
#						colliding_character.set_true_position()
#
#					move_amount.x -= sign(move_amount.x) # skip moving this move_amount
#					if !manual_move:
#						get("velocity").x = FMath.percent(get("velocity").x, get("PLAYER_PUSH_SLOWDOWN")) # slow you down a little more
#
#			else: # non-player moving
#				position.x += sign(move_amount.x)		
#				move_amount.x -= sign(move_amount.x)
#			if not_in_sequence(collision_box) and check_offstage(collision_box): # ringed out
#				return [false, false, false]
#		else: # hit a wall
#			if !manual_move:
#				get("velocity").x = 0
#			collision_check = true
#			break
#
#	while move_amount.y != 0:
#		# velocity.y is stopped by floors and may be stopped by soft floors
#		if move_amount.y < 0: # moving upwards
#			# if no solid platform above
#			if !is_against_ceiling(collision_box, soft_platform_dbox, checklist):
#				position.y += sign(move_amount.y)
#				move_amount.y -= sign(move_amount.y)
#
#				if not_in_sequence(collision_box) and check_offstage(collision_box):
#					return [false, false, false]
#
#			else: # hit ceiling
#				if !manual_move:
#					get("velocity").y = 0
#				collision_check = true
#				break
#		else: # moving downwards
#
#			if !is_on_ground(soft_platform_dbox, checklist):
#				position.y += sign(move_amount.y)
#				move_amount.y -= sign(move_amount.y)
#				if check_offstage(collision_box):
#					return [false, false, false]
#			else: # stop moving
#				if !manual_move:
#					get("velocity").y = 0
#				landing_check = true
#				collision_check = true
#				break
#
#	return [landing_check, collision_check, ledgedrop_check]
	
	
	
func move_sequence_player_to(new_position: Vector2): # called by grabber, also move used to move grabber if grabbed hit a wall
	
	var move_amount := Vector2.ZERO
	move_amount.x = new_position.x - position.x
	move_amount.y = new_position.y - position.y
		
	var results
	results = move_amount(move_amount)
	call("set_true_position")
	
	return results # [landing_check, collision_check, ledgedrop_check]
	
	
func move_sequence_player_by(move_amount: Vector2): # in some special cases where move_sequence_player_to() is not enough
	var results
	results = move_amount(move_amount)
	call("set_true_position")
	return results # [landing_check, collision_check, ledgedrop_check]
	
	
func not_in_sequence(collision_box): # when object is in sequence, will not be killed at ceiling and sides but will die at bottom
	if (collision_box.is_in_group("Players") or collision_box.is_in_group("Mobs")) and \
			get("state") in [Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER]:
		return false
	return true
	
	
func move_no_collision():
	
	if get("velocity").x == 0 and get("velocity").y == 0: return
	
	call("move_true_position", get("velocity")) # first, move the true position
	position = call("get_rounded_position")  # then get the new target position derived from the true position
	
	# check offstage
	if self.is_in_group("PlayerNodes") or self.is_in_group("MobNodes"):
		Globals.Game.detect_kill(get_node("PlayerCollisionBox"))
	elif self.is_in_group("EntityNodes") or self.is_in_group("MobEntityNodes"):
		if has_node("EntitySpriteBox"):
			Globals.Game.detect_offstage(get_node("EntitySpriteBox"))
	
	
func check_offstage(collision_box):
	if collision_box.is_in_group("Players") and Globals.Game.detect_kill(collision_box):
		return true
	elif collision_box.is_in_group("Entities") and collision_box.get_parent().has_node("EntitySpriteBox") and \
			Globals.Game.detect_offstage(collision_box.get_parent().get_node("EntitySpriteBox")):
		# detect_offstage() will handle entities' reaction when becoming offstage
		return true
	return false
	
	
#func check_blast_barriers(collision_box, compass_dir): # return null if not touching barriers, return bounced velocity if so
#	if call("get_damage_percent") >= 100: # no barrier if damage value too high
#		return false
#	match compass_dir:
#		Em.compass.W:
#			if !Detection.detect_duo(collision_box, Globals.Game.blastbarrierL):
#				return null
#			call("bounce_dust", compass_dir)
#			get("velocity").x = -FMath.percent(get("velocity").x, 75)
#			return true
#		Em.compass.E:
#			if !Detection.detect_duo(collision_box, Globals.Game.blastbarrierR):
#				return null
#			call("bounce_dust", compass_dir)
#			get("velocity").x = -FMath.percent(get("velocity").x, 75)
#			return true
#		Em.compass.N:
#			if !Detection.detect_duo(collision_box, Globals.Game.blastbarrierU):
#				return false
#			call("bounce_dust", compass_dir)
#			get("velocity").y = -FMath.percent(get("velocity").y, 25) # bounce down
#			return true
#	return false # just in case

	
# no need to get character collision for up and down movement for now
#func get_colliding_characters_side(collision_box, checklist: Array, direction):
#	var colliding_characters = []
##	var tester = collision_box.get_parent()
#
#	# get an array of character nodes in the way
#	var to_check := []
#	if "Players" in checklist: to_check.append("Players")
#	if "Mobs" in checklist: to_check.append("Mobs")
#	if to_check.size() == 0: return []
#
#	var characters_detected = Detection.detect_return([collision_box], to_check, Vector2(direction, 0))
#	for character in characters_detected:
#		if "MOB" in self and "MOB" in character:
#			continue # mobs do not collide with each other
#		# check if you are moving toward them or away, only collide if moving towards them
#		if ((direction == 1 and character.position.x > position.x) or \
#				(direction == -1 and character.position.x < position.x)):
#			if character.state == Em.char_state.CROUCHING and !get("grounded") and character.position.y > position.y:
#				continue # if you are airborne, will not collide with opponents that are crouching and under you
#			elif character.has_method("check_collidable") and character.call("check_collidable"): # detected character must be collidable
#				colliding_characters.append(character)
#
#	return colliding_characters
	
	
func create_checklist_enum() -> Array:
	var to_check := []
	
	var collision_box = get_collision_box()
	var soft_dbox = get_soft_dbox(collision_box)
		
	if Detection.detect_bool([collision_box], ["SolidPlatforms", "CSolidPlatforms"]):
		to_check.append(Em.detect.PASS_SIDE)
		# if a solid platform is within collision_box, can move pass solid platforms sideway/upward
	
	if has_method("check_passthrough") and call("check_passthrough"):
		pass
	else:
		if !Detection.detect_bool([soft_dbox], ["SolidPlatforms"]):
			to_check.append(Em.detect.SOLID)
		if has_node("EntityCollisionBox"):
			if ($EntityCollisionBox.is_in_group("CSolidPlatforms") or \
				$EntityCollisionBox.is_in_group("SemiSolidWalls")):
				pass # created platforms will not collide with other created platforms
			else:
				if !Detection.detect_bool([soft_dbox], ["CSolidPlatforms"]):
					to_check.append(Em.detect.CSOLID)
		else:
			if !Detection.detect_bool([soft_dbox], ["CSolidPlatforms"]):
				to_check.append(Em.detect.CSOLID)
			to_check.append(Em.detect.SEMISOLIDWALLS) # entities do not collide with SemiSolidWalls
		if has_method("check_fallthrough") and call("check_fallthrough"):
			pass
		else:
			if !Detection.detect_bool([soft_dbox], ["SoftPlatforms"]):
				to_check.append(Em.detect.SOFT)
			
	if is_in_group("PlayerNodes") or is_in_group("MobNodes"):
		to_check.append(Em.detect.BLASTWALLS)
		to_check.append(Em.detect.BLASTCEILING)
		if has_method("is_killable"):
			if call("is_killable", get("velocity").x):
				to_check.erase(Em.detect.BLASTWALLS)
			if call("is_killable", get("velocity").y):
				to_check.erase(Em.detect.BLASTCEILING)
			
		if has_method("check_collidable") and call("check_collidable"):
			to_check.append(Em.detect.PLAYERS)
			if is_in_group("PlayerNodes"): to_check.append(Em.detect.MOBS)
			
		
	elif is_in_group("EntityNodes") or is_in_group("MobEntityNodes"):
		if Em.entity_trait.BLAST_BARRIER_COLLIDE in get("UniqEntity").TRAITS:
			to_check.append(Em.detect.BLASTWALLS)
			to_check.append(Em.detect.BLASTCEILING)
#		elif get("UniqEntity").has_method("on_offstage"):
#			to_check.erase("BlastBarriers")
	elif is_in_group("PickUpNodes"):
		to_check.append(Em.detect.BLASTWALLS)
		to_check.append(Em.detect.BLASTCEILING)
			
	return to_check
			
			
#func refine_checklist(checklist_enum: Array) -> Array: # enum into strings
#	var checklist := []
#	for x in checklist_enum:
#		match x:
#			Em.detect.SOLID:
#				checklist.append("SolidPlatfoms")
#			Em.detect.CSOLID:
#				checklist.append("CSolidPlatfoms")
#			Em.detect.SOFT:
#				checklist.append("SoftPlatfoms")
#			Em.detect.SEMISOLIDWALLS:
#				checklist.append("SemiSolidWalls")
#			Em.detect.BLASTCEILING:
#				checklist.append("BlastCeiling")
#			Em.detect.BLASTCEILING:
#				checklist.append("BlastWalls")
#			Em.detect.PLAYERS:
#				checklist.append("Players")
#			Em.detect.MOBS:
#				checklist.append("Mobs")
#	return checklist
#
#
#func check_test_rect(test_rect, test_rect2, checklist_enum: Array, ledge_stop: bool):
#
#	var checklist := refine_checklist(checklist_enum)
#
#	if Detection.detect_bool([test_rect], checklist):
#		return false # detected obstacle, failed test
#
#	if ledge_stop and !is_on_ground(test_rect2):
#		return false # grounded object went off ledge, failed test
#
##	if is_in_group("PlayerNodes"): # player went off stage, failed test
#	if Globals.Game.is_offstage(test_rect):
#		return false
#
#	return true
			
	
# return true if a wall in "direction", 1 is right, -1 is left
func is_against_wall(direction: int, in_soft_dbox = null):
		
	var collision_box = get_collision_box()
	
	var soft_dbox = in_soft_dbox
	if soft_dbox == null:
		soft_dbox = get_soft_dbox(get_collision_box())
		
	if Detection.detect_bool([collision_box], ["SolidPlatforms"], Vector2(direction, 0)) and \
		!Detection.detect_bool([soft_dbox], ["SolidPlatforms"]):
		return true	
	if Detection.detect_bool([collision_box], ["CSolidPlatforms"], Vector2(direction, 0)) and \
		!Detection.detect_bool([soft_dbox], ["CSolidPlatforms"]):
		return true	
	if Detection.detect_bool([collision_box], ["SemiSolidWalls"], Vector2(direction, 0)):
		return true	
	if Detection.detect_bool([collision_box], ["BlastWalls"], Vector2(direction, 0)) and \
		!Detection.detect_bool([soft_dbox], ["BlastWalls"]):
		return true	
			
	return false
		
		
func is_in_wall():
	
	if has_method("check_passthrough") and call("check_passthrough"):
		return false
	
	if Detection.detect_bool([get_soft_dbox(get_collision_box())], ["SolidPlatforms"]):
		return true
	else:
		return false
		
		
func is_tele_valid(target_position: Vector2): # to check if teleportation will go into walls
	var move_vec = target_position - position
	
	var collision_box = get_collision_box()
	var new_rect = Rect2(collision_box.rect_global_position + move_vec, collision_box.rect_size)
	
	if Detection.detect_bool([new_rect], ["SolidPlatforms", "BlastWalls", "BlastCeiling", "CSolidPlatforms"]):
		return false
	else:
		if Globals.Game.is_offstage(new_rect):
			return false
		return true
	
		
#func is_against_ledge(soft_platform_dbox, direction):
#	if "grounded" in self and !get("grounded"):
#		return false
#	if !Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms", "CSolidPlatforms", "SoftPlatforms"], Vector2(direction, 1)):
#		return true
#	else:
#		return false
		
		
func is_against_ceiling(in_soft_dbox = null): # return true if there is a solid platform above
		
	var collision_box = get_collision_box()
	
	var soft_dbox = in_soft_dbox
	if soft_dbox == null:
		soft_dbox = get_soft_dbox(get_collision_box())
		
	if Detection.detect_bool([collision_box], ["SolidPlatforms"], Vector2.UP) and \
		!Detection.detect_bool([soft_dbox], ["SolidPlatforms"]):
		return true	
	if Detection.detect_bool([collision_box], ["CSolidPlatforms"], Vector2.UP) and \
		!Detection.detect_bool([soft_dbox], ["CSolidPlatforms"]):
		return true	
	if Detection.detect_bool([collision_box], ["BlastCeiling"], Vector2.UP) and \
		!Detection.detect_bool([soft_dbox], ["BlastCeiling"]):
		return true	
	
	return false
		
		
func is_on_ground(in_soft_dbox = null): # return true if standing on solid/soft floor

	if get("velocity").y < 0: # is not considered on ground if moving upwards
		return false
		
	var soft_dbox = in_soft_dbox
	if soft_dbox == null:
		soft_dbox = get_soft_dbox(get_collision_box())
		
	if Detection.detect_bool([soft_dbox], ["SolidPlatforms"], Vector2.DOWN) and \
		!Detection.detect_bool([soft_dbox], ["SolidPlatforms"]):
		return true	
	if Detection.detect_bool([soft_dbox], ["CSolidPlatforms"], Vector2.DOWN) and \
		!Detection.detect_bool([soft_dbox], ["CSolidPlatforms"]):
		return true
	if Detection.detect_bool([soft_dbox], ["SoftPlatforms"], Vector2.DOWN) and \
		!Detection.detect_bool([soft_dbox], ["SoftPlatforms"]):
		return true	
	
	return false
			

func is_on_solid_ground(in_soft_dbox = null):
	
	if has_method("check_passthrough") and call("check_passthrough"):
		return false
	if get("velocity").y < 0: # is not considered on ground if moving upwards
		return false
		
	var soft_dbox = in_soft_dbox
	if soft_dbox == null:
		soft_dbox = get_soft_dbox(get_collision_box())
	
	if Detection.detect_bool([soft_dbox], ["SolidPlatforms"], Vector2.DOWN) and \
		!Detection.detect_bool([soft_dbox], ["SolidPlatforms"]):
		return true	

	if has_node("EntityCollisionBox") and $EntityCollisionBox.is_in_group("CSolidPlatforms"):
		pass
	elif Detection.detect_bool([soft_dbox], ["CSolidPlatforms"], Vector2.DOWN) and \
			!Detection.detect_bool([soft_dbox], ["CSolidPlatforms"]):
		return true
		
	return false
		
	
func is_on_soft_ground(in_soft_dbox = null): # return true if standing on soft floor
	
	if has_method("check_passthrough") and call("check_passthrough"):
		return false
#	if has_method("check_fallthrough") and call("check_fallthrough"):
#		return false
	if get("velocity").y < 0: # is not considered on ground if moving upwards
		return false
	
	var soft_dbox = in_soft_dbox
	if soft_dbox == null:
		soft_dbox = get_soft_dbox(get_collision_box())
	
	if Detection.detect_bool([soft_dbox], ["SoftPlatforms"], Vector2.DOWN) and \
		!Detection.detect_bool([soft_dbox], ["SoftPlatforms"]):
		return true
		
	return false


func snap_up(): # move character upwards till dashland_dbox stop detecting soft platforms, called by Character.gd
	var max_movement = get_node("DashLandDBox").rect_size.y
	for x in max_movement:
		# dashland_dbox stopped detecting soft platforms, snap complete
		if !Detection.detect_bool([get_node("DashLandDBox")], ["SoftPlatforms"]):
			get("velocity").y = 0 # reset vertical velocity
			call("set_true_position")
			return true
		# else if no solid platform above, move up 1 pixel
		elif !Detection.detect_bool([get_collision_box()], ["SolidPlatforms", "CSolidPlatforms"], Vector2.UP):
			position.y -= 1
		else: # hit a solid platform, stop immediately, revert all movement
			position.y += x
			return false
	# if fail to snap up after moving the max allowed distance, return to starting position
	position.y += max_movement
	return false
	

# MOVEMENT COLLISION ---------------------------------------------------------------------------------------------------------

func get_nodes_in_box_move(detect_box: Rect2, platform_boxes: Array) -> Array:
	var to_return := []
	for x in platform_boxes:
		if detect_box.intersects(Rect2(x.rect_global_position, x.rect_size)):
			to_return.append(x)
	return to_return
	
func get_players_in_box_move(detect_box: Rect2, player_boxes: Array, direction: int) -> Array:
	var to_return := []
	for x in player_boxes:
		if x.get_parent() == self or x.get_parent().position.x == position.x:
			continue # cannot collide with self
		if sign(x.get_parent().position.x - position.x) != direction:
			continue # only collide with other players in direction you are moving towards
		if !x.get_parent().check_collidable():
			continue # only collide with players in collidable states
		if detect_box.intersects(Rect2(x.rect_global_position, x.rect_size)):
			to_return.append(x)
			x.get_parent().move_amount(Vector2(direction, 0))
			x.get_parent().set_true_position()
	return to_return
	
func get_lowest_in_array(stoppers: Array): # for moving upward
	var lowest_point = null
	for stopper in stoppers:
		if lowest_point == null:
			lowest_point = stopper.rect_global_position.y + stopper.rect_size.y
		else:
			if stopper.rect_global_position.y + stopper.rect_size.y > lowest_point:
				lowest_point = stopper.rect_global_position.y + stopper.rect_size.y
	return lowest_point
	
func get_highest_in_array(stoppers: Array): # for moving downward
	var highest_point = null
	for stopper in stoppers:
		if highest_point == null:
			highest_point = stopper.rect_global_position.y
		else:
			if stopper.rect_global_position.y < highest_point:
				highest_point = stopper.rect_global_position.y
	return highest_point
	
func get_leftmost_in_array(stoppers: Array): # for moving to the right
	var leftmost_point = null
	for stopper in stoppers:
		if leftmost_point == null:
			leftmost_point = stopper.rect_global_position.x
		else:
			if stopper.rect_global_position.x < leftmost_point:
				leftmost_point = stopper.rect_global_position.x
	return leftmost_point
	
func get_rightmost_in_array(stoppers: Array): # for moving to the left
	var rightmost_point = null
	for stopper in stoppers:
		if rightmost_point == null:
			rightmost_point = stopper.rect_global_position.x + stopper.rect_size.x
		else:
			if stopper.rect_global_position.x + stopper.rect_size.x < rightmost_point:
				rightmost_point = stopper.rect_global_position.x + stopper.rect_size.x
	return rightmost_point
	
	
#func is_over_void(target_box):
#	if !Detection.detect_bool([target_box], ["SolidPlatforms", "CSolidPlatforms", "SoftPlatforms"], Vector2(0, 1)):
#		return true
#	else:
#		return false
		
func left_ledgestop(collision_box, target_box, results) -> Rect2:
	if "grounded" in self and !get("grounded"):
		return target_box
	
	var my_ground = Detection.detect_return_boxes([collision_box], ["SolidPlatforms", "CSolidPlatforms", "SoftPlatforms"], Vector2(0, 1))
	if my_ground.size() == 0: return target_box # just in case
	
	var left_ledge = get_leftmost_in_array(my_ground) + 1
	if target_box.position.x + target_box.size.x < left_ledge:
		target_box.position.x = left_ledge - target_box.size.x
		results[2] = true # set ledgestop flag
	return target_box
		
func right_ledgestop(collision_box, target_box, results) -> Rect2:
	if "grounded" in self and !get("grounded"):
		return target_box
	
	var my_ground = Detection.detect_return_boxes([collision_box], ["SolidPlatforms", "CSolidPlatforms", "SoftPlatforms"], Vector2(0, 1))
	if my_ground.size() == 0: return target_box # just in case
	
	var right_ledge = get_rightmost_in_array(my_ground) - 1
	if target_box.position.x > right_ledge:
		target_box.position.x = right_ledge
		results[2] = true # set ledgestop flag
	return target_box
	
func test_offstage_right(target_box, results) -> Rect2:
	var stage_rect = Globals.Game.stage_box.get_rect()
	var border = stage_rect.position.x + stage_rect.size.x
	
	if target_box.position.x > border:
		target_box.position.x = border
		results[3] = true # set offstage flag
	return target_box # Rect2 are NOT passed by pointer, have to return it

func test_offstage_left(target_box, results) -> Rect2:
	var stage_rect = Globals.Game.stage_box.get_rect()
	var border = stage_rect.position.x
	
	if target_box.position.x + target_box.size.x < border:
		target_box.position.x = border - target_box.size.x
		results[3] = true # set offstage flag
	return target_box

func test_offstage_up(target_box, results) -> Rect2:
	var stage_rect = Globals.Game.stage_box.get_rect()
	var border = stage_rect.position.y
	
	if target_box.position.y + target_box.size.y < border:
		target_box.position.y = border - target_box.size.y
		results[3] = true # set offstage flag
	return target_box
		
func test_offstage_down(target_box, results) -> Rect2:
	var stage_rect = Globals.Game.stage_box.get_rect()
	var border = stage_rect.position.y + stage_rect.size.y
	
	if target_box.position.y > border:
		target_box.position.y = border
		results[3] = true # set offstage flag
	return target_box
	

# extend detect_box to look for collisions
func linear_move(collision_box, horizontal: bool, move_amount: int, checklist_enum: Array, ledgestop: bool, offstage_stop: bool) -> Array:
	
	var detect_box = Rect2(collision_box.rect_global_position, collision_box.rect_size)
	
	var platform_boxes = []

		
	var compass_dir: int
		
	match horizontal:
		true:
			if !Em.detect.PASS_SIDE in checklist_enum:
				if Em.detect.SOLID in checklist_enum:
					platform_boxes.append_array(get_tree().get_nodes_in_group("SolidPlatforms"))
					platform_boxes.append_array(get_tree().get_nodes_in_group("SemiSolidWalls"))
				if Em.detect.CSOLID in checklist_enum:
					platform_boxes.append_array(get_tree().get_nodes_in_group("CSolidPlatforms"))
			if Em.detect.BLASTWALLS in checklist_enum:
				platform_boxes.append_array(get_tree().get_nodes_in_group("BlastWalls"))
				
#			if Em.detect.PLAYERS in checklist_enum:
#				platform_boxes.append_array(get_tree().get_nodes_in_group("Players"))
#			if Em.detect.MOBS in checklist_enum:
#				platform_boxes.append_array(get_tree().get_nodes_in_group("Mobs"))
				
			if move_amount > 0: # moving right
				detect_box.size.x += move_amount
				compass_dir = Em.compass.E
			else: # moving left
				detect_box.size.x += -move_amount
				detect_box.position.x -= -move_amount
				compass_dir = Em.compass.W
		false:
			if Em.detect.SOLID in checklist_enum:
				platform_boxes.append_array(get_tree().get_nodes_in_group("SolidPlatforms"))
			if Em.detect.CSOLID in checklist_enum:
				platform_boxes.append_array(get_tree().get_nodes_in_group("CSolidPlatforms"))
			if move_amount > 0: # moving down
				# shrink detect_box into soft_dbox
				detect_box.position.y = detect_box.position.y + detect_box.size.y - 1
				detect_box.size.y = 1
				detect_box.size.y += move_amount
				if Em.detect.SOFT in checklist_enum:
					platform_boxes.append_array(get_tree().get_nodes_in_group("SoftPlatforms"))
				compass_dir = Em.compass.S
			else: # moving up
				detect_box.size.y += -move_amount
				detect_box.position.y -= -move_amount
				if Em.detect.BLASTCEILING in checklist_enum:
					platform_boxes.append_array(get_tree().get_nodes_in_group("BlastCeiling"))
				compass_dir = Em.compass.N
				
	var collided_boxes = get_nodes_in_box_move(detect_box, platform_boxes)
	var results := [false, false, false, false, false]
	# return [landing_check, collision_check, ledgedrop_check, offstage_check, player_collide_check]
	var target_box := Rect2(collision_box.rect_global_position, collision_box.rect_size)
	
	match compass_dir:
		Em.compass.E:
			if collided_boxes.size() == 0: 
				target_box.position.x = collision_box.rect_global_position.x + move_amount
			else:
				var point = get_leftmost_in_array(collided_boxes)
	#			if point > collision_box.position.x + collision_box.rect_size.x:
				target_box.position.x = point - collision_box.rect_size.x
				results[1] = true
	#			results = [false, false, false]
			if ledgestop:
				target_box = right_ledgestop(collision_box, target_box, results)
			if offstage_stop:
				target_box = test_offstage_right(target_box, results)
				
		Em.compass.W:
			if collided_boxes.size() == 0: 
				target_box.position.x = collision_box.rect_global_position.x + move_amount
			else:
				var point = get_rightmost_in_array(collided_boxes)
	#			if point < collision_box.position.x:
				target_box.position.x = point
				results[1] = true
	#			results = [false, false, false]
			if ledgestop:
				target_box = left_ledgestop(collision_box, target_box, results)
			if offstage_stop:
				target_box = test_offstage_left(target_box, results)
		Em.compass.N:
			if collided_boxes.size() == 0: 
				target_box.position.y = collision_box.rect_global_position.y + move_amount
			else:
				var point = get_lowest_in_array(collided_boxes)
	#			if point < collision_box.position.y:
				target_box.position.y = point
				results[1] = true
	#			results = [false, false, false]
			if offstage_stop:
				target_box = test_offstage_up(target_box, results)
		_: # moving down
			if collided_boxes.size() == 0: 
				target_box.position.y = collision_box.rect_global_position.y + move_amount
			else:
				var point = get_highest_in_array(collided_boxes)
	#			if point > collision_box.position.y + collision_box.rect_size.y:
				target_box.position.y = point - collision_box.rect_size.y
				results[0] = true
				results[1] = true
	#			results = [false, false, false]
			if offstage_stop:
				target_box = test_offstage_down(target_box, results)
	
	if !horizontal:
		position += target_box.position - collision_box.rect_global_position
		return results
		
	else: # player_collision
		var player_boxes := []
		if Em.detect.PLAYERS in checklist_enum:
			player_boxes.append_array(get_tree().get_nodes_in_group("Players"))
		if Em.detect.MOBS in checklist_enum:
			player_boxes.append_array(get_tree().get_nodes_in_group("Mobs"))
		if player_boxes.size() == 0: # no collision with players
			position += target_box.position - collision_box.rect_global_position
			return results
			
		# create a new detect_box
		var move_amount2 = target_box.position.x - collision_box.rect_global_position.x
		if move_amount2 == 0: return results # no more movement
		
		var detect_box2 := Rect2(collision_box.rect_global_position, collision_box.rect_size)
		if move_amount2 > 0: # moving to right
			detect_box2.size.x += move_amount2
		else: # moving to left
			detect_box2.size.x += -move_amount2
			detect_box2.position.x -= -move_amount2
			
# warning-ignore:narrowing_conversion
		var collided_players = get_players_in_box_move(detect_box2, player_boxes, sign(move_amount2)) # get collided players
		if collided_players.size() == 0: # no collision with players
			position += target_box.position - collision_box.rect_global_position
			return results
		else:
			results[4] = true
			
		
		if move_amount2 > 0: # moving to right
			var point = get_leftmost_in_array(collided_players)
			if point > collision_box.rect_global_position.x + collision_box.rect_size.x: # only move if collider is completely outside own's box
				target_box.position.x = point - collision_box.rect_size.x
				position += target_box.position - collision_box.rect_global_position
		else: # moving to left
			var point = get_rightmost_in_array(collided_players)
			if point < collision_box.rect_global_position.x:
				target_box.position.x = point
				position += target_box.position - collision_box.rect_global_position
				
	return results
		
	
