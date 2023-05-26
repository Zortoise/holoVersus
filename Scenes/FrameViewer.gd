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

var damage_value_at_start := [0, 0]


func _ready():
	$FrameViewerList/Startup.text = ""
	$FrameViewerList/Startup2.text = ""
	$FrameViewerList/Advantage.text = ""
	$FrameViewerList/Damage.text = ""

func is_idle(player):
	match player.state:
		Em.char_state.GROUND_STANDBY, Em.char_state.AIR_STANDBY, Em.char_state.CROUCHING, \
				Em.char_state.DEAD, Em.char_state.GROUND_C_REC, Em.char_state.AIR_C_REC:
			return true
		Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK: # for block, block return is not considered idle
			return true
		Em.char_state.LAUNCHED_HITSTUN:
			if !player.get_node("HitStunTimer").is_running():
				return true
	return false

func simulate():
	if visible:
		
		if !running: # check whether to start running
			if !is_idle(P1_node) or !is_idle(P2_node):
				start()
		if running: # running, don't use else, check whether to stop running
			if is_idle(P1_node) and is_idle(P2_node):
				stop()
			else:
				var pip_number = posmod(time, 75)
				
				if pip_number == 0 and time != 0:
					darken_pips() # next line
					
				var players = [P1_node, P2_node]
				
				for player_number in players.size():
					
					if players[player_number].get_node("HitStopTimer").is_running():
						pips[player_number][pip_number].modulate = Color(1.0, 0.0, 0.0)
					else:
						match players[player_number].state:
							Em.char_state.SEQUENCE_TARGET, Em.char_state.SEQUENCE_USER:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(1.0, 0.0, 0.0)
							Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.3, 1.0, 1.0)
							Em.char_state.GROUND_ACTIVE, Em.char_state.AIR_ACTIVE:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.3, 0.3, 0.7)
							Em.char_state.GROUND_REC, Em.char_state.AIR_REC:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.4, 0.4, 1.0)
							Em.char_state.GROUND_C_REC, Em.char_state.AIR_C_REC, \
									Em.char_state.GROUND_D_REC, Em.char_state.AIR_D_REC:
								if !player_stopped[player_number]: stoptimes[player_number] = time
								player_stopped[player_number] = true
								pips[player_number][pip_number].modulate = Color(0.7, 0.3, 1.0)
								
							Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP:
								player_stopped[player_number] = false
								if Em.atk_attr.SUPERARMOR_STARTUP in players[player_number].query_atk_attr_current():
									pips[player_number][pip_number].modulate = Color(0.2, 0.7, 0.7)
								else:
									pips[player_number][pip_number].modulate = Color(0.3, 1.0, 1.0)
							Em.char_state.GROUND_ATK_ACTIVE, Em.char_state.AIR_ATK_ACTIVE:
								player_stopped[player_number] = false
								if Em.atk_attr.SUPERARMOR_ACTIVE in players[player_number].query_atk_attr_current():
									pips[player_number][pip_number].modulate = Color(0.7, 0.3, 0.3)
								else:
									pips[player_number][pip_number].modulate = Color(1.0, 0.5, 0.5)				
							Em.char_state.GROUND_ATK_REC, Em.char_state.AIR_ATK_REC:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(0.4, 0.4, 1.0)				
								
							Em.char_state.GROUND_FLINCH_HITSTUN, Em.char_state.AIR_FLINCH_HITSTUN:
								player_stopped[player_number] = false
								pips[player_number][pip_number].modulate = Color(1.0, 1.0, 0.3)	
							Em.char_state.LAUNCHED_HITSTUN:
								player_stopped[player_number] = false
#								if players[player_number].get_node("HitStunTimer").is_running():
								pips[player_number][pip_number].modulate = Color(1.0, 1.0, 0.3)	
#								else: # techable
#									pips[player_number][pip_number].modulate = Color(0.6, 0.8, 0.3)	
#							Em.char_state.GROUND_BLOCKSTUN, Em.char_state.AIR_BLOCKSTUN:
#								player_stopped[player_number] = false
#								pips[player_number][pip_number].modulate = Color(1.0, 0.8, 0.3)	
#							Em.char_state.GROUND_BLOCK, Em.char_state.AIR_BLOCK: # for BlockReturn
#								if players[player_number].Animator.query_current(["BlockstunReturn", "aBlockstunReturn"]):
#									player_stopped[player_number] = false
#									pips[player_number][pip_number].modulate = Color(1.0, 0.8, 0.3)	
#								else: continue
							_:
								if !player_stopped[player_number]:
									stoptimes[player_number] = time
								player_stopped[player_number] = true
								pass
								
				for player_number in players.size():
					if !players[player_number].state in [Em.char_state.GROUND_STARTUP, Em.char_state.AIR_STARTUP,
							Em.char_state.GROUND_ATK_STARTUP, Em.char_state.AIR_ATK_STARTUP]:
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
	$FrameViewerList/Startup.text = ""
	$FrameViewerList/Startup2.text = ""
	$FrameViewerList/Advantage.text = ""
	$FrameViewerList/Damage.text = ""
	
	damage_value_at_start = [P1_node.current_damage_value, P2_node.current_damage_value]
	
		
func stop():
	running = false
	
	if !player_stopped[0]: stoptimes[0] = time
	if !player_stopped[1]: stoptimes[1] = time
	if !startup_stopped[0]: startup_stoptimes[0] = time
	if !startup_stopped[1]: startup_stoptimes[1] = time
	
	time = 0
	var time_diff = stoptimes[1] - stoptimes[0]
	if time_diff >= 0:
		$FrameViewerList/Advantage.text = "+ " + str(time_diff)
	else:
		$FrameViewerList/Advantage.text = "- " + str(abs(time_diff))
	if startup_stoptimes[0] > 0:
		$FrameViewerList/Startup.text = "S: " + str(startup_stoptimes[0])
	if startup_stoptimes[1] > 0:
		$FrameViewerList/Startup2.text = "S: " + str(startup_stoptimes[1])
		
	var P1_damage = P1_node.current_damage_value - damage_value_at_start[0]
	var P2_damage = P2_node.current_damage_value - damage_value_at_start[1]
	
	if max(P1_damage, P2_damage) > 0:
		$FrameViewerList/Damage.text = "D: " + str(max(P1_damage, P2_damage))
		
	
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
