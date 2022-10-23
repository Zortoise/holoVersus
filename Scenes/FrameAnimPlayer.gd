extends Node

# this can play animations other than frame data for sprites
# set animation list by extending this animation player

signal anim_started (anim_name)
signal anim_finished (anim_name)
signal change_spritesheet(spritesheet_filename) # only connect this if needed
signal change_SfxOver_spritesheet(SfxOver_spritesheet_filename)
signal change_SfxUnder_spritesheet(SfxUnder_spritesheet_filename)
signal frame_update () # currently used for staggering audio

var sprite # sprite to animate
var sfx_over
var sfx_under

var time := 0 # increase by 1 each frame, used to check for timestamps
var to_play_animation: String # since current_animation should only be changed on render
var current_animation: String
var playing := false
var looped_back := false # if true, do not emit anim_started when starting

# set this in node extending this
var animations = {}

	
# load and play an animation
func play(anim):
	if anim in animations:
		playing = true
		to_play_animation = anim
		time = 0
		looped_back = false
		
func stop():
	playing = false
	
func is_playing():
	if time >= animations[current_animation].duration - 1 and !animations[current_animation].loop:
		return false
	else: return true

# run every physics tick
func stimulate():
	if playing:
		current_animation = to_play_animation
		
		if time == 0:
			if !looped_back:
				emit_signal("anim_started", current_animation)
			set_up_texture()
		
		# if has loop section, just loop the section till animtion finishes, good for modulate animations
		if "loop_section" in animations[current_animation]:
			if time % animations[current_animation].loop_section in animations[current_animation]["timestamps"]:
				process_timestamp(time % animations[current_animation].loop_section)
		# no loop section, process normally
		elif time in animations[current_animation]["timestamps"]:
			process_timestamp(time)
			
		if time >= animations[current_animation].duration - 1: # increment time_count if not completed yet
			if animations[current_animation].loop:
				time = 0
				looped_back = true
			else:
				emit_signal("anim_finished", current_animation)
				return
		else:
			time += 1


func process_timestamp(timestamp):
	if "frame" in animations[current_animation]["timestamps"][timestamp]:
		sprite.frame = animations[current_animation]["timestamps"][timestamp].frame
		emit_signal("frame_update")
	if "modulate" in animations[current_animation]["timestamps"][timestamp]:
		sprite.modulate.r = animations[current_animation]["timestamps"][timestamp].modulate.r
		sprite.modulate.g = animations[current_animation]["timestamps"][timestamp].modulate.g
		sprite.modulate.b = animations[current_animation]["timestamps"][timestamp].modulate.b
	if "fade" in animations[current_animation]["timestamps"][timestamp]:
		sprite.modulate.a = animations[current_animation]["timestamps"][timestamp].fade
	# add more later?
	
	if "SfxOver_frame" in animations[current_animation]["timestamps"][timestamp]:
		sfx_over.frame = animations[current_animation]["timestamps"][timestamp].SfxOver_frame
		sfx_over.scale.x = sprite.scale.x
	if "SfxUnder_frame" in animations[current_animation]["timestamps"][timestamp]:
		sfx_under.frame = animations[current_animation]["timestamps"][timestamp].SfxUnder_frame
		sfx_under.scale.x = sprite.scale.x
		
# handle changing spritesheets, triggered at start of every animation
func set_up_texture():
	
	if "spritesheet" in animations[current_animation]:
		emit_signal("change_spritesheet", animations[current_animation].spritesheet)
	if "hframes" in animations[current_animation]:
		sprite.hframes = animations[current_animation].hframes
	if "vframes" in animations[current_animation]:
		sprite.vframes = animations[current_animation].vframes
		
	if "SfxOver_spritesheet" in animations[current_animation]:
		emit_signal("change_SfxOver_spritesheet", animations[current_animation].SfxOver_spritesheet)
	if "SfxOver_hframes" in animations[current_animation]:
		sfx_over.hframes = animations[current_animation].SfxOver_hframes
	if "SfxOver_vframes" in animations[current_animation]:
		sfx_over.vframes = animations[current_animation].SfxOver_vframes
		
	if "SfxUnder_spritesheet" in animations[current_animation]:
		emit_signal("change_SfxUnder_spritesheet", animations[current_animation].SfxUnder_spritesheet)		
	if "SfxUnder_hframes" in animations[current_animation]:
		sfx_under.hframes = animations[current_animation].SfxUnder_hframes
	if "SfxUnder_vframes" in animations[current_animation]:
		sfx_under.vframes = animations[current_animation].SfxUnder_vframes
		
		
# QUERIES --------------------------------------------------------------------------------------------------

func query(query_animations: Array): # return true if either current_animation or to_play_animation is of certain animations
	for query_animation in query_animations:
		if current_animation == query_animation or to_play_animation == query_animation:
			return true
	return false
	
func query_to_play(query_animations: Array): # return true if to_play_animation is of certain animations
	for query_animation in query_animations:
		if to_play_animation == query_animation:
			return true
	return false
	
func query_current(query_animations: Array): # return true if to_play_animation is of certain animations
	for query_animation in query_animations:
		if current_animation == query_animation:
			return true
	return false
	
# request for a certain polygon, return null if no such polygon
func query_polygon(target = "hurtbox"):
	
	# first, find the latest frame
	var new_time = time
	if !new_time in animations[to_play_animation]["timestamps"]:
		while new_time > 0:
			new_time -= 1
			if new_time in animations[to_play_animation]["timestamps"]:
				break 
		
	if target in animations[to_play_animation]["timestamps"][new_time]:
		var polygon = animations[to_play_animation]["timestamps"][new_time][target].duplicate()
		if "facing" in get_parent(): # mirrored if facing other way
			for index in polygon.size():
				polygon[index].x *= get_parent().facing
		if polygon.size() == 0: # return null if empty polygon
			return null
		else:
			return polygon
	else:
		return null
		
# request for a certain point, return null if no such point
func query_point(target = "kborigin"):
	
	# first, find the latest frame
	var new_time = time
	if !new_time in animations[to_play_animation]["timestamps"]:
		while new_time > 0:
			new_time -= 1
			if new_time in animations[to_play_animation]["timestamps"]:
				break 
		
	if target in animations[to_play_animation]["timestamps"][new_time]:
		var point = animations[to_play_animation]["timestamps"][new_time][target]
		if point == null: return null
		if "facing" in get_parent(): # mirrored if facing other way
			point.x *= get_parent().facing
		return point
	else:
		return null
		

# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"time" : time,
		"to_play_animation" : to_play_animation,
		"current_animation" : current_animation,
		"playing" : playing,
		"looped_back" : looped_back,
	}
	return state_data
	
func load_state(state_data):
	time = state_data.time
	to_play_animation = state_data.to_play_animation
	current_animation = state_data.current_animation
	playing = state_data.playing
	looped_back = state_data.looped_back
	
	if current_animation != "":
		# when loading, time can be between frames, if so, rollback to last timestamp
		if !time in animations[current_animation]["timestamps"]:
			var new_time
			
			if "loop_section" in animations[current_animation]: # for looped sections
				new_time = time % animations[current_animation].loop_section
			else: # for normal animations
				new_time = time
				
			while new_time > 0:
				new_time -= 1
				if new_time in animations[current_animation]["timestamps"]:
					set_up_texture()
					process_timestamp(new_time)
					break 
		else:
			set_up_texture()
			process_timestamp(time)
	
#--------------------------------------------------------------------------------------------------

