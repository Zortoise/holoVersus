extends AudioStreamPlayer


# WIP, handle looping and music transitions (fade out)
var bgm_dictionary

var ended := false
var decaying := false # used to fade out music during transitions
var debug_quick_seek = false

func init(in_bgm_dictionary, loaded_stream = null, loop = false):
	
	bgm_dictionary = in_bgm_dictionary
	
	if loaded_stream == null:
		if "audio" in bgm_dictionary:
			stream = ResourceLoader.load(bgm_dictionary.audio)
		elif "stream" in bgm_dictionary:
			stream = bgm_dictionary.stream
	else:
		stream = loaded_stream

	if "vol" in bgm_dictionary:
		volume_db = bgm_dictionary.vol
		
	#if loop and "loop_start" in bgm_dictionary:
	#	var stream_len = bgm_dictionary.loop_start + bgm_dictionary.loop_end
	#	play(get_playback_position() - stream_len)
	#else:
	play()
	
	if debug_quick_seek:
		var stream_len = stream.get_length()
		if "loop_end" in bgm_dictionary:
			stream_len -= stream.get_length() - bgm_dictionary.loop_end
		seek(stream_len - 6)
		debug_quick_seek = false

func _process(delta):	
	if ended or decaying:
		if ("fade" in bgm_dictionary and bgm_dictionary.fade == true) or decaying:
			volume_db -= 60.0 * delta
			if volume_db <= -80:
				queue_free()
		
	else:
		if "loop_end" in bgm_dictionary and get_playback_position() >= bgm_dictionary.loop_end: # reach loop point
			# Changes to avoid hiccups in audio:
			# Instead of creating a new instance for looped tracks, we seek() the current instance to the new track position.
			# We also don't use loop_start directly: We subtract loop_length (If defined in the bgm_dictionary, it would be: loop_end - loop_start) from get_playback_position() in case any frames got dropped during the calculations
			# Finally, if we are somehow attempting to jump to a negative value, just seek to 0.0 

			var loop_len = 0
			if "loop_start" in bgm_dictionary:
				loop_len = bgm_dictionary.loop_end - bgm_dictionary.loop_start
			else:
				loop_len = bgm_dictionary.loop_end
				
			var stream_pos = get_playback_position()
			var new_pos = stream_pos - loop_len
			if (new_pos >= 0):
				seek(new_pos)
			else:
				seek(0.0)
			
func _on_BGMPlayer_finished():
	if ended and decaying:
		queue_free()
