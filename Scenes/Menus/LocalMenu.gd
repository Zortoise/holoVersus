extends Node2D

const GAMEMODE_OPTIONS = ["1 v 1", "3 players FFA", "4 players FFA", "2 v 2"]
const STOCKPOINTS_OPTIONS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, \
		14, 15, 16, 17, 18, 19, 20]
const TIMELIMIT_OPTIONS = ["none", 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420, 445, 480, 510, \
		540, 570, 600, 630, 660, 690, 710, 750, 780, 810, 840, 870, 900, 930, 960, 999]
const ASSISTS_OPTIONS = ["off", "select", "item - low", "item - medium", "item - high"]
const STATICSTAGE_OPTIONS = ["off", "on"]
var custom_playlist_options = ["none"] # can be added to


func _ready():
	
	BGM.bgm(BGM.common_music["title_theme"])
	
	# WIP, load custom playlists here
	
	$LocalList/GameMode.disable() # HBoxContainer buttons have to be disabled in code
	$LocalList/Assists.disable()
	$LocalList/CustomPlaylist.disable()
	
	for node in $LocalList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$LocalList/StartGame.initial_focus()
	
	var game_config = Settings.load_game_config() # set up loaded values
	$LocalList/GameMode.load_button("Game Mode", GAMEMODE_OPTIONS, game_config.game_mode)
	$LocalList/StockPoints.load_button("Stock Points", STOCKPOINTS_OPTIONS, game_config.stock_points)
	$LocalList/TimeLimit.load_button("Time Limit", TIMELIMIT_OPTIONS, game_config.time_limit)
	$LocalList/Assists.load_button("Assists", ASSISTS_OPTIONS, game_config.assists)
	$LocalList/StaticStage.load_button("Static Stage", STATICSTAGE_OPTIONS, game_config.static_stage)
	$LocalList/CustomPlaylist.load_button("Custom Playlist", custom_playlist_options, game_config.custom_playlist)


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
				var game_config = {
					"game_mode" : 0,
					"stock_points" : 4,
					"time_limit" : 10,
					"assists" : 0,
					"static_stage" : 0,
					"custom_playlist" : 0,
				}
				play_audio("ui_accept", {"vol":-8})
				$LocalList/GameMode.change_pointer(game_config.game_mode)
				$LocalList/StockPoints.change_pointer(game_config.stock_points)
				$LocalList/TimeLimit.change_pointer(game_config.time_limit)
				$LocalList/Assists.change_pointer(game_config.assists)
				$LocalList/StaticStage.change_pointer(game_config.static_stage)
				$LocalList/CustomPlaylist.change_pointer(game_config.custom_playlist)
			"StartGame":
				var game_config = {
					"game_mode" : $LocalList/GameMode.option_pointer,
					"stock_points" : $LocalList/StockPoints.option_pointer,
					"time_limit" : $LocalList/TimeLimit.option_pointer,
					"assists" : $LocalList/Assists.option_pointer,
					"static_stage" : $LocalList/StaticStage.option_pointer,
					"custom_playlist" : $LocalList/CustomPlaylist.option_pointer,
				}
				Settings.save_game_config(game_config)
				play_audio("ui_accept2", {"vol":-5})
				BGM.fade()
				$Transition.play("transit_to_char_select")
				Globals.starting_stock_pts = STOCKPOINTS_OPTIONS[game_config.stock_points]
				Globals.time_limit = TIMELIMIT_OPTIONS[game_config.time_limit]
				if Globals.time_limit is String: Globals.time_limit = 0
				Globals.assists = game_config.assists
				Globals.static_stage = game_config.static_stage
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
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)


