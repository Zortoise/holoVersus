extends AudioStreamPlayer


# WIP, handle looping and music transitions (fade out)

var music_to_play
var decaying := false


func bgm(new_bgm):
	music_to_play = new_bgm
	decaying = true
	
func _physics_process(_delta):
	pass
	# start fading out current music, once music is faded out start playing music_to_play
