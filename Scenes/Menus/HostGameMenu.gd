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
const ASSISTS_OPTIONS = ["off", "select", "item - low", "item - medium", "item - high"]
const STATICSTAGE_OPTIONS = ["off", "on"]
var custom_playlist_options = ["none"] # can be added to

var host_private_ip := ""
var host_public_ip := ""
#var hide_ip := true

var host_readied := false
var guest_readied := false


func _ready():
	
	BGM.bgm(BGM.common_music["title_theme"])
	
	Netplay.lobby = self
	
	# WIP, load custom playlists here
	
	$HostList2/Assists.disable()
	$HostList2/CustomPlaylist.disable()
	
	for node in $HostList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	for node in $HostList2.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$HostList/Ready.initial_focus()
	
# warning-ignore:return_value_discarded
	$HostList2/HostSide.connect("shifted", self, "_setting_shifted")
# warning-ignore:return_value_discarded
	$HostList2/DelayFrames.connect("shifted", self, "_setting_shifted")
# warning-ignore:return_value_discarded
	$HostList2/MaxRollback.connect("shifted", self, "_setting_shifted")
# warning-ignore:return_value_discarded
	$HostList2/StockPoints.connect("shifted", self, "_setting_shifted")
# warning-ignore:return_value_discarded
	$HostList2/TimeLimit.connect("shifted", self, "_setting_shifted")
# warning-ignore:return_value_discarded
	$HostList2/Assists.connect("shifted", self, "_setting_shifted")
# warning-ignore:return_value_discarded
	$HostList2/StaticStage.connect("shifted", self, "_setting_shifted")
	
	var net_game_config = Netplay.load_net_game_config_host() # set up loaded values
	$HostList2/HostSide.load_button("Host's Side", HOSTSIDE_OPTIONS, net_game_config.host_side)
	$HostList2/DelayFrames.load_button("Input Delay", DELAYFRAMES_OPTIONS, net_game_config.input_delay)
	$HostList2/MaxRollback.load_button("Max Rollback", MAXROLLBACK_OPTIONS, net_game_config.max_rollback)
	$HostList2/StockPoints.load_button("Stock Points", STOCKPOINTS_OPTIONS, net_game_config.stock_points)
	$HostList2/TimeLimit.load_button("Time Limit", TIMELIMIT_OPTIONS, net_game_config.time_limit)
	$HostList2/Assists.load_button("Assists", ASSISTS_OPTIONS, net_game_config.assists)
	$HostList2/StaticStage.load_button("Static Stage", STATICSTAGE_OPTIONS, net_game_config.static_stage)
	$HostList2/CustomPlaylist.load_button("Custom Playlist", custom_playlist_options, 0)
	
	$PlayerList/PlayersList/Player1/Name.text = " " + Netplay.profile_name
	$Background/Grid/Port2.text = str(Netplay.port_number)
	request_public_ip()
	host_private_ip = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	show_hidden_private_ip()
	
# warning-ignore:return_value_discarded
	Netplay.connect("update_player_list", self, "_on_update_player_list")
	
	if !Netplay.is_netplay():
		Netplay.start_hosting()
	else:
		Netplay.open_connection()
		_on_update_player_list()

	
func _on_update_player_list():
	if Netplay.player_list[1].peer_id != null:
		$PlayerList/PlayersList/Player2/Name.text = " " + Netplay.player_list[1].profile_name
		$PlayerList/PlayersList/Player2/Ping.text = "-"
		$PlayerList/PlayersList/Player2.show()
	else:
		$PlayerList/PlayersList/Player2/Name.text = ""
		$PlayerList/PlayersList/Player2/Ping.text = ""
		$PlayerList/PlayersList/Player2.hide()
	
	
# IP ADDRESS ----------------------------------------------------------------------------------------------------------------------------------------



func show_hidden_private_ip():
#	hide_ip = true
	var hidden_private_ip = ""
	for x in host_private_ip.length():
		hidden_private_ip += "*"
	$Background/Grid/PrivateIP2.text = hidden_private_ip


func request_public_ip():
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", self, "receive_public_ip")
	var error = http.request("https://api.ipify.org")
	if error != OK:
		$Background/Grid/IP2.text = "query failed"
	
func receive_public_ip(_result, _response_code, _headers, body):
	host_public_ip = body.get_string_from_utf8()
	show_hidden_public_ip()
	
func show_hidden_public_ip():
#	hide_ip = true
	var hidden_public_ip = ""
	for x in host_public_ip.length():
		hidden_public_ip += "*"
	$Background/Grid/PublicIP2.text = hidden_public_ip
	
#func show_revealed_ip():
#	hide_ip = false
#	$Background/Grid/IP2.text = host_ip
	
# ----------------------------------------------------------------------------------------------------------------------------------------


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if $HostList2.get_focus_owner().get_parent().name == "HostList2":
			$HostList/Change.initial_focus()
			play_audio("ui_back", {})
		elif host_readied:
			rpc("host_ready", false)
	
	# update ping
	if Netplay.is_netplay() and Netplay.ping != null:
		var ping = Netplay.ping * 1000
		$PlayerList/PlayersList/Player2/Ping.text = str(round(ping)) + "ms (" + str(ceil(Netplay.ping * 30)) + "f)"
		if ping <= 100:
			$HostList2/HSplitContainer/Recommended.text = "Recommended: 1 frame"
		elif ping <= 150:
			$HostList2/HSplitContainer/Recommended.text = "Recommended: 2 frames"
		elif ping <= 200:
			$HostList2/HSplitContainer/Recommended.text = "Recommended: 3 frames"
		elif ping <= 250:
			$HostList2/HSplitContainer/Recommended.text = "Recommended: 4 frames"
		else:
			$HostList2/HSplitContainer/Recommended.text = "Recommended: Kick them"
			
	# start game
	if host_readied and guest_readied:
		start_game()

