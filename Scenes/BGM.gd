extends Node

# WIP, handle looping and music transitions (fade out)
var BGMPlayerScene = load("res://Scenes/BGMPlayer.tscn")

var common_music = {
	"title_theme" : {
		"name" : "title_theme",
		"audio" : ResourceLoader.load("res://Assets/Music/Title Theme.ogg"),
		"loop_end": 208.0
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

	
