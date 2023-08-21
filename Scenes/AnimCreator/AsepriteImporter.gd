tool
extends EditorScript

# This tool take .aseprite files and generate frame data, spritesheets, hitboxes, hurtboxes, etc from it

# HOW TO USE:
#	Key in directory for entity_folder (must contain a folder called "AsepriteFiles" with at least 1 .aseprite file inside)
# 	Key in filename for the .aseprite file (leave empty to process all .aseprite files in AsepriteFiles folder of entity_folder
# 	Key in path to Aseprite.exe
#	Do File > Run or use the shortcut Control+Shift+X

# TARGETS ---------------------------------------------------------------------------------------------------

export var entity_folder = "res://Characters/Ina"
# be sure to end with a "/", or not if you wish, I guess

export var target_aseprite_filename = "SP5"
# only need filename, not path, no need extension
# if left empty, will process all .aseprite files in the AsepriteFiles folder in entity_folder

export var aseprite_exe = "C:\\Program Files\\Aseprite-v1.2.39\\Aseprite.exe"
# path to Aseprite.exe
# remember to change this after updating Aseprite!

# ---------------------------------------------------------------------------------------------------

const COLUMN_COUNT := 6 # for exported spritesheet

func _run():
	
	if !entity_folder.ends_with("/"):
		entity_folder += "/" # stop accidentally leaving it out
		
	# if target_aseprite_filename is not empty, only process that aseprite file and ignore the rest
	if target_aseprite_filename != "":
		process_aseprite_file(target_aseprite_filename)
	else: # if target_aseprite_filename is empty, process all aseprite_files in AsepriteFiles folder in entity_folder
		var dir = Directory.new()
		if dir.open(entity_folder + "AsepriteFiles/") == OK:
			dir.list_dir_begin(true)
			var file_name = dir.get_next()
			while file_name != "":
				if file_name.ends_with(".aseprite"):
					process_aseprite_file(file_name.get_file().trim_suffix(".aseprite"))
				file_name = dir.get_next()
		else: print("Error: Cannot open AsepriteFiles folder")
		
	print("Import complete!")


# ---------------------------------------------------------------------------------------------------

# when processing all .aseprite files in the folder, do this once for each aseprite_file found
func process_aseprite_file(in_aseprite_filename: String): # output a single .tres FrameData file for each .aseprite file
	
	var frame_data = {}

	# get the array of layers within the aseprite file
	var layers = get_layers(in_aseprite_filename)
	
	# process "Sprite" layer first
	process_sprite_layer(frame_data, in_aseprite_filename)
	
	# process other layers
	for layer_name in layers:
