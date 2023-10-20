extends Node2D

var LEVEL_SELECT_OPTIONS = []
var level_select_filenames = []
const PLAYER_COUNT_OPTIONS = ["1", "2"]
const DIFFICULTY_OPTIONS = ["Normal", "Hard", "Challenge", "Must Die"]

func _ready():
	
	BGM.play_common("TitleThemes")
	
	# load LEVEL_SELECT_OPTIONS
	var directory = Directory.new()
	if directory.open("res://Levels/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				var tscn_path = "res://Levels/" + file_name + "/UniqLevel.tscn"
				if directory.file_exists(tscn_path):
					var level_name = load(tscn_path).instance().LEVEL_NAME
					LEVEL_SELECT_OPTIONS.append(level_name)
					level_select_filenames.append(file_name)
			file_name = directory.get_next()
	else: print("Error: Cannot open Levels folder")

	for node in $SurvivalList.get_children():
		if node.is_in_group("has_focus"):
			node.connect("focused", self, "focused")
		if node.is_in_group("has_trigger"):
			node.connect("triggered", self, "triggered")
	$SurvivalList/StartGame.initial_focus()
	
	var survival_config = Settings.load_survival_config() # set up loaded values
	var last_level = clamp(survival_config.level_select, 0, LEVEL_SELECT_OPTIONS.size() - 1)
	$SurvivalList/LevelSelect.load_button("Level Select", LEVEL_SELECT_OPTIONS, last_level)
	$SurvivalList/PlayerCount.load_button("Player Count", PLAYER_COUNT_OPTIONS, survival_config.player_count)
	$SurvivalList/Difficulty.load_button("Difficulty", DIFFICULTY_OPTIONS, survival_config.difficulty)
	
	update_diff_explain()
# warning-ignore:return_value_discarded
	$SurvivalList/Difficulty.connect("shifted", self, "shifted")


func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		play_audio("ui_back", {})
		$Transition.play("transit_to_main")


func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)

func shifted(_shifted_node):
	update_diff_explain()
	
func update_diff_explain():
	match $SurvivalList/Difficulty.option_pointer:
		0:
			$DiffExplain.text = "Regain 1 Stock after each wave if Stock count is below starting amount."
		1:
			$DiffExplain.text = "No Stock handouts after each wave."
		2:
			$DiffExplain.text = "One Stock. No Cards.\nShow me what you got."
		3:
			$DiffExplain.text = "Do not attempt."
	

func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"StartGame":
				var survival_config = {
					"level_select" : $SurvivalList/LevelSelect.option_pointer,
					"player_count" : $SurvivalList/PlayerCount.option_pointer,
					"difficulty" : $SurvivalList/Difficulty.option_pointer,
				}
				Settings.save_survival_config(survival_config)
				play_audio("ui_accept2", {})
				BGM.fade()
				$Transition.play("transit_to_char_select_surv")
				Globals.survival_level = level_select_filenames[survival_config.level_select]
				Globals.player_count = survival_config.player_count + 1
				Globals.difficulty = survival_config.difficulty
				Globals.time_limit = 0
				Globals.assists = -1
			"Return":
				play_audio("ui_back", {})
				$Transition.play("transit_to_main")

			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
	Globals.next_scene = new_scene
# warning-ignore:return_value_discarded
	get_tree().change_scene("res://Scenes/LoadingScreen.tscn")
	
func play_audio(audio_ref, aux_data):
	var new_audio = Loader.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)


