extends Node2D

const FULLSCREEN_OPTIONS = ["off", "on"]
const WINDOWSIZE_OPTIONS = ["1280 x 720", "1600 x 900", "1920 x 1080"]
const BORDERLESS_OPTIONS = ["off", "on"]
const VSYNC_OPTIONS = ["off", "on", "via compositor"]
const FPSLOCK_OPTIONS = ["uncapped", "on"]
const FPSPING_OPTIONS = ["off", "on"]


func _ready():
	for node in $SettingsList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	for node in $SettingsList2.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$SettingsList2.get_node(Globals.settings_menu_focus).initial_focus()
	Globals.settings_menu_focus = "Change"
	
	var config = Settings.load_settings() # set up loaded values
	$SettingsList/Fullscreen.load_button("Fullscreen", FULLSCREEN_OPTIONS, config.fullscreen)
	$SettingsList/WindowSize.load_button("Window Size", WINDOWSIZE_OPTIONS, config.window_size)
	$SettingsList/Borderless.load_button("Borderless", BORDERLESS_OPTIONS, config.borderless)
	$SettingsList/Vsync.load_button("Vsync", VSYNC_OPTIONS, config.vsync)
	$SettingsList/FPSLock.load_button("60FPS Cap", FPSLOCK_OPTIONS, config.fps_lock)
	$SettingsList/FPSandPing.load_button("Show FPS/Ping", FPSPING_OPTIONS, config.fps_and_ping)
	$SettingsList/GameVolume.load_button("Game Volume", config.game_volume)
	$SettingsList/MusicVolume.load_button("Music Volume", config.music_volume)
	$SettingsList/UIVolume.load_button("UI Volume", config.ui_volume)
	
	
func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if $SettingsList2.get_focus_owner().get_parent().name == "SettingsList2":
			var new_config = {
				"fullscreen" : $SettingsList/Fullscreen.option_pointer,
				"window_size" : $SettingsList/WindowSize.option_pointer,
				"borderless" : $SettingsList/Borderless.option_pointer,
				"vsync" : $SettingsList/Vsync.option_pointer,
				"fps_lock" : $SettingsList/FPSLock.option_pointer,
				"fps_and_ping" : $SettingsList/FPSandPing.option_pointer,
				"game_volume" : $SettingsList/GameVolume.value,
				"music_volume" : $SettingsList/MusicVolume.value,
				"ui_volume" : $SettingsList/UIVolume.value,
			}
			Settings.save_settings(new_config)
			play_audio("ui_accept", {"vol":-8})
			$Transition.play("transit_to_main")
		else:
			$SettingsList2/Change.initial_focus()
			play_audio("ui_back", {})
	
	
func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)


func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"Change":
				play_audio("ui_accept", {"vol":-8})
				$SettingsList/Fullscreen.initial_focus()
			"Save":
				var new_config = {
					"fullscreen" : $SettingsList/Fullscreen.option_pointer,
					"window_size" : $SettingsList/WindowSize.option_pointer,
					"borderless" : $SettingsList/Borderless.option_pointer,
					"vsync" : $SettingsList/Vsync.option_pointer,
					"fps_lock" : $SettingsList/FPSLock.option_pointer,
					"fps_and_ping" : $SettingsList/FPSandPing.option_pointer,
					"game_volume" : $SettingsList/GameVolume.value,
					"music_volume" : $SettingsList/MusicVolume.value,
					"ui_volume" : $SettingsList/UIVolume.value,
				}
				Settings.save_settings(new_config)
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_main")
			"Replays":
#				Settings.load_settings() # return to saved settings
				play_audio("ui_accept", {"vol":-8})
				$Transition.play("transit_to_replays")
				Globals.settings_menu_focus = "Replays"
			"Discard":
#				Settings.load_settings() # return to saved settings
				play_audio("ui_back", {})
				$Transition.play("transit_to_main")
			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)
	
func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)
	

