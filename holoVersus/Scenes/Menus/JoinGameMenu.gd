extends Node2D

const HOSTSIDE_OPTIONS = ["P1", "P2"]
const DELAYFRAMES_OPTIONS = ["none", "1 frame", "2 frames", "3 frames", "4 frames", "5 frames", "6 frames",
		"7 frames", "8 frames", "9 frames", "10 frames"]
const MAXROLLBACK_OPTIONS = ["20 frames", "25 frames", "30 frames",
		"35 frames", "40 frames", "45 frames", "50 frames", "55 frames", "60 frames",]
const STOCKPOINTS_OPTIONS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, \
		14, 15, 16, 17, 18, 19, 20]
const TIMELIMIT_OPTIONS = ["none", 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 360, 390, 420, 445, 480, 510, \
		540, 570, 600, 630, 660, 690, 710, 750, 780, 810, 840, 870, 900, 930, 960, 999]
#const ASSISTS_OPTIONS = ["off", "select", "item - low", "item - medium", "item - high"]
const ASSISTS_OPTIONS = ["off", "select", "item - low", "item - medium", "item - high"]
const STATICSTAGE_OPTIONS = ["off", "on"]
#var custom_playlist_options = ["none"] # can be added to

var host_net_game_config = {}

var host_readied := false
var guest_readied := false

func _ready():
	
	BGM.play_random_in_folder("Common/TitleThemes")
	
	Netplay.lobby = self
	
	# WIP, load custom playlists here
	
#	$JoinList/CustomPlaylist.disable()
	
	for node in $JoinList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$JoinList/Ready.initial_focus()
	
#	$JoinList/CustomPlaylist.load_button("Custom Playlist", custom_playlist_options, 0)

	# update match data from host
	$MatchList2/HostSide.text = "-"
	$MatchList2/InputDelay.text = "-"
	$MatchList2/MaxRollback.text = "-"
	$MatchList2/StockPoints.text = "-"
	$MatchList2/TimeLimit.text = "-"
	$MatchList2/Assists.text = "-"
	$MatchList2/StaticStage.text = "-"
	rpc_id(1, "setup_settings_for_guest")
	
	# fill player list
	$PlayerList/PlayersList/Player1/Name.text = " " + Netplay.player_list[0].profile_name
	$PlayerList/PlayersList/Player2/Name.text = " " + Netplay.profile_name
	
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	
func _server_disconnected(): # host disconnected
	play_audio("ui_deny", {"vol" : -9})
	Netplay.connection_issue(1, self, "_server_disconnected2")
	
func _server_disconnected2(): # host disconnected
	play_audio("ui_back", {})
	$Transition.play("transit_to_search")
	Netplay.stop_hosting_or_searching()

	

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if guest_readied:
			rpc_id(1, "guest_ready", false)
			
	# update ping
	if Netplay.is_netplay() and Netplay.ping != null:
		$PlayerList/PlayersList/Player2/Ping.text = str(round(Netplay.ping * 1000)) + "ms (" + str(ceil(Netplay.ping * 30)) + "f)"
		
	# start game
	if host_readied and guest_readied:
		start_game()
		
		
func start_game():
	BGM.fade()
	$Transition.play("transit_to_char_select_net")
	
	Netcode.input_delay = host_net_game_config.input_delay
	Netcode.max_rollback = (host_net_game_config.max_rollback * 5) + 20
	match host_net_game_config.host_side:
		0: # host is P1
			Netplay.player_list[0].player_id = 0
			Netplay.player_list[1].player_id = 1
		1: # host is P2
			Netplay.player_list[0].player_id = 1
			Netplay.player_list[1].player_id = 0
	Globals.starting_stock_pts = STOCKPOINTS_OPTIONS[host_net_game_config.stock_points]
	Globals.time_limit = TIMELIMIT_OPTIONS[host_net_game_config.time_limit]
	if Globals.time_limit is String: Globals.time_limit = 0
	Globals.assists = host_net_game_config.assists
	Globals.static_stage = host_net_game_config.static_stage
	Globals.survival_level = null
	Globals.player_count = 2
	

func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"Ready":
				if !guest_readied:
					rpc_id(1, "guest_ready", true)
				else:
					rpc_id(1, "guest_ready", false)
			"Return":
				play_audio("ui_back", {})
				$Transition.play("transit_to_search")
				Netplay.stop_hosting_or_searching()
			

# ----------------------------------------------------------------------------------------------------------------------------------------

puppet func guest_ready_acknowledged(ready_state: bool):
	if ready_state:
		if !guest_readied:
			play_audio("ui_accept2", {})
			$PlayerList/PlayersList/Player2/Ready/AnimationPlayer.play("flashing")
			guest_readied = true
	else:
		if guest_readied:
			play_audio("ui_back", {})
			$PlayerList/PlayersList/Player2/Ready/AnimationPlayer.play("fade")
			guest_readied = false

puppet func host_ready(ready_state: bool): # rpc-ed by host when they click ready
	host_readied = ready_state
	if host_readied:
		$PlayerList/PlayersList/Player1/Ready/AnimationPlayer.play("flashing")
	else:
		$PlayerList/PlayersList/Player1/Ready/AnimationPlayer.play("fade")
	rpc_id(1, "host_ready_acknowledged", ready_state)
	
puppet func host_changed_settings(in_host_net_game_config: Dictionary): # rpc-ed by host when they change match settings
	host_net_game_config = in_host_net_game_config
	$MatchList2/HostSide.text = HOSTSIDE_OPTIONS[host_net_game_config.host_side]
	$MatchList2/InputDelay.text = DELAYFRAMES_OPTIONS[host_net_game_config.input_delay]
	$MatchList2/MaxRollback.text = MAXROLLBACK_OPTIONS[host_net_game_config.max_rollback]
	$MatchList2/StockPoints.text = str(STOCKPOINTS_OPTIONS[host_net_game_config.stock_points])
	$MatchList2/TimeLimit.text = str(TIMELIMIT_OPTIONS[host_net_game_config.time_limit])
	$MatchList2/Assists.text = ASSISTS_OPTIONS[host_net_game_config.assists]
	$MatchList2/StaticStage.text = STATICSTAGE_OPTIONS[host_net_game_config.static_stage]
	rpc_id(1, "guest_ready", false)
			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
	Netplay.lobby = null
	Globals.next_scene = new_scene
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/LoadingScreen.tscn")
	
func force_start_game():
	if !$Transition.is_playing():
		start_game()
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)

