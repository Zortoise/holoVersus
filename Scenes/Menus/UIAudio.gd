extends AudioStreamPlayer


func init(audio_ref: String, aux_data: Dictionary):
	
	stream = LoadedSFX.loaded_ui_audio[audio_ref]
	
	if "bus" in aux_data:
		bus = aux_data.bus
	if "vol" in aux_data:
		volume_db = aux_data.vol
	
	play()
	

func _on_UIAudio_finished():
	queue_free()
