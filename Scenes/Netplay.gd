extends Node

signal update_player_list()
signal packet_loss()

onready var loaded_popup = load("res://Scenes/Popup.tscn")

var lobby = null # set to lobby node while in lobby

var profile_name := "Player"
var port_number := 44500

var	player_list = [
		{
			"peer_id" : null,
			"player_id" : null,
			"profile_name" : "",
			"wins" : 0,
		},
		{
			"peer_id" : null,
			"player_id" : null,
			"profile_name" : "",
			"wins" : 0,
		}
	]
	

var ping = null # median of ping_array, in seconds
var ping_array := []
const PING_ARRAY_SIZE = 11 # how many measured ping to keep
const PING_INTERVAL = 1.0 # how often to measure ping, in seconds

var ping_interval_timer := 0.0
var ping_timer = null
const PING_LIMIT = 1.0




func _ready():
#	close_connection() # start with connection closed
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_player_connected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
#	get_tree().connect("connected_to_server", self, "_connected_ok") # connect in menu node
##	get_tree().connect("connection_failed", self, "_connected_fail") # connect in menu node
#	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	
func close_connection():
	if get_tree().has_network_peer():
		get_tree().set_refuse_new_network_connections(true)
func open_connection():
	if get_tree().has_network_peer():
		get_tree().set_refuse_new_network_connections(false)
	
func is_netplay():
	if get_tree().has_network_peer() and get_tree().get_network_connected_peers().size() > 0:
		return true
	else:
		return false

func my_player_id():
	if get_tree().is_network_server():
		return player_list[0].player_id
	else:
		return player_list[1].player_id

func start_hosting():
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port_number, 2)
	get_tree().network_peer = peer
	open_connection()
	
	player_list[0].peer_id = 1
	player_list[0].profile_name = profile_name
#	emit_signal("update_player_list") # update player list in menu
	
	
func start_searching(target_ip: String = "127.0.0.1"):
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(target_ip, port_number)
	get_tree().network_peer = peer
	
func stop_hosting_or_searching():
	close_connection()
	get_tree().network_peer = null
	player_list[0].peer_id = null # reset player list
	player_list[0].profile_name = ""
	player_list[0].player_id = null
	player_list[0].wins = 0
	player_list[1].peer_id = null
	player_list[1].profile_name = ""
	player_list[1].player_id = null
	player_list[1].wins = 0
	
	
# SAVE/LOAD LAST PICKED SETTINGS -----------------------------------------------------------------
	
# last picked options, so you don't have to keep resetting them
func save_net_game_config_host(net_game_config_host: Dictionary):
	var net_game_config_data_host = load("res://Scenes/Menus/NetGameConfigHost.gd").new() # save config data
	net_game_config_data_host.net_game_config_host = net_game_config_host.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://net_game_config_host.tres", net_game_config_data_host)
	
func load_net_game_config_host():
	var net_game_config_host: Dictionary
	if ResourceLoader.exists("user://net_game_config_host.tres"):
		net_game_config_host = ResourceLoader.load("user://net_game_config_host.tres").net_game_config_host
		
		var valid := true # check if game_config has all needed keys, if not, use default game_config
		for check in ["host_side", "input_delay", "max_rollback", "stock_points", "time_limit", "assists", "static_stage"]:
			if !check in net_game_config_host:
				valid = false
		if valid:
			return net_game_config_host
		
	# default net_game_config
	return {
			"host_side" : 0,
			"input_delay" : 1,
			"max_rollback" : 0,
			"stock_points" : 7,
			"time_limit" : 6,
			"assists" : 0,
			"static_stage": 0,
		}		
		
# last picked options, so you don't have to keep resetting them
func save_net_game_config_guest(net_game_config_guest: Dictionary):
	var net_game_config_data_guest = load("res://Scenes/Menus/NetGameConfigGuest.gd").new() # save config data
	net_game_config_data_guest.net_game_config_guest = net_game_config_guest.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://net_game_config_guest.tres", net_game_config_data_guest)
	
func load_net_game_config_guest():
	var net_game_config_guest: Dictionary
	if ResourceLoader.exists("user://net_game_config_guest.tres"):
		net_game_config_guest = ResourceLoader.load("user://net_game_config_guest.tres").net_game_config_guest
		
		var valid := true # check if game_config has all needed keys, if not, use default game_config
		for check in ["host_ip"]:
			if !check in net_game_config_guest:
				valid = false
		if valid:
			return net_game_config_guest
		
	# default net_game_config
	return {
#			"host_ip" : "127.0.0.1",
			"host_ip" : "",
		}		
		
		
