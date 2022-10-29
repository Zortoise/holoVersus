extends Node2D


var running := false

var time := 0

onready var pips = [$P1.get_children(), $P2.get_children()]

var P1_node
var P2_node

var player_stopped := [false, false]
var stoptimes := [0, 0]
var startup_stopped := [false, false]
var startup_stoptimes:= [0, 0]

func _ready():
	$Startup.text = ""
	$Startup2.text = ""
	$Advantage.text = ""

func is_idle(player):
	match player.state:
		Globals.char_state.GROUND_STANDBY, Globals.char_state.AIR_STANDBY, Globals.char_state.CROUCHING, \
				Globals.char_state.DEAD, Globals.char_state.GROUND_C_RECOVERY, Globals.char_state.AIR_C_RECOVERY:
			return true
		Globals.char_state.GROUND_BLOCK, Globals.char_state.AIR_BLOCK: # for block, block return is not considered idle
			if !player.Animator.query_current(["BlockstunReturn", "AirBlockstunReturn"]):
				return true
	return false

func stimulate():
	if visible:
		
		if !running: # check whether to start running
			if !is_idle(P1_node) or !is_idle(P2_node):
				start()
		if running: # running, don't use else, check whether to stop running
			if is_idle(P1_node) and is_idle(P2_node):
				stop()
			else:
				var pip_number = posmod(time, 50)
				
				if pip_number == 0 and time != 0:
					darken_pips() # next line
					
				var players = [P1_node, P2_node]
				
				for player_number in players.size():
					
					if players[player_number].get_node("HitStopTimer").is_running():
						pips[player_number][pip_number].modulate = Color(1.0, 0.0, 0.0)
					else:
						match players[player_number].state:
							Globals.char_state.GROUND_STARTUP, Globals.char_state.AIR_STARTUP:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.3, 1.0, 1.0)
							Globals.char_state.GROUND_ACTIVE, Globals.char_state.AIR_ACTIVE:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.3, 0.3, 0.7)
							Globals.char_state.GROUND_RECOVERY, Globals.char_state.AIR_RECOVERY:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.4, 0.4, 1.0)
							Globals.char_state.GROUND_C_RECOVERY, Globals.char_state.AIR_C_RECOVERY:
								if !player_stopped[player_number]: stoptimes[player_number] = time
								player_stopped[player_number] = true
								pips[player_number][pip_number].modulate = Color(0.7, 0.3, 1.0)
								
							Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.AIR_ATK_STARTUP:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.3, 1.0, 1.0)
							Globals.char_state.GROUND_ATK_ACTIVE, Globals.char_state.AIR_ATK_ACTIVE:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(1.0, 0.5, 0.5)				
							Globals.char_state.GROUND_ATK_RECOVERY, Globals.char_state.AIR_ATK_RECOVERY:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.4, 0.4, 1.0)				
								
							Globals.char_state.GROUND_FLINCH_HITSTUN, Globals.char_state.AIR_FLINCH_HITSTUN:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(1.0, 1.0, 0.3)	
							Globals.char_state.LAUNCHED_HITSTUN:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(1.0, 1.0, 0.3)	
							Globals.char_state.GROUND_BLOCKSTUN, Globals.char_state.AIR_BLOCKSTUN:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(1.0, 0.8, 0.3)	
							Globals.char_state.GROUND_BLOCK, Globals.char_state.AIR_BLOCK: # for BlockReturn
								if players[player_number].Animator.query_current(["BlockstunReturn", "AirBlockstunReturn"]):
									player_stopped[player_number] = false
									pips[player_number][pip_number].modulate = Color(1.0, 0.8, 0.3)	
								else: continue
							_:
								if !player_stopped[player_number]:
									stoptimes[player_number] = time
								player_stopped[player_number] = true
								pass
								
				for player_number in players.size():
					if !players[player_number].state in [Globals.char_state.GROUND_STARTUP, Globals.char_state.AIR_STARTUP,
							Globals.char_state.GROUND_ATK_STARTUP, Globals.char_state.AIR_ATK_STARTUP]:
						if !startup_stopped[player_number]: startup_stoptimes[player_number] = time
						startup_stopped[player_number] = true
				
				time += 1


func start():
	clear_pips()
	running = true
	time = 0
	stoptimes = [0, 0]
	player_stopped = [false, false]
	startup_stoptimes = [0, 0]
	startup_stopped = [false, false]
	$Startup.text = ""
	$Startup2.text = ""
	$Advantage.text = ""
	
		
func stop():
	running = false
	
	if !player_stopped[0]: stoptimes[0] = time
	if !player_stopped[1]: stoptimes[1] = time
	if !startup_stopped[0]: startup_stoptimes[0] = time
	if !startup_stopped[1]: startup_stoptimes[1] = time
	
	time = 0
	var time_diff = stoptimes[1] - stoptimes[0]
	if time_diff >= 0:
		$Advantage.text = "+ " + str(time_diff)
	else:
		$Advantage.text = "- " + str(abs(time_diff))
	if startup_stoptimes[0] > 0:
		$Startup.text = "S: " + str(startup_stoptimes[0])
	if startup_stoptimes[1] > 0:
		$Startup2.text = "S: " + str(startup_stoptimes[1])
		
	
func darken_pips():
	for x in $P1.get_children():
		if x.modulate != Color(0.2, 0.2, 0.2):
			x.modulate = x.modulate * 0.6
	for x in $P2.get_children():
		if x.modulate != Color(0.2, 0.2, 0.2):
			x.modulate = x.modulate * 0.6
	
func clear_pips():
	for x in $P1.get_children():
		x.modulate = Color(0.2, 0.2, 0.2)
	for x in $P2.get_children():
		x.modulate = Color(0.2, 0.2, 0.2)