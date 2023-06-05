extends Node

# WIP, handle looping and music transitions (fade out)
var BGMPlayerScene = load("res://Scenes/Audio/BGMPlayer.tscn")

var common_music = {
	"title_theme" : {
		"name" : "title_theme", # to not play the same music as the one currently being played
		"audio" : ResourceLoader.load("res://Assets/Music/TitleTheme.ogg"),
#		"loop_start": 0.0,
		"loop_end": 224.0,
		"vol" : 3,
		},
	"char_select" : {
		"name" : "char_select",
		"audio" : ResourceLoader.load("res://Assets/Music/CharSelect.ogg"),
#		"loop_end": 111.42,
		"loop_end": 125.14,
		"vol" : 0,
		},
	"victory" : {
		"name" : "victory",
		"audio" : ResourceLoader.load("res://Assets/Music/VictoryScreen.ogg"),
		"loop_start": 0.63,
		"loop_end": 94.1,
		"vol" : 1,
		}
}

var current_music := ""

func fade():
	current_music = ""
	var old_bgm = get_tree().get_nodes_in_group("BGMPlayers")
	for x in old_bgm:
		x.decaying = true

func bgm(bgm_dictionary):
	
	if current_music != bgm_dictionary.name:
		fade() # just in case
		current_music = bgm_dictionary.name
		
		yield(get_tree(),"idle_frame")
		var BGMPlayer = BGMPlayerScene.instance()
		get_tree().get_root().add_child(BGMPlayer)
		BGMPlayer.init(bgm_dictionary)

	
