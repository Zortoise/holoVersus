extends "res://Scenes/FrameAnimPlayer.gd"


# set up sprite to animate and import animation list from a .tres file	
func init(in_sprite, in_sfx_over, in_sfx_under, frame_data_path):
	
	sprite = in_sprite
	sfx_over = in_sfx_over
	sfx_under = in_sfx_under
	
	# open the frame_data_path and get the filenames of all files in it
	var dir = Directory.new()
	if dir.open(frame_data_path) == OK:
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"): # load all files with name ending in ".tres"
				var import_data = ResourceLoader.load(frame_data_path + file_name)
				for key in import_data.frame_data.keys(): # add the data inside to animations dictionary
					animations[key] = import_data.frame_data[key]
			file_name = dir.get_next()
	else: print("Error: Cannot open FrameData folder in SpritePlayer")
	

# for entities which require frame data already loaded
func init_with_loaded_frame_data(in_sprite, loaded_frame_data):
	sprite = in_sprite
	for key in loaded_frame_data.frame_data.keys():
		animations[key] = loaded_frame_data.frame_data[key]
