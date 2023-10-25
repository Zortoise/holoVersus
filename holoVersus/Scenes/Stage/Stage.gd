extends Node

#var music := []

func init(): # called by unique stage code when init() is called
	Globals.Game.stage_box = $StageBox
#	Globals.Game.blastbarrierL = $StageBox/BlastBarrierL
#	Globals.Game.blastbarrierR = $StageBox/BlastBarrierR
#	Globals.Game.blastbarrierU = $StageBox/BlastBarrierU
#	$StageBox/BlastBarrierL.add_to_group("BlastBarriers")
#	$StageBox/BlastBarrierR.add_to_group("BlastBarriers")
#	$StageBox/BlastBarrierU.add_to_group("BlastBarriers")
	$StageBox/BlastBarrierL.add_to_group("BlastWalls")
	$StageBox/BlastBarrierR.add_to_group("BlastWalls")
	$StageBox/BlastBarrierU.add_to_group("BlastCeiling")
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
			
#	load_music()
	

#func load_music():
#	var dir = Directory.new()
#	var dir_name = "res://Stages/" + Globals.stage_ref + "/Music/"
#	if dir.dir_exists(dir_name): # if Music folder exist
#		if dir.open(dir_name) == OK:
#			dir.list_dir_begin(true)
#			var file_name = dir.get_next()
#			while file_name != "":
#				if file_name.ends_with(".ogg"):
#					var dictionary = {
#						"name" : file_name,
#						"vol" : 0,
#					}
#					dictionary["audio"] = dir_name + file_name
#
#					var tres_name = dir_name + file_name.trim_suffix(".ogg") + ".tres"
#					if ResourceLoader.exists(tres_name):
#						var track_data = ResourceLoader.load(tres_name).data
#						for key in track_data.keys():
#							dictionary[key] = track_data[key]
#
#					music.append(dictionary)
#
#				file_name = dir.get_next()
#		else: print("Error: Cannot open Stage's Music folder")

func simulate():
	if !Globals.Game.is_stage_paused():
		for moving_platform in get_tree().get_nodes_in_group("MovingPlatforms"):
			moving_platform.simulate()
		
	
		
	
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
