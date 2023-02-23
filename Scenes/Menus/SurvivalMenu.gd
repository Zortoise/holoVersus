extends Node2D

var LEVEL_SELECT_OPTIONS = []
const PLAYER_COUNT_OPTIONS = [1, 2]

func _ready():
	
	BGM.bgm(BGM.common_music["title_theme"])
	
	# load LEVEL_SELECT_OPTIONS
	var directory = Directory.new()
	if directory.open("res://Levels/") == OK:
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				LEVEL_SELECT_OPTIONS.append(file_name.get_file().trim_suffix(".tscn"))
			file_name = directory.get_next()
	else: print("Error: Cannot open FrameData folder for mob")

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



func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		play_audio("ui_back", {})
		$Transition.play("transit_to_main")


func focused(focused_node):
	$Cursor.position = Vector2(focused_node.rect_global_position.x - 48, focused_node.rect_global_position.y + focused_node.rect_size.y / 2.0)


func triggered(triggered_node):
	if !$Transition.is_playing():
		match triggered_node.name:
			"StartGame":
				var survival_config = {
					"level_select" : $SurvivalList/LevelSelect.option_pointer,
					"player_count" : $SurvivalList/PlayerCount.option_pointer,
				}
				Settings.save_survival_config(survival_config)
				play_audio("ui_accept2", {"vol":-5})
				BGM.fade()
				$Transition.play("transit_to_char_select_surv")
				Globals.survival_level = LEVEL_SELECT_OPTIONS[survival_config.level_select]
				Globals.player_count = PLAYER_COUNT_OPTIONS[survival_config.player_count]
				Globals.time_limit = 0
			"Return":
				play_audio("ui_back", {})
				$Transition.play("transit_to_main")

			
# ----------------------------------------------------------------------------------------------------------------------------------------

func change_scene(new_scene: String): # called by animation
# warning-ignore:return_value_discarded
	get_tree().change_scene(new_scene)
	
func play_audio(audio_ref, aux_data):
	var new_audio = Globals.loaded_ui_audio_scene.instance()
	get_tree().get_root().add_child(new_audio)
	new_audio.init(audio_ref, aux_data)


