extends Node


func init(): # called by unique stage code when init() is called
	Globals.Game.stage_box = $StageBox
	Globals.Game.middle_point = $MiddlePosition.position
	for respawn_point in $RespawnPoints.get_children():
		Globals.Game.respawn_points.append(respawn_point.position)
	
	Globals.Game.P1_position = $P1_Position.position
	Globals.Game.P1_facing = 1
	Globals.Game.P2_position = $P2_Position.position
	Globals.Game.P2_facing = -1


func stimulate():
	for moving_platform in get_tree().get_nodes_in_group("MovingPlatforms"):
		moving_platform.move_platform()
		
	
# SAVE/LOAD STATE --------------------------------------------------------------------------------------------------

func save_state():
	var stage_state_data = {}
	for moving_platform in get_tree().get_nodes_in_group("MovingPlatforms"):
		stage_state_data[moving_platform.name] = moving_platform.save_state()
	
	return stage_state_data

func load_state(stage_state_data):
	for moving_platform in get_tree().get_nodes_in_group("MovingPlatforms"):
		moving_platform.load_state(stage_state_data)

#--------------------------------------------------------------------------------------------------
