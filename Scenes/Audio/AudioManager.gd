extends AudioStreamPlayer

var free := false

var audio_ref: String
var volume_target := 0

var decay := false

var time = 0.0

var confirmed := false # rollback confirmed, will not remove


func init(in_audio_ref: String, aux_data: Dictionary):

	audio_ref = in_audio_ref
	
	if "bus" in aux_data:
		bus = aux_data.bus
		
	if Globals.survival_level != null and "surv" in aux_data:
		stream = Globals.Game.LevelControl.unique_audio[audio_ref]
	elif "unique_path" in aux_data: # load unique audio
		stream = get_node(aux_data.unique_path).unique_audio[audio_ref]
	elif "mob_ref" in aux_data:
		stream = Globals.Game.LevelControl.mob_data[aux_data.mob_ref].unique_audio[audio_ref]
	else:
		stream = LoadedSFX.loaded_audio[audio_ref]
		
	if "vol" in aux_data:
		volume_target = aux_data.vol
	
#	if "pitch" in aux_data: # only set in certain circumstances
#		pitch_scale = aux_data.pitch

	volume_db = volume_target
	play()	

			
func _process(_delta):
	if decay:
		if volume_db > -80.0:
			volume_db = lerp(volume_db, -90.0, 0.5)
		if volume_db <= -80.0:
			queue_free()
			
func _physics_process(_delta):
	time += 1
		
func _on_AudioManager_finished():
	queue_free()

#func simulate():
#	time += 1
#	if time * Globals.FRAME >= stream.get_length(): # if overshooting stream length
#		free = true
			
	
func kill():
	decay = true
	get_parent().remove_child(self)
	Globals.Game.get_node("DecayAudio").add_child(self)
	
	
# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------
#
#func save_state():
#	var state_data = {
#		"audio_ref" : audio_ref,
#		"bus" : bus,
#		"unique_path" : unique_path,
#		"time" : time,
#		"volume_target" : volume_target,
#		"free" : free
##		"pitch" : pitch_scale,
#	}
#	return state_data
#
#func load_state(state_data):
#	audio_ref = state_data.audio_ref
#	bus = state_data.bus
#	unique_path = state_data.unique_path
#	time = state_data.time
#	volume_target = state_data.volume_target
#	free = state_data.free
##	pitch_scale = state_data.pitch
#
#	if !unique_path:
#		stream = LoadedSFX.loaded_audio[audio_ref]
#	else: # load unique audio
#		stream = get_node(unique_path).unique_audio[audio_ref]



	
#--------------------------------------------------------------------------------------------------



