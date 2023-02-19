extends "res://Scenes/Animators/FrameAnimPlayer.gd"


# list of available animations, built-in instead of reading a resource file like the real FrameAnimPlayer
func _ready():
	animations = LoadedSFX.modulate_animations # no need duplicate(), not changing anything inside

