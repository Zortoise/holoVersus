extends Node2D


onready var box = $MPlatform/SoftPlatform

# to save
var active := true

func _ready():
	add_to_group("MovingPlatforms")
	
	if has_node("SpritePlayer"):
		$SpritePlayer.init_with_loaded_frame_data($Sprite, get("loaded_frame_data"))
		# load frame data inside Resource folder, directory in extended
		
#		$Sprite.texture = Loader.entity_data[entity_ref].spritesheet # load spritesheet
	

func simulate():
	
	var results = call("movement_pattern")
	if results == null: return # just in case
	
	if results is Dictionary:
		process_results(results)
		
	elif results is Array: # can trigger multiple patterns at once
		for result in results:
			process_results(result)
			
	if has_node("SpritePlayer"):
		$SpritePlayer.stimulate()
	

func process_results(results: Dictionary):
	match results.type:
		Em.mov_platform.MOVING: # actual moving platform
			# get all riding entities
			var rider_boxes = []
			# get collision boxes of all grounded entities
			var collision_boxes = get_tree().get_nodes_in_group("Grounded")
			for collision_box in collision_boxes:
				if Detection.is_riding(box, collision_box): # check if riding
					rider_boxes.append(collision_box)
			
			var old_position = $MPlatform.position # store old position
			$MPlatform.position = results.pos # move platform
			var position_change: Vector2 = results.pos - old_position # use new position to calculate position_change vector
			
			# apply position_change vector to all riding entities
			for rider_box in rider_boxes:
				if rider_box.is_in_group("PlayerBoxes") or rider_box.is_in_group("MobBoxes") or rider_box.is_in_group("NPCBoxes") or \
						rider_box.is_in_group("EntityBoxes"):
					 # rider is player character/grounded entity
					# position_change need to be in integer!'
					var rider = rider_box.get_parent()
					if "stasis" in rider and rider.stasis:
						pass
					if "state" in rider and rider.state in [Em.char_state.INACTIVE, Em.char_state.SEQ_TARGET]:
						pass
					else:
						rider.move_amount(position_change)
						if rider.has_method("set_true_position"):
							rider.call("set_true_position")
					# no need the velocity, grounded Entities always have SoftPlatformDBox
				else:
					rider_box.get_parent().position += position_change # for grounded sfx, don't need to check for collision
						
		Em.mov_platform.WARPING: # teleporting platform
			$MPlatform.position = results.pos # move platform
			
		Em.mov_platform.ACTIVATE:
			active = results.active
			activate()
			
		Em.mov_platform.ANIMATE:
			if has_node("SpritePlayer"):
				if results.anim != null:
					$SpritePlayer.play(results.anim)
				else:
					$SpritePlayer.stop()
					
		Em.mov_platform.AUDIO:
			Globals.Game.play_audio(results.ref, results.aux)


func activate():
	if active:
		if !box.is_in_group("SoftPlatforms"):
			box.add_to_group("SoftPlatforms")
		if !has_node("SpritePlayer"):
			$MPlatform/Sprite.show()
			
	else:
		if box.is_in_group("SoftPlatforms"):	
			box.remove_from_group("SoftPlatforms")
		if !has_node("SpritePlayer"):
			$MPlatform/Sprite.hide()
					
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
		"active" : active
	}
	
	if has_node("SpritePlayer"):
		state_data["SpritePlayer_data"] = $SpritePlayer.save_state()
	
	return state_data

func load_state(stage_state_data): # move platform without moving riders
	$MPlatform.position = stage_state_data[name].position
	active = stage_state_data[name].active
	activate()
	
	if has_node("SpritePlayer"):
		$SpritePlayer.load_state(stage_state_data.SpritePlayer_data)
	

