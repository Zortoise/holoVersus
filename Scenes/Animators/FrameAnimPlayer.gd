extends Node

# this can play animations other than frame data for sprites
# set animation list by extending this animation player

signal anim_started (anim_name)
signal anim_finished (anim_name)
signal change_spritesheet(spritesheet_filename) # only connect this if needed
signal change_SfxOver_spritesheet(SfxOver_spritesheet_filename)
signal hide_SfxOver ()
signal change_SfxUnder_spritesheet(SfxUnder_spritesheet_filename)
signal hide_SfxUnder ()
signal frame_update () # currently used for staggering audio

var sprite # sprite to animate
var sfx_over
var sfx_under

var time := 0 # increase by 1 each frame, used to check for timestamps
var to_play_anim: = "" # since current_anim should only be changed on render
var current_anim: = ""
var playing := false
var looped_back := false # if true, do not emit anim_started when starting

# set this in node extending this
var animations = {}

var sustain := false # not saved

	
# load and play an animation
func play(anim: String):
	if anim in animations:
		playing = true
		to_play_anim = anim
		time = 0
		looped_back = false
		if current_anim == "": # first animation
			current_anim = to_play_anim
			set_up_texture()
			process_timestamp(0)
		sustain = true
	else:
		print("Error: Animation " + anim + " not found.")
		
func stop():
	playing = false
	
func is_playing():
	if !current_anim in animations:
		return false
	if time >= animations[current_anim].duration - 1 and !animations[current_anim].loop:
		return false
	else: return true

# run every physics tick
func simulate():
	if playing:
		current_anim = to_play_anim
		
		if !sustain and (current_anim in NSAnims.modulate_animations or current_anim in NSAnims.fade_animations) and \
				animations[current_anim].loop and get_parent().has_method("reset_modulate"):
			get_parent().reset_modulate()
			current_anim = ""
			stop()
			return
		sustain = false
		
		if time == 0:
			if !looped_back:
				emit_signal("anim_started", current_anim)
			set_up_texture()
		
		# if has loop section, just loop the section till animation finishes, good for modulate animations to shorten code
		if "loop_section" in animations[current_anim]:
			if posmod(time, animations[current_anim].loop_section) in animations[current_anim]["timestamps"]:
				process_timestamp(time % animations[current_anim].loop_section)
		# no loop section, process normally
		elif time in animations[current_anim]["timestamps"]:
			process_timestamp(time)
			
		if time >= animations[current_anim].duration - 1: # increment time_count if not completed yet
			if animations[current_anim].loop:
				time = 0
				looped_back = true
			else:
				emit_signal("anim_finished", current_anim)
				return
		else:
			time += 1
			

func process_timestamp(timestamp):
	if "frame" in animations[current_anim]["timestamps"][timestamp]:
		sprite.frame = animations[current_anim]["timestamps"][timestamp].frame
		emit_signal("frame_update")
	if "modulate" in animations[current_anim]["timestamps"][timestamp]:
		sprite.modulate.r = animations[current_anim]["timestamps"][timestamp].modulate.r
		sprite.modulate.g = animations[current_anim]["timestamps"][timestamp].modulate.g
		sprite.modulate.b = animations[current_anim]["timestamps"][timestamp].modulate.b
	if "fade" in animations[current_anim]["timestamps"][timestamp]:
		sprite.modulate.a = animations[current_anim]["timestamps"][timestamp].fade
	# add more later?
	
	if "SfxOver_frame" in animations[current_anim]["timestamps"][timestamp]:
		sfx_over.frame = animations[current_anim]["timestamps"][timestamp].SfxOver_frame
		sfx_over.scale.x = sprite.scale.x
	if "SfxUnder_frame" in animations[current_anim]["timestamps"][timestamp]:
		sfx_under.frame = animations[current_anim]["timestamps"][timestamp].SfxUnder_frame
		sfx_under.scale.x = sprite.scale.x
		
