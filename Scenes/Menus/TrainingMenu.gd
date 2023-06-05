extends Node2D

const ASSISTS_OPTIONS = ["off", "select", "item - low", "item - medium", "item - high"]
const STATICSTAGE_OPTIONS = ["off", "on"]
var custom_playlist_options = ["none"] # can be added to


func _ready():
	
	BGM.bgm(BGM.common_music["title_theme"])
	
	# WIP, load custom playlists here
	
	$LocalList/Assists.disable()
	$LocalList/CustomPlaylist.disable()
	
	for node in $LocalList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$LocalList/StartGame.initial_focus()
	
	var training_config = Settings.load_training_config() # set up loaded values
	$LocalList/Assists.load_button("Assists", ASSISTS_OPTIONS, training_config.assists)
	$LocalList/StaticStage.load_button("Static Stage", STATICSTAGE_OPTIONS, training_config.static_stage)
	$LocalList/CustomPlaylist.load_button("Custom Playlist", custom_playlist_options, training_config.custom_playlist)


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		play_audio("ui_back", {})
		$Transition.play("transit_to_main")


func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)


func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"Reset":
				var training_config = {
					"assists" : 0,
					"static_stage" : 0,
					"custom_playlist" : 0,
				}
				play_audio("ui_accept", {"vol":-8})
				$LocalList/Assists.change_pointer(training_config.assists)
				$LocalList/StaticStage.change_pointer(training_config.static_stage)
				$LocalList/CustomPlaylist.change_pointer(training_config.custom_playlist)
			"StartGame":
				var training_config = {
					"assists" : $LocalList/Assists.option_pointer,
					"static_stage" : $LocalList/StaticStage.option_pointer,
					"custom_playlist" : $LocalList/CustomPlaylist.option_pointer,
				}
				Settings.save_training_config(training_config)
				play_audio("ui_accept2", {})
				BGM.fade()
				$Transition.play("transit_to_char_select")
				Globals.assists = training_config.assists
				Globals.static_stage = training_config.static_stage
				Globals.survival_level = null
				Globals.player_count = 2
			"Return":
				play_audio("ui_back", {})
				$Transition.play("transit_to_main")

			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)