func start_game():
	Netplay.close_connection()
	BGM.fade()
	$Transition.play("transit_to_char_select_net")
	
	Netcode.input_delay = $HostList2/DelayFrames.option_pointer
	Netcode.max_rollback = ($HostList2/MaxRollback.option_pointer * 5) + 20
	match $HostList2/HostSide.option_pointer:
		0: # host is P1
			Netplay.player_list[0].player_id = 0
			Netplay.player_list[1].player_id = 1
		1: # host is P2
			Netplay.player_list[0].player_id = 1
			Netplay.player_list[1].player_id = 0
	Globals.starting_stock_pts = STOCKPOINTS_OPTIONS[$HostList2/StockPoints.option_pointer]
	Globals.time_limit = TIMELIMIT_OPTIONS[$HostList2/TimeLimit.option_pointer]
	if Globals.time_limit is String: Globals.time_limit = 0
	Globals.assists = $HostList2/Assists.option_pointer
	Globals.static_stage = $HostList2/StaticStage.option_pointer
	Globals.survival_level = null
	Globals.player_count = 2
	

func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"Change":
				play_audio("ui_accept", {"vol":-8})
				$HostList2/HostSide.initial_focus()
#			"ShowIP":
#				if host_ip != "":
#					play_audio("ui_accept", {"vol":-8})
#					if hide_ip:
#						show_revealed_ip()
#						triggered_node.text = "Hide my IP"
#					else:
#						show_hidden_ip()
#						triggered_node.text = "Show my IP"
			"CopyPrivateIP":
				if host_private_ip != "":
					play_audio("ui_accept", {"vol":-8})
					OS.set_clipboard(host_private_ip)
					$IPCopied/AnimationPlayer.stop()
					$IPCopied/AnimationPlayer.play("show")
			"CopyPublicIP":
				if host_public_ip != "":
					play_audio("ui_accept", {"vol":-8})
					OS.set_clipboard(host_public_ip)
					$IPCopied2/AnimationPlayer.stop()
					$IPCopied2/AnimationPlayer.play("show")
			"Kick":
				if get_tree().get_network_connected_peers().size() > 0:
					play_audio("ui_accept2", {"vol":-5})
					get_tree().get_network_peer().disconnect_peer(get_tree().get_network_connected_peers()[0])
				else:
					play_audio("ui_deny", {"vol" : -9})
			"Reset":
				var game_config = {
					"stock_points" : 4,
					"time_limit" : 10,
					"assists" : 0,
					"static_stage" : 0,
					"custom_playlist" : 0,
				}
				play_audio("ui_accept", {"vol":-8})
				$HostList2/StockPoints.change_pointer(game_config.stock_points)
				$HostList2/TimeLimit.change_pointer(game_config.time_limit)
				$HostList2/Assists.change_pointer(game_config.assists)
				$HostList2/CustomPlaylist.change_pointer(game_config.custom_playlist)
				setup_settings_for_guest()
			"Ready":
				if Netplay.is_netplay():
					if !host_readied:
						rpc("host_ready", true)
					else:
						rpc("host_ready", false)
				else:
					play_audio("ui_deny", {"vol" : -9})
			"Return":
				play_audio("ui_back", {})
				Netplay.stop_hosting_or_searching()
				$Transition.play("transit_to_netplay")
			
func save_config():
	var new_net_game_config = {
			"host_side" : $HostList2/HostSide.option_pointer,
			"input_delay" : $HostList2/DelayFrames.option_pointer,
			"max_rollback" : $HostList2/MaxRollback.option_pointer,
			"stock_points" : $HostList2/StockPoints.option_pointer,
			"time_limit" : $HostList2/TimeLimit.option_pointer,
			"assists" : $HostList2/Assists.option_pointer,
			"static_stage" : $HostList2/StaticStage.option_pointer,
		}
	Netplay.save_net_game_config_host(new_net_game_config)
			
			
# ----------------------------------------------------------------------------------------------------------------------------------------

master func host_ready_acknowledged(ready_state: bool):
	if ready_state:
		if !host_readied:
			save_config()
			play_audio("ui_accept2", {"vol":-5})
			$PlayerList/PlayersList/Player1/Ready/AnimationPlayer.play("flashing")
			host_readied = true
	else:
		if host_readied:
			play_audio("ui_back", {})
			$PlayerList/PlayersList/Player1/Ready/AnimationPlayer.play("fade")
			host_readied = false

master func guest_ready(ready_state: bool): # rpc-ed by client when they click ready
	guest_readied = ready_state
	if guest_readied:
		$PlayerList/PlayersList/Player2/Ready/AnimationPlayer.play("flashing")
	else:
		$PlayerList/PlayersList/Player2/Ready/AnimationPlayer.play("fade")
	rpc("guest_ready_acknowledged", ready_state)
	
master func setup_settings_for_guest():
	var host_net_game_config = {
			"host_side" : $HostList2/HostSide.option_pointer,
			"input_delay" : $HostList2/DelayFrames.option_pointer,
			"max_rollback" : $HostList2/MaxRollback.option_pointer,
			"stock_points" : $HostList2/StockPoints.option_pointer,
			"time_limit" : $HostList2/TimeLimit.option_pointer,
			"assists" : $HostList2/Assists.option_pointer,
			"static_stage" : $HostList2/StaticStage.option_pointer,
		}
	rpc("host_changed_settings", host_net_game_config)
	rpc("host_ready", false)
	

func _setting_shifted(_shifted):
	setup_settings_for_guest()
			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
	Netplay.lobby = null
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)
	
func force_start_game():
	if !$Transition.is_playing():
		start_game()
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)