#		match layer_name: # ignore "Sprite" layer since already processed
		# "match layer_name:" used to work in older versions, now I have to use ".begins_with"...
		if layer_name.begins_with("Hurtbox"):
			process_polygon_layer("Hurtbox", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("SDHurtbox"):
			process_polygon_layer("SDHurtbox", frame_data, in_aseprite_filename)			
		elif layer_name.begins_with("Hitbox"):
			process_polygon_layer("Hitbox", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("Sweetbox"):
			process_polygon_layer("Sweetbox", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("ExPolygonA"): # can be used for various effects like vacuuming or sourspots
			process_polygon_layer("ExPolygonA", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("ExPolygonB"):
			process_polygon_layer("ExPolygonB", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("SfxOver"):
			process_sfx_layer("SfxOver", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("SfxUnder"):
			process_sfx_layer("SfxUnder", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("KBOrigin"):
			process_point_layer("KBOrigin", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("SfxSpawn"):
			process_point_layer("SfxSpawn", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("EntitySpawn"):
			process_point_layer("EntitySpawn", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("GrabPoint"):
			process_point_layer("GrabPoint", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("GrabRotDir"):
			process_point_layer("GrabRotDir", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("VacPoint"):
			process_point_layer("VacPoint", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("ExPointA"): # can be used for extra SfxSpawn and EntitySpawn points
			process_point_layer("ExPointA", frame_data, in_aseprite_filename)
		elif layer_name.begins_with("ExPointB"):
			process_point_layer("ExPointB", frame_data, in_aseprite_filename)
				
	# ---------------------------------------------------------------------------------------------------
	# save frame_data dictionary for this aseprite file to a .tres file
	
	var export_data = load("res://Scenes/AnimCreator/FrameData.gd").new()
	export_data.frame_data = frame_data
	
	var dir = Directory.new()
	if !dir.dir_exists(entity_folder + "FrameData/"):
		dir.make_dir(entity_folder + "FrameData/")
	
	var output_file_name = entity_folder + "FrameData/" + in_aseprite_filename + ".tres"
	ResourceSaver.save(output_file_name, export_data)

	
# --------------------------------------------------------------------------------------------------

func get_layers(in_aseprite_filename: String): # this returns an array of layer names in a certain .aseprite file
	var output = []
	OS.execute(aseprite_exe, ["--all-layers", "-b", "--list-layers", generate_aseprite_file_path(in_aseprite_filename)], true, output, true)
	var layers = output[0].split('\n')
	layers.resize(layers.size() - 1)
	return layers
	
# generate arguments for a certain layer in a certain aseprite file to be used in OS.execute
func generate_arguments(layer_name, in_aseprite_filename):
	var arguments = [
		"--layer",
		layer_name,
		"--all-layers",
		"-b",
		"--list-tags",
		"--data",
		generate_JSON_path(in_aseprite_filename, layer_name),
		"--format",
		"json-array",
		"--sheet",
		generate_spritesheet_path(in_aseprite_filename, layer_name),
		generate_aseprite_file_path(in_aseprite_filename),
		"--merge-duplicates",
		"--sheet-columns",
		COLUMN_COUNT, # number of columns for spritesheet
	]
	return arguments
	
func generate_arguments_for_polygons(polygon_layer_name, in_aseprite_filename):
	var arguments = [
		"--layer",
		polygon_layer_name,
		"--all-layers",
		"-b",
		"--list-tags",
		"--data",
		generate_JSON_path(in_aseprite_filename, polygon_layer_name),
		"--format",
		"json-array",
		"--sheet",
		generate_polygon_ref_path(in_aseprite_filename, polygon_layer_name),
		generate_aseprite_file_path(in_aseprite_filename),
		"--merge-duplicates",
		"--sheet-columns",
		COLUMN_COUNT, # number of columns for spritesheet
	]
	return arguments
	
func get_frame_index(frame): # this take the data of a single frame and get the frame index
	var column = frame.frame.x / frame.frame.w
	var row = frame.frame.y / frame.frame.h
	return (row * COLUMN_COUNT) + column
	
func generate_aseprite_file_path(in_aseprite_filename):
	var aseprite_file_path = entity_folder + "AsepriteFiles/" + in_aseprite_filename + ".aseprite"
	aseprite_file_path = aseprite_file_path.trim_prefix("res://")
	return aseprite_file_path
	
func generate_JSON_path(in_aseprite_filename, layer_name):
	var JSON_path = entity_folder + in_aseprite_filename + layer_name + ".json"
	JSON_path = JSON_path.trim_prefix("res://")
	return JSON_path
	
func generate_spritesheet_path(in_aseprite_filename, layer_name):
	var spritesheet_path = entity_folder + "Spritesheets/" + in_aseprite_filename + layer_name + ".png"
	spritesheet_path = spritesheet_path.trim_prefix("res://")
	return spritesheet_path
	
func generate_polygon_ref_path(in_aseprite_filename, polygon_layer_name):
	var polygon_ref_path = entity_folder + in_aseprite_filename + polygon_layer_name + ".png"
	polygon_ref_path = polygon_ref_path.trim_prefix("res://")
	return polygon_ref_path
	
# --------------------------------------------------------------------------------------------------

func process_sprite_layer(frame_data, in_aseprite_filename):
	var output = []
	# extract JSON and spritesheet from "Sprite" layer
	OS.execute(aseprite_exe, generate_arguments("Sprite", in_aseprite_filename), true, output, true)

	# read JSON file and convert into text
	var file = File.new()
	file.open(generate_JSON_path(in_aseprite_filename, "Sprite"), File.READ)
	var layer_data =  parse_json(file.get_as_text())
	file.close()
	
	
	# get hframes and vframes
	var hframes = layer_data.meta.size.w / layer_data.frames[0].sourceSize.w
	var vframes = layer_data.meta.size.h / layer_data.frames[0].sourceSize.h
	
	var name_for_checking := [] # used to check for duplicated tag name
	
	# get data for each animation tag
	for animation in layer_data.meta.frameTags:
		var anim_name = animation.name
		
		if anim_name in name_for_checking:
			print("Error: Duplicate animation tag name found: " + str(anim_name))
		name_for_checking.append(anim_name)
		
		var loop := false
		if anim_name.begins_with("~"): # if start with "~", remove it from the name and loop = true
			loop = true
			anim_name = anim_name.trim_prefix("~")
		
		# start setting up frame data for the animation tag
		frame_data[anim_name] = {}
		frame_data[anim_name]["spritesheet"] = in_aseprite_filename + "Sprite"
		frame_data[anim_name]["hframes"] = int(hframes)
		frame_data[anim_name]["vframes"] = int(vframes)
		frame_data[anim_name]["loop"] = loop
		frame_data[anim_name]["timestamps"] = {}
			
		var frames_in_anim = layer_data.frames.slice(animation.from, animation.to)
		var anim_time := 0
		for frame in frames_in_anim: # getting frame index and timestamps per frame
			frame_data[anim_name]["timestamps"][anim_time] = {}
			frame_data[anim_name]["timestamps"][anim_time]["frame"] = int(get_frame_index(frame))
			anim_time += round(frame.duration / (100.0/6.0)) # convert from milliseconds to frame
		
		frame_data[anim_name]["duration"] = anim_time
		
	# remove JSON file for this layer afterward
	var dir = Directory.new()
	dir.remove(entity_folder + in_aseprite_filename + "Sprite" + ".json")
	

func process_sfx_layer(sfx_layer_name, frame_data, in_aseprite_filename):
	var output = []
	# extract JSON and spritesheet from sfx layer
	OS.execute(aseprite_exe, generate_arguments(sfx_layer_name, in_aseprite_filename), true, output, true)

	# read JSON file and convert into text
	var file = File.new()
	file.open(generate_JSON_path(in_aseprite_filename, sfx_layer_name), File.READ)
	var layer_data =  parse_json(file.get_as_text())
	file.close()
	
	# get hframes and vframes for sfx layer spritesheet
	var sfx_hframes = layer_data.meta.size.w / layer_data.frames[0].sourceSize.w
	var sfx_vframes = layer_data.meta.size.h / layer_data.frames[0].sourceSize.h
	
	# get data for each animation tag
	for animation in layer_data.meta.frameTags:
		var anim_name = animation.name
		anim_name = anim_name.trim_prefix("~") # will leave anim_name unchanged if it doesn't begin with "~"
		frame_data[anim_name][sfx_layer_name + "_spritesheet"] = in_aseprite_filename + sfx_layer_name
		frame_data[anim_name][sfx_layer_name + "_hframes"] = int(sfx_hframes)
		frame_data[anim_name][sfx_layer_name + "_vframes"] = int(sfx_vframes)
		
		var frames_in_anim = layer_data.frames.slice(animation.from, animation.to)
		var anim_time := 0
		for frame in frames_in_anim: # getting frame index for the sfx_layer and add to that timestamp
			frame_data[anim_name]["timestamps"][anim_time][sfx_layer_name + "_frame"] = int(get_frame_index(frame))
			anim_time += round(frame.duration / (100.0/6.0)) # convert from milliseconds to frame
		
	# remove JSON file for this layer afterward
	var dir = Directory.new()
	dir.remove(entity_folder + in_aseprite_filename + sfx_layer_name + ".json")
	
		
func process_polygon_layer(polygon_layer_name, frame_data, in_aseprite_filename):
	var output = []
	# extract JSON and polygon_ref from sfx layer
	OS.execute(aseprite_exe, generate_arguments_for_polygons(polygon_layer_name, in_aseprite_filename), true, output, true)
	
	# read JSON file and convert into text
	var file = File.new()
	file.open(generate_JSON_path(in_aseprite_filename, polygon_layer_name), File.READ)
	var layer_data =  parse_json(file.get_as_text())
	file.close()
	
	# get hframes and vframes for polygon ref
	var ref_hframes = layer_data.meta.size.w / layer_data.frames[0].sourceSize.w
	var ref_vframes = layer_data.meta.size.h / layer_data.frames[0].sourceSize.h
	
	# prepare the polygon_array, each entry of polygon_array contain the polygon coordinates for a certain frame index in polygon_ref
	var polygon_array = []
#	var bitmask_array = []
	for x in ref_hframes * ref_vframes:
		polygon_array.append([]) # prepare one empty array for each frame index in polygon_ref, only accept one polygon per frame index
#		bitmask_array = []
	
	# create bitmap from polygon_ref
	var image = Image.new()
	image.load(entity_folder + in_aseprite_filename + polygon_layer_name + ".png")
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	# find the size of a single frame in polygon_ref
	var frame_size: Vector2
	frame_size.x = bitmap.get_size().x / ref_hframes
	frame_size.y = bitmap.get_size().y / ref_vframes
	
	# extract an array of polygons from the bitmap, each polygon is an array of Vect2 points
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(0, 0), bitmap.get_size()))	
	
	for polygon in polygons:
		# for each polygon in "polygons", find out which frame index they belong to by looking at the polygon_ref
		var x_number = floor(polygon[0].x / float(frame_size.x))
		var y_number = floor(polygon[0].y / float(frame_size.y))
		var frame_index = y_number * ref_hframes + x_number
		
		# get the centerpoint of the frame for that frame
		var centerpoint: Vector2
		centerpoint.x = x_number * frame_size.x + (frame_size.x / 2.0)
		centerpoint.y = y_number * frame_size.y + (frame_size.y / 2.0)

		# get the coordinates for each point of the polygon from the centerpoint
		var converted_polygon = []
		for point in polygon:
			converted_polygon.append(point - centerpoint)
			
		# load the converted points into polygon_array in the correct frame index
		if polygon_array[frame_index].size() == 0:
			polygon_array[frame_index] = converted_polygon
		else: print("Error: Multiple polygons detected in one frame")
		
		
	# get data for each animation tag
	for animation in layer_data.meta.frameTags:
		var anim_name = animation.name
		anim_name = anim_name.trim_prefix("~") # will leave anim_name unchanged if it doesn't begin with "~"

		var frames_in_anim = layer_data.frames.slice(animation.from, animation.to)
		var anim_time := 0
#		print(anim_name)
		for frame in frames_in_anim: # getting polygon and adding it to that timestamp
			frame_data[anim_name]["timestamps"][anim_time][polygon_layer_name.to_lower()] = polygon_array[get_frame_index(frame)]
			anim_time += round(frame.duration / (100.0/6.0)) # convert from milliseconds to frame
			
	# remove JSON file and polygon_ref for this layer afterward
	var dir = Directory.new()
	dir.remove(entity_folder + in_aseprite_filename + polygon_layer_name + ".json")
	dir.remove(entity_folder + in_aseprite_filename + polygon_layer_name + ".png")


func process_point_layer(point_layer_name, frame_data, in_aseprite_filename):
	var output = []
	# extract JSON and polygon_ref from sfx layer
	OS.execute(aseprite_exe, generate_arguments_for_polygons(point_layer_name, in_aseprite_filename), true, output, true)
	
	# read JSON file and convert into text
	var file = File.new()
	file.open(generate_JSON_path(in_aseprite_filename, point_layer_name), File.READ)
	var layer_data =  parse_json(file.get_as_text())
	file.close()
	
	# get hframes and vframes for polygon ref
	var ref_hframes = layer_data.meta.size.w / layer_data.frames[0].sourceSize.w
	var ref_vframes = layer_data.meta.size.h / layer_data.frames[0].sourceSize.h
	
	# prepare the point_array, each entry of point_array contain a Vect2 coordinates for a certain frame index in polygon_ref
	var point_array = []
	for x in ref_hframes * ref_vframes:
		point_array.append(null) # prepare one empty array for each frame index in polygon_ref, only accept one polygon per frame index
	
	# create bitmap from polygon_ref
	var image = Image.new()
	image.load(entity_folder + in_aseprite_filename + point_layer_name + ".png")
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(image)
	
	# find the size of a single frame in polygon_ref
	var frame_size: Vector2
	frame_size.x = bitmap.get_size().x / ref_hframes
	frame_size.y = bitmap.get_size().y / ref_vframes
	
	# extract an array of polygons from the bitmap, each polygon is an array of Vect2 points
	var polygons = bitmap.opaque_to_polygons(Rect2(Vector2(0, 0), bitmap.get_size()))	
	
	for polygon in polygons:
		# for each polygon in "polygons", find out which frame index they belong to by looking at the polygon_ref
		var x_number = floor(polygon[0].x / float(frame_size.x))
		var y_number = floor(polygon[0].y / float(frame_size.y))
		var frame_index = y_number * ref_hframes + x_number
		
		# get the centerpoint of the frame for that frame
		var centerpoint: Vector2
		centerpoint.x = x_number * frame_size.x + (frame_size.x / 2.0)
		centerpoint.y = y_number * frame_size.y + (frame_size.y / 2.0)

		# get the coordinates for the top left point of the polygon from the centerpoint
		var converted_point = polygon[polygon.size() - 1] - centerpoint
			
		# load the converted point into point_array in the correct frame index
		if point_array[frame_index] == null:
			point_array[frame_index] = converted_point
		else: print("Error: Multiple points detected in one frame")
		
	# get data for each animation tag
	for animation in layer_data.meta.frameTags:
		var anim_name = animation.name
		anim_name = anim_name.trim_prefix("~") # will leave anim_name unchanged if it doesn't begin with "~"

		var frames_in_anim = layer_data.frames.slice(animation.from, animation.to)
		var anim_time := 0
		for frame in frames_in_anim: # getting polygon and adding it to that timestamp
			frame_data[anim_name]["timestamps"][anim_time][point_layer_name.to_lower()] = point_array[get_frame_index(frame)]
			anim_time += round(frame.duration / (100.0/6.0)) # convert from milliseconds to frame
			
	# remove JSON file and polygon_ref for this layer afterward
	var dir = Directory.new()
	dir.remove(entity_folder + in_aseprite_filename + point_layer_name + ".json")
	dir.remove(entity_folder + in_aseprite_filename + point_layer_name + ".png")
