extends Node2D

var fade_sound := false # for fading out sound when transiting to other scenes

func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameFade"), 0.0)
	$Test.show()
	$HUD/FrameViewer.hide()
	$HUD/P1_HUDRect/Inputs.hide()
	$HUD/P2_HUDRect/Inputs.hide()
	
	if Netplay.is_netplay():
# warning-ignore:return_value_discarded
		get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
# warning-ignore:return_value_discarded
		get_tree().connect("server_disconnected", self, "_server_disconnected")
		
		$HUD/P1_HUDRect/Portrait/ProfileName.show()
		$HUD/P1_HUDRect/Portrait/ProfileName.text = Netplay.get_profile_name_from_player_id(0)
		$HUD/P2_HUDRect/Portrait/ProfileName.show()
		$HUD/P2_HUDRect/Portrait/ProfileName.text = Netplay.get_profile_name_from_player_id(1)
		
	elif Globals.watching_replay and Globals.replay_is_netgame:
		$HUD/P1_HUDRect/Portrait/ProfileName.show()
		$HUD/P1_HUDRect/Portrait/ProfileName.text = Globals.replay_profiles[0]
		$HUD/P2_HUDRect/Portrait/ProfileName.show()
		$HUD/P2_HUDRect/Portrait/ProfileName.text = Globals.replay_profiles[1]
		
	
func set_fade_sound(): # fade out sound when transiting to other scenes, called by animation
	fade_sound = true
	

func _physics_process(_delta):
	
	if Globals.debug_mode2:
		$Test/Frametime.show()
		$Test/TrueFrametime.show()
		$Test/Frametime.text = "FRAME: " + str($ViewportContainer/Viewport/Game.frametime)
		$Test/TrueFrametime.text = "PRESENT: " + str($ViewportContainer/Viewport/Game.true_frametime)
	else:
		$Test/Frametime.hide()
		$Test/TrueFrametime.hide()
	
	# show playspeed
	if $ViewportContainer/Viewport/Game.play_speed == 0:
		$Test/Playspeed.text = "PAUSED"
		$Test/Playspeed.show()
	elif $ViewportContainer/Viewport/Game.play_speed > 1:
		$Test/Playspeed.text = "X " + str($ViewportContainer/Viewport/Game.play_speed) + " SPEED"
		$Test/Playspeed.show()
	else:
		$Test/Playspeed.hide()
	
	# fade out Save/Load text after a while
	if $Test/SaveLoad/Timer.is_stopped():
		$Test/SaveLoad.modulate.a = lerp($Test/SaveLoad.modulate.a, 0, 0.1)
		
	# zooming in and out based on zoom_level, zoom_level 2 is x3 pixel, zoom_level 1 is x2 pixel, zoom_level 0 is actual pixel
	$ViewportContainer.rect_scale = Vector2(1.0 + Globals.zoom_level, 1.0 + Globals.zoom_level)
	$ViewportContainer/Viewport.size = Vector2(1920.0, 1080.0) / $ViewportContainer.rect_scale
	
	
	if $ViewportContainer/Viewport/Game.playback_mode:
		pass
		$Test/Playback.show()
	else:
		$Test/Playback.hide()
		
	# pausing game
	if !Netplay.is_netplay():
		if Globals.pausing and !$HUD/HoldToPause/AnimationPlayer.is_playing():
			$HUD/HoldToPause/AnimationPlayer.play("hold")
		elif !Globals.pausing and $HUD/HoldToPause/AnimationPlayer.is_playing():
			$HUD/HoldToPause/AnimationPlayer.play("RESET")
		
	# 
	if fade_sound: # fade out sound when transiting to other scenes
		var volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("GameFade"))
		volume = lerp(volume, -60.0, 0.2)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("GameFade"), volume)
		
		
	if Globals.Game.frametime == 36:
		$HUD/Announcer/AnimationPlayer.play("start_battle")
	
	if Globals.Game.frametime == 126:
		start_battle()


func start_battle():
	Globals.Game.input_lock = false
	if Globals.Game.you_label != null and is_instance_valid(Globals.Game.you_label):
		Globals.Game.you_label.free()
	
	
func _on_Game_game_set():
	$HUD/Announcer/AnimationPlayer.play("game_set")
	
