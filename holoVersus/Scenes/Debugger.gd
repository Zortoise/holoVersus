extends Resource


export var logs = {"rollback_check" : []}

#export var save_stateA = {}
#export var save_stateB = {}

#var player_input_state = [ # in int form
#	{ # player 1
#		"pressed" : [],
#		"just_pressed" : [],
#		"just_released" : [],
#	},
#	{ # player 2
#		"pressed" : [],
#		"just_pressed" : [],
#		"just_released" : [],
#	},
#	]
#var captured_input_state = [ # use for capturing inputs, during input delay cannot rely on player_input_state
#	{ # player 1
#		"pressed" : [],
#	},
#	{ # player 2
#		"pressed" : [],
#	},
#	]

export var physics_logs = {}
#export var damage_logs = {}
#export var gg_logs = {}
#export var mm_logs = {}

#export var matchtime_logs = {}
export var platform_logs = {}
export var rng_logs = {}

func set_physics_logs(timestamp: int, players):
	physics_logs[timestamp] = {}
#	matchtime_logs[timestamp] = Globals.Game.matchtime
#	damage_logs[timestamp] = {}
#	gg_logs[timestamp] = {}
#	mm_logs[timestamp] = {}
	for player in players:
		physics_logs[timestamp][player.player_ID] = {}
		physics_logs[timestamp][player.player_ID]["position"] = player.position
		physics_logs[timestamp][player.player_ID]["velocity"] = player.velocity
#		damage_logs[timestamp][player.player_ID] = {}
#		damage_logs[timestamp][player.player_ID][Em.move.DMG] = player.current_damage_value
#		gg_logs[timestamp][player.player_ID] = {}
#		gg_logs[timestamp][player.player_ID]["gg"] = player.current_res_gauge
#		mm_logs[timestamp][player.player_ID] = {}
#		mm_logs[timestamp][player.player_ID]["mm"] = player.repeat_memory.duplicate(true)
		
func rng_logs(timestamp: int, data):
	rng_logs[timestamp] = data
		
func set_platform_logs(timestamp: int, data):
	platform_logs[timestamp] = data.duplicate(true)


func set_input_log(timestamp: int, data):
	if !timestamp in logs:
		logs[timestamp] = {}
	logs[timestamp]["input_log"] = data.duplicate(true)

func set_captured_input_state(timestamp: int, data):
	if data.pressed.size() + data.old_pressed.size() == 0:
		return
	if !timestamp in logs:
		logs[timestamp] = {}
	logs[timestamp]["captured_input_state"] = data.duplicate(true)
	
func set_state(timestamp, input_log, player_input_state):
#	if player_input_state.pressed.size() + player_input_state.old_pressed.size() == 0:
#		return
	if !timestamp in logs:
		logs[timestamp] = {}
	else:
		var marker = 0
		var new_timestamp = timestamp
		while new_timestamp in logs:
			marker += 1
			new_timestamp = str(timestamp) + "r" + str(marker)
		logs[new_timestamp] = logs[timestamp].duplicate(true)
	if input_log != null:
		logs[timestamp]["input_log"] = input_log.duplicate(true)
	if player_input_state.pressed.size() > 0:
		logs[timestamp]["input_state"] = player_input_state.pressed.duplicate(true)
	
func rollback_check(timestamp):
	logs.rollback_check.append(timestamp)
	
func set_player_input_state(timestamp: int, data):
	if data.pressed.size() + data.just_pressed.size() + data.just_released.size() == 0:
		return
	if !timestamp in logs:
		logs[timestamp] = {}
	logs[timestamp]["player_input_state"] = data.duplicate(true)
	
func set_latest_correct_time(timestamp: int, data):
	if !timestamp in logs:
		logs[timestamp] = {}
	logs[timestamp]["latest_correct_time"] = data
	
#func set_latest_payload(timestamp: int, data):
#	pass

