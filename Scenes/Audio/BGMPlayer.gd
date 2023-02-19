extends AudioStreamPlayer


# WIP, handle looping and music transitions (fade out)
var bgm_dictionary

var decaying := false


func init(in_bgm_dictionary, loop = false):
	
	bgm_dictionary = in_bgm_dictionary
	stream = bgm_dictionary.audio

	if "vol" in bgm_dictionary:
		volume_db = bgm_dictionary.vol
		
	if loop and "loop_start" in bgm_dictionary:
		play(bgm_dictionary.loop_start)
	else:
		play()
		

func _process(delta):
	if decaying:
		volume_db -= 60.0 * delta
		if volume_db <= -80:
			queue_free()
		
	else:
		if "loop_end" in bgm_dictionary and get_playback_position() >= bgm_dictionary.loop_end: # reach loop point
			decaying = true
			var BGMPlayer = BGM.BGMPlayerScene.instance()
			get_tree().get_root().add_child(BGMPlayer)
			BGMPlayer.init(bgm_dictionary, true)
			
			
func _on_BGMPlayer_finished():
	
	if !decaying:
		if "loop_start" in bgm_dictionary:
			play(bgm_dictionary.loop_start)
		else:
			play(0.0)
