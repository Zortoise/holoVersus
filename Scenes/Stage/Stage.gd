extends Node


func init(): # called by unique stage code when init() is called
	Globals.Game.stage_box = $StageBox
#	Globals.Game.blastbarrierL = $StageBox/BlastBarrierL
#	Globals.Game.blastbarrierR = $StageBox/BlastBarrierR
#	Globals.Game.blastbarrierU = $StageBox/BlastBarrierU
	$StageBox/BlastBarrierL.add_to_group("BlastBarriers")
	$StageBox/BlastBarrierR.add_to_group("BlastBarriers")
	$StageBox/BlastBarrierU.add_to_group("BlastBarriers")
	$StageBox/BlastBarrierL.hide()
	$StageBox/BlastBarrierR.hide()
	$StageBox/BlastBarrierU.hide()
	Globals.Game.middle_point = $MiddlePosition.position
	Globals.Game.left_corner = $StageBox.rect_global_position.x + Globals.CORNER_SIZE
	Globals.Game.right_corner = $StageBox.rect_global_position.x + $StageBox.rect_size.x - Globals.CORNER_SIZE

	for respawn_point in $RespawnPoints.get_children():
		Globals.Game.respawn_points.append(respawn_point.position)
	
	Globals.Game.P1_position = $P1_Position.position
	Globals.Game.P1_facing = 1
	Globals.Game.P2_position = $P2_Position.position
	Globals.Game.P2_facing = -1
	
	add_to_group("StageDarken")
	if has_node("ParallaxBackground"):
		for child in $ParallaxBackground.get_children():
			child.add_to_group("StageDarken")
			child.add_to_group("StagePause")


func simulate():
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