# handle changing spritesheets, triggered at start of every animation
func set_up_texture():
	
	if "spritesheet" in animations[current_anim]:
		emit_signal("change_spritesheet", animations[current_anim].spritesheet)
	if "hframes" in animations[current_anim]:
		sprite.hframes = animations[current_anim].hframes
	if "vframes" in animations[current_anim]:
		sprite.vframes = animations[current_anim].vframes
		
	if "SfxOver_spritesheet" in animations[current_anim]:
		emit_signal("change_SfxOver_spritesheet", animations[current_anim].SfxOver_spritesheet)
	else:
		emit_signal("hide_SfxOver")
	if "SfxOver_hframes" in animations[current_anim]:
		sfx_over.hframes = animations[current_anim].SfxOver_hframes
	if "SfxOver_vframes" in animations[current_anim]:
		sfx_over.vframes = animations[current_anim].SfxOver_vframes
		
	if "SfxUnder_spritesheet" in animations[current_anim]:
		emit_signal("change_SfxUnder_spritesheet", animations[current_anim].SfxUnder_spritesheet)	
	else:
		emit_signal("hide_SfxUnder")	
	if "SfxUnder_hframes" in animations[current_anim]:
		sfx_under.hframes = animations[current_anim].SfxUnder_hframes
	if "SfxUnder_vframes" in animations[current_anim]:
		sfx_under.vframes = animations[current_anim].SfxUnder_vframes
		
		
# QUERIES --------------------------------------------------------------------------------------------------

func query(query_animations: Array): # return true if either current_anim or to_play_anim is of certain animations
	for query_animation in query_animations:
		if current_anim == query_animation or to_play_anim == query_animation:
			return true
	return false
	
func query_to_play(query_animations: Array): # return true if to_play_anim is of certain animations
	for query_animation in query_animations:
		if to_play_anim == query_animation:
			return true
	return false
	
func query_current(query_animations: Array): # return true if to_play_anim is of certain animations
	for query_animation in query_animations:
		if current_anim == query_animation:
			return true
	return false
	
# request for a certain polygon, return null if no such polygon
func query_polygon(target = "hurtbox"):
	var owner_pos = get_parent().position
	
	# first, find the latest frame
	var new_time = time
	if !new_time in animations[to_play_anim]["timestamps"]:
		while new_time > 0:
			new_time -= 1
			if new_time in animations[to_play_anim]["timestamps"]:
				break 
		
	if target in animations[to_play_anim]["timestamps"][new_time]:
		var polygon = animations[to_play_anim]["timestamps"][new_time][target].duplicate()
		if "facing" in get_parent(): # mirrored if facing other way
			for index in polygon.size():
				polygon[index].x *= get_parent().facing
		if "v_facing" in get_parent():
			for index in polygon.size():
				polygon[index].y *= get_parent().v_facing
		if polygon.size() == 0: # return null if empty polygon
			return null
		else:
			for index in polygon.size():
				polygon[index] += owner_pos
			return polygon
	else:
		return null
		
# request for a certain point, return null if no such point
func query_point(target = "kborigin"):
	var owner_pos = get_parent().position
	
	# first, find the latest frame
	var new_time = time
	if !new_time in animations[to_play_anim]["timestamps"]:
		while new_time > 0:
			new_time -= 1
			if new_time in animations[to_play_anim]["timestamps"]:
				break 
		
	if target in animations[to_play_anim]["timestamps"][new_time]:
		var point = animations[to_play_anim]["timestamps"][new_time][target]
		if point == null: return null
		if "facing" in get_parent(): # mirrored if facing other way
			point.x *= get_parent().facing
		if "v_facing" in get_parent():
			point.y *= get_parent().v_facing
		return (point + owner_pos)
	else:
		return null
		

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"time" : time,
		"to_play_anim" : to_play_anim,
		"current_anim" : current_anim,
		"playing" : playing,
		"looped_back" : looped_back,
	}
	return state_data
	
func load_state(state_data):
	time = state_data.time
	to_play_anim = state_data.to_play_anim
	current_anim = state_data.current_anim
	playing = state_data.playing
	looped_back = state_data.looped_back
	
	if current_anim != "":
		# when loading, time can be between frames, if so, rollback to last timestamp
		if !time in animations[current_anim]["timestamps"]:
			var new_time
			
			if "loop_section" in animations[current_anim]: # for looped sections
				new_time = posmod(time, animations[current_anim].loop_section)
			else: # for normal animations
				new_time = time
				
#			while new_time > 0:
#				new_time -= 1
#				if new_time in animations[current_anim]["timestamps"]:
#					set_up_texture()
#					process_timestamp(new_time)
#					break 
					
			var result = Globals.timestamp_find(animations[current_anim].timestamps.keys(), new_time, true)
			if result != null:
				set_up_texture()
				process_timestamp(result)
			else:
				print("Error: Unable to find timestamp when loading animation " + current_anim + " at time: " + str(new_time))
			
			
		else:
			set_up_texture()
			process_timestamp(time)
#	else: # load on 1st frame
#		if time == 0:
#			set_up_texture()
#			process_timestamp(0)
	
#--------------------------------------------------------------------------------------------------

