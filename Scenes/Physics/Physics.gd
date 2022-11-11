extends Node2D
# let every moveable object extend this script

var player_push_slowdown # set by constant in Character.gd

# soft_platform_dbox is needed to phase through soft platforms
func character_move(collision_box, soft_platform_dbox, velocity, ledge_stop = false):
	var move_amount = Vector2.ZERO
	move_amount.x = round(velocity.x * Globals.FRAME)
	move_amount.y = round(velocity.y * Globals.FRAME)
	
	return move_amount(move_amount, collision_box, soft_platform_dbox, velocity, ledge_stop) # move and return the velocity
	
func move_amount(move_amount:Vector2, collision_box, soft_platform_dbox, velocity, ledge_stop = false):
	# will only collide with other players if owner of collision_box is a player
	# just in case...
	move_amount.x = int(move_amount.x)
	move_amount.y = int(move_amount.y)
	
	while move_amount.x != 0:
		if ledge_stop and is_against_ledge(soft_platform_dbox, sign(move_amount.x)): # if ledge_stop is true, ledges will stop movement
			velocity.x = 0
			break
		# velocity.x can be stopped by walls and players (for characters)
		elif !is_against_wall(collision_box, soft_platform_dbox, sign(move_amount.x)):
			# for players, has to test collision with other players as well
			if collision_box.is_in_group("Players"):
				var colliding_characters = get_colliding_characters_side(collision_box, sign(move_amount.x))
				# no collision with other players during hitstun
				if $HitStunTimer.is_running() or colliding_characters.size() == 0:
					collision_box.get_parent().position.x += sign(move_amount.x)
					if Globals.Game.detect_kill(collision_box):
						return Vector2.ZERO
					move_amount.x -= sign(move_amount.x)
				else:
					for colliding_character in colliding_characters: # push collided player 1 pixel whike you lose 1 move_amount
						colliding_character.move_amount(Vector2(sign(move_amount.x), 0), colliding_character.get_node("PlayerCollisionBox"), \
							colliding_character.get_node("SoftPlatformDBox"), Vector2.ZERO)
					move_amount.x -= sign(move_amount.x) # skip moving this move_amount
					velocity.x *= player_push_slowdown # slow you down a little more
			else: # non-player moving
				collision_box.get_parent().position.x += sign(move_amount.x)
				move_amount.x -= sign(move_amount.x)
		else:
			velocity.x = 0
			break
			
	while move_amount.y != 0:
		# velocity.y is stopped by floors and may be stopped by soft floors
		if move_amount.y < 0: # moving upwards
			# if no solid platform above
			if !is_against_ceiling(collision_box, soft_platform_dbox):
				collision_box.get_parent().position.y += sign(move_amount.y)
				if Globals.Game.detect_kill(collision_box):
					return Vector2.ZERO
				move_amount.y -= sign(move_amount.y)
			else: # stop moving
				velocity.y = 0
				break
		else: # moving downwards
			if has_method("check_auto_drop") and call("check_auto_drop"): # passing through soft platforms
				if !is_on_solid_ground(soft_platform_dbox, velocity):
					collision_box.get_parent().position.y += sign(move_amount.y)
					if Globals.Game.detect_kill(collision_box):
						return Vector2.ZERO
					move_amount.y -= sign(move_amount.y)
				else: # stop moving
					velocity.y = 0
					break
			else:
				if !is_on_ground(soft_platform_dbox, velocity):
					collision_box.get_parent().position.y += sign(move_amount.y)
					if Globals.Game.detect_kill(collision_box):
						return Vector2.ZERO
					move_amount.y -= sign(move_amount.y)
				else: # stop moving
					velocity.y = 0
					break
			
	return velocity
	
# no need to get character collision for up and down movement for now
func get_colliding_characters_side(collision_box, direction):
	var colliding_characters = []
	var tester = collision_box.get_parent()
	
	# get an array of character nodes in the way
	var characters_detected = Detection.detect_return([collision_box], ["Players"], Vector2(direction, 0))
	for character in characters_detected:
		# check if you are moving toward them or away
		if ((direction == 1 and character.position.x > tester.position.x) or \
				(direction == -1 and character.position.x < tester.position.x)) and \
				is_collidable(character): # will not collide with hitstunned players unless they are in hitstop
			
			colliding_characters.append(character)
			
	return colliding_characters
	
func is_collidable(character):
	if !self.UniqueCharacter.check_collidable():
		return false
#	if !character.get_node("HitStunTimer").is_running(): # not in hitstun
#		return true # some characters have move that can pass through other characters
#	elif character.get_node("HitStopTimer").is_running(): # or if in hitstun, in hitstop
#		return true
	elif character.state == Globals.char_state.LAUNCHED_HITSTUN:
		return false
	return true
	
# return true if a wall in "direction", 1 is right, -1 is left
func is_against_wall(collision_box, soft_platform_dbox, direction):
	if Detection.detect_bool([collision_box], ["SolidPlatforms"], Vector2(direction, 0)) and \
			!Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms"]):
		return true
	else:
		return false
		
func is_against_ledge(soft_platform_dbox, direction):
	if !Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms", "SoftPlatforms"], Vector2(direction, 1)):
		return true
	else:
		return false
		
# return true if there is a solid platform above
func is_against_ceiling(collision_box, soft_platform_dbox):
	if Detection.detect_bool([collision_box], ["SolidPlatforms"], Vector2.UP) and \
			!Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms"]):
		return true
	else:
		return false
		
# return true if standing on solid/soft floor
func is_on_ground(soft_platform_dbox, velocity):
	if Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms", "SoftPlatforms"], Vector2.DOWN) and \
			!Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms", "SoftPlatforms"]) \
			and velocity.y >= 0: # is not considered on ground if moving upwards
		return true
	else:
		return false

func is_on_solid_ground(soft_platform_dbox, velocity):
	if Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms"], Vector2.DOWN) and \
			!Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms"]) \
			and velocity.y >= 0: # is not considered on ground if moving upwards
		return true
	else:
		return false
	
# return true if standing on soft floor
func is_on_soft_ground(soft_platform_dbox, velocity):
	if Detection.detect_bool([soft_platform_dbox], ["SoftPlatforms"], Vector2.DOWN) and \
			!Detection.detect_bool([soft_platform_dbox], ["SolidPlatforms", "SoftPlatforms"]) \
			and velocity.y >= 0: # is not considered on ground if moving upwards
		return true
	else:
		return false

# move character upwards till dashland_dbox stop detecting soft platforms
func snap_up(collision_box, dashland_dbox):
	var max_movement = dashland_dbox.rect_size.y
	for x in max_movement:
		# dashland_dbox stopped detecting soft platforms, snap complete
		if !Detection.detect_bool([dashland_dbox], ["SoftPlatforms"]):
			collision_box.get_parent().velocity.y = 0 # reset vertical velocity
			return
		# else if no solid platform above, move up 1 pixel
		elif !Detection.detect_bool([collision_box], ["SolidPlatforms"], Vector2.UP):
			collision_box.get_parent().position.y -= 1
		else: # hit a solid platform, stop immediately, revert all movement
			collision_box.get_parent().position.y += x
			return
	# if fail to snap up after moving the max allowed distance, return to starting position
	collision_box.get_parent().position.y += max_movement


		
	
