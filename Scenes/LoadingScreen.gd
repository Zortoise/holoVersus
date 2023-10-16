extends Node

func _ready():
	match Globals.next_scene:
		"res://Scenes/GameViewport.tscn", "res://Scenes/Menus/CharacterSelect.tscn", \
				"res://Scenes/Menus/CharacterSelectNet.tscn", "res://Scenes/Menus/CharacterSelectSurvival.tscn", \
				"res://Scenes/Menus/CharacterSelectTraining.tscn":
			pass # wait 1 frame first to show the "Loading" text
		_:
			# warning-ignore:return_value_discarded
			get_tree().change_scene(Globals.next_scene)

func _process(_delta):
# warning-ignore:return_value_discarded
	get_tree().change_scene(Globals.next_scene)