# last picked options, so you don't have to keep resetting them
func save_net_game_config_common(net_game_config_common: Dictionary):
	var net_game_config_data_common = load("res://Scenes/Menus/NetGameConfigCommon.gd").new() # save config data
	net_game_config_data_common.net_game_config_common = net_game_config_common.duplicate()
# warning-ignore:return_value_discarded
	ResourceSaver.save("user://net_game_config_common.tres", net_game_config_data_common)
	
func load_net_game_config_common():
	var net_game_config_common: Dictionary
	if ResourceLoader.exists("user://net_game_config_common.tres"):
		net_game_config_common = ResourceLoader.load("user://net_game_config_common.tres").net_game_config_common
		
		var valid := true # check if game_config has all needed keys, if not, use default game_config
		for check in ["name", "port"]:
			if !check in net_game_config_common:
				valid = false
		if valid:
			return net_game_config_common
		
	# default net_game_config
	return {
			"name" : "",
			"port" : 44500,
		}		
	
# --------------------------------------------------------------------------------------------------------
	
func get_player_id_from_peer_id(peer_id):
	for player in player_list:
		if player.peer_id == peer_id:
			return player.player_id
	print("Error: Fail to find peer_id in player_list.")
	
func get_peer_id_from_player_id(player_id):
	for player in player_list:
		if player.player_id == player_id:
			return player.peer_id
	print("Error: Fail to find player_id in player_list.")
	
func get_profile_name_from_player_id(player_id):
	for player in player_list:
		if player.player_id == player_id:
			return player.profile_name
	print("Error: Fail to find player_id in player_list.")
	

# SIGNALS ----------------------------------------------------------------------------------------

# host and client
func _player_connected(id):
	ping = null # reset ping median just in case
	ping_array = []
	ping_interval_timer = PING_INTERVAL
	
	if get_tree().is_network_server(): # start filling in the list
		player_list[1].peer_id = id
		rpc("sent_host_your_profile") # request profile name from client
	
puppet func sent_host_your_profile():
	rpc_id(1, "receive_client_profile", profile_name)
master func receive_client_profile(client_profile: String):
	player_list[1].profile_name = client_profile
	emit_signal("update_player_list") # update player list in menu
	rpc("set_player_list", player_list) # send completed player list to client
puppet func set_player_list(in_player_list):
	player_list = in_player_list.duplicate(true)
	emit_signal("update_player_list") # update player list in menu
	
# host and client
func _player_disconnected(id):
	ping = null
	ping_array = []
	
	if id != 1: # guest disconnected
		player_list[1].peer_id = null
		player_list[1].profile_name = ""
		player_list[1].player_id = null
	elif id == 1: # host disconnected
		player_list[0].peer_id = null
		player_list[0].profile_name = ""
		player_list[0].player_id = null
		
	emit_signal("update_player_list") # update player list in menu

	
# client only
#func _server_disconnected(): # host disconnected
#	pass
	
# show popup during disconnection
func connection_issue(issue, sending_node: Node, following_method: String):
	var pop = loaded_popup.instance()
	get_tree().get_root().add_child(pop)
	pop.connect("popup_vanished", sending_node, following_method)
	pop.init(issue)

	
# MEASURING PING ----------------------------------------------------------------------------------------
	
func _process(delta):
	if is_netplay() and get_tree().is_network_server():
		if ping_timer != null: # for measuring ping
			ping_timer += delta
			if ping_timer > PING_LIMIT: # ping takes too long to echo back, stop counting time
				ping_timer = null
				emit_signal("packet_loss")
		
		ping_interval_timer += delta # for calculating ping in set intervals
		if ping_interval_timer >= PING_INTERVAL:
			ping_interval_timer = 0.0
			ping_peer()

	
func ping_peer(): # start measuring ping, send a ping request to peer, only done by host
	ping_timer = 0.0
	rpc_unreliable("receive_ping_request")
	
puppet func receive_ping_request(): # client only, on receiving ping request, bounce it back
	rpc_unreliable("receive_echoed_ping_request")
	
master func receive_echoed_ping_request(): # host only, received bounced ping request, use it to measure ping time
	ping_array.append(ping_timer)
	ping_timer = null
	if ping_array.size() > PING_ARRAY_SIZE: # record a maximum of PING_ARRAY_SIZE ping times
		ping_array.remove(0) # remove oldest ping time in ping_array
		
	# calculate median and send it to client
	var ping_array2 = ping_array.duplicate()
	ping_array2.sort()
	ping = ping_array2[floor(ping_array2.size() / 2.0)]
	rpc("set_ping", ping)
	
puppet func set_ping(in_ping):
	ping = in_ping
	
	
# ----------------------------------------------------------------------------------------

func force_opponent_to_start_game():
	rpc("force_start_game")
	
remote func force_start_game():
	if lobby != null:
		lobby.force_start_game()
		