func _on_Game_time_over():
	$HUD/Announcer/AnimationPlayer.play("time_over")

func _on_Game_loaded_state():
	$Test/SaveLoad.show()
	$Test/SaveLoad.text = "STATE LOADED"
	$Test/SaveLoad.modulate.a = 1.0
	$Test/SaveLoad/Timer.wait_time = 0.5
	$Test/SaveLoad/Timer.start()

func _on_Game_saved_state():
	$Test/SaveLoad.show()
	$Test/SaveLoad.text = "STATE SAVED"
	$Test/SaveLoad.modulate.a = 1.0
	$Test/SaveLoad/Timer.wait_time = 0.5
	$Test/SaveLoad/Timer.start()

func _on_Game_record_ended():
	$Test/SaveLoad.show()
	$Test/SaveLoad.text = "RECORD ENDED"
	$Test/SaveLoad.modulate.a = 1.0
	$Test/SaveLoad/Timer.wait_time = 0.5
	$Test/SaveLoad/Timer.start()
	

# ------------------------------------------------------------------------------------------------------------
	
func change_scene(new_scene: String): # called by animation
	
	# save these 2 before restoring controls so that they can be saved to replays
	Globals.temp_input_buffer_time = Settings.input_buffer_time.duplicate(true)
	Globals.temp_tap_jump = Settings.tap_jump.duplicate(true)
	Globals.temp_dj_fastfall = Settings.dj_fastfall.duplicate(true)
	
	# change controls back to normal, don't do "if Netplay.is_netplay()" in case of disconnection
# warning-ignore:return_value_discarded
	Settings.change_input_map(Settings.load_input_map())

	Netcode.game_ongoing = false
	if Netplay.is_netplay():
		if new_scene == "res://Scenes/Menus/VictoryScreen.tscn":
			new_scene = "res://Scenes/Menus/VictoryScreenNet.tscn" # route to VictoryScreenNet for netgames
			
	elif Globals.watching_replay:
		if new_scene == "res://Scenes/Menus/VictoryScreen.tscn":
			new_scene = "res://Scenes/Menus/VictoryScreenReplay.tscn" # route to VictoryScreenReplay for relays
		Globals.watching_replay = false
		
	get_tree().change_scene(new_scene)
	
	
func force_game_over(winner_ID):
	Globals.winner = [winner_ID, Globals.Game.get_player_node(winner_ID).UniqueCharacter.NAME]
	$Transition.play("transit_to_victory")
	
func _player_disconnected(_id): # opponent disconnected
	play_audio("ui_deny", {"vol" : -9})
	Netplay.connection_issue(2, self, "_player_disconnected2")
	
func _server_disconnected():
	play_audio("ui_deny", {"vol" : -9})
	Netplay.connection_issue(2, self, "_player_disconnected2")
	
func _player_disconnected2(): # opponent disconnected
	play_audio("ui_back", {})
	$Transition.play("transit_to_netplay")
	Netplay.stop_hosting_or_searching()
	
remote func rollback_over_limit():
	if Netcode.game_ongoing:
		play_audio("ui_deny", {"vol" : -9})
		Netplay.connection_issue(3, self, "_player_disconnected2")
		rpc("rollback_over_limit")
	
remote func gap_in_input():
	if Netcode.game_ongoing:
		play_audio("ui_deny", {"vol" : -9})
		Netplay.connection_issue(4, self, "_player_disconnected2")
		rpc("gap_in_input")
	
remote func desync_escape():
	if Netcode.game_ongoing:
		play_audio("ui_deny", {"vol" : -9})
		Netplay.connection_issue(5, self, "_player_disconnected2")
		rpc("desync_escape")
	
remote func positions_desync():
	if Netcode.game_ongoing:
		Globals.Game.export_logs()
		play_audio("ui_deny", {"vol" : -9})
		Netplay.connection_issue(6, self, "_player_disconnected2")
		rpc("positions_desync")
	
remote func positions_desync2():
	if Netcode.game_ongoing:
		play_audio("ui_deny", {"vol" : -9})
		Netplay.connection_issue(7, self, "_player_disconnected2")
		rpc("positions_desync2")

# ------------------------------------------------------------------------------------------------------------

func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
