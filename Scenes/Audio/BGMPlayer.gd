extends AudioStreamPlayer


# WIP, handle looping and music transitions (fade out)
var bgm_dictionary

var ended := false
var decaying := false # used to fade out music during transitions


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
		
	if loop and "loop_start" in bgm_dictionary:
		play(bgm_dictionary.loop_start)
	else:
		play()
		

func _process(delta):
	if ended or decaying:
		if "fade" in bgm_dictionary or decaying:
			volume_db -= 60.0 * delta
			if volume_db <= -80:
				queue_free()
		
	else:
		if "loop_end" in bgm_dictionary and get_playback_position() >= bgm_dictionary.loop_end: # reach loop point
			ended = true
			var BGMPlayer = BGM.BGMPlayerScene.instance()
			get_tree().get_root().add_child(BGMPlayer)
			BGMPlayer.init(bgm_dictionary, stream, true)
			
			
func _on_BGMPlayer_finished():
	
	if !ended and !decaying:
		if "loop_start" in bgm_dictionary:
			play(bgm_dictionary.loop_start)
		else:
			play(0.0)
			
	else:
		queue_free()
