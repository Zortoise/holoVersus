extends AudioStreamPlayer

var free := false

var audio_ref: String
var unique_path
var volume_target := 0

var decay := false

var time := -1 # so that 1st frame is 0, stimulate() will call once before the first _process()
# _physics_process() will not call on frame the node is created
var processed := false # not saved, used to indicate the 1st frame not stimulated


func init(in_audio_ref: String, aux_data: Dictionary):

	audio_ref = in_audio_ref
	
	if "bus" in aux_data:
		bus = aux_data.bus
		
	if "unique_path" in aux_data: # load unique audio
		unique_path = aux_data.unique_path
		stream = get_node(aux_data.unique_path).unique_audio[audio_ref]
	else:
		stream = LoadedSFX.loaded_audio[audio_ref]
		
	if "vol" in aux_data:
		volume_target = aux_data.vol
	
#	if "pitch" in aux_data: # only set in certain circumstances
#		pitch_scale = aux_data.pitch

	if !Netplay.is_netplay():
		volume_db = volume_target
		play()	

			
func _process(delta):
		
	if processed:
		if !decay: # set volume changes, if not at target volume raise up to it, if decaying raise down
			if volume_db < volume_target:
				volume_db = Globals.sin_lerp(-80.0, volume_target, abs(volume_db + 80.0) / abs(volume_target + 80.0) + 1.0 * delta)
			if volume_db > volume_target:
				volume_db = volume_target
		else: # decaying
			if volume_db > -80.0:
				volume_db = Globals.sin_lerp(volume_target, -80.0, abs(volume_db - volume_target) / abs( volume_target + 80.0) + 1.0 * delta)
			if volume_db <= -80.0:
				queue_free()
			
	else: # run only once
		# stopped being stimulated/loaded in, start from a certain position based on time
		processed = true
		if Netplay.is_netplay():
			if time < 0: # audio glitch
				free = true
			elif time == 0:
				volume_db = volume_target
				play()
			else:
				volume_db = -80.0
				play(max(time, 0) * Globals.FRAME)


	
func stimulate():
	time += 1
	if time * Globals.FRAME >= stream.get_length(): # if overshooting stream length
		free = true
			
	
func kill(): # called when loading state, kill the original node by transferring it to main game scene, then start fading away
	decay = true
	get_parent().remove_child(self)
	Globals.Game.get_node("DecayAudio").add_child(self)
	
	
# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var state_data = {
		"audio_ref" : audio_ref,
		"bus" : bus,
		"unique_path" : unique_path,
		"time" : time,
		"volume_target" : volume_target,
		"free" : free
#		"pitch" : pitch_scale,
	}
	return state_data
	
func load_state(state_data):
	audio_ref = state_data.audio_ref
	bus = state_data.bus
	unique_path = state_data.unique_path
	time = state_data.time
	volume_target = state_data.volume_target
	free = state_data.free
#	pitch_scale = state_data.pitch
	
	if !unique_path:
		stream = LoadedSFX.loaded_audio[audio_ref]
	else: # load unique audio
		stream = get_node(unique_path).unique_audio[audio_ref]



	
#--------------------------------------------------------------------------------------------------
