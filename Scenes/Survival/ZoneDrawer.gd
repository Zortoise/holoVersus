extends Node2D

var to_draw = []
	
#func _ready():
#	hide()

func activate():
	update()
	
func drawer(origin: Vector2, size: Vector2, ref: String):
	
	var draw = {
		"pos" : Vector2(origin.x - int(size.x/2), origin.y - int(size.y/2)),
		"size" : size,
	}
	
	var color
	match ref:
		"point_blank":
			color = Color(1.5, 0.2, 0.2, 0.5)
		"close_range":
			color = Color(0.0, 1.0, 0.0, 0.25)
		"mid_range":
			color = Color(0.2, 0.2, 1.5, 0.5)
		"anti_air":
			color = Color(1.0, 0.0, 1.0, 0.3)
		"anti_air_short":
			color = Color(0.0, 1.0, 1.0, 0.3)
		"anti_air_long":
			color = Color(1.0, 1.0, 1.0, 0.25)
			
		"air_close":
			color = Color(1.5, 0.2, 0.2, 0.5)
		"air_high":
			color = Color(0.0, 1.0, 1.0, 0.3)
		"air_high_long":
			color = Color(1.0, 1.0, 1.0, 0.25)
		"air_low_short":
			color = Color(0.0, 1.0, 0.0, 0.25)
		"air_low_long":
			color = Color(0.2, 0.2, 1.5, 0.5)
		"air_low":
			color = Color(0.0, 0.0, 0.0, 0.25)
		"air_far":
			color = Color(1.0, 0.0, 1.0, 0.3)
	
	draw["color"] = color
	to_draw.append(draw)

	
func _draw():
	
	for draw in to_draw:
		var rect = Rect2(draw.pos, draw.size)
		draw_rect(rect, draw.color)
		
	to_draw = []	
	
	
	
#	for hitbox in player_hitboxes:
#		draw_colored_polygon(hitbox.polygon, Color(1.5, 0.2, 0.2, 0.5))
#		if "sweetbox" in hitbox:
#			draw_colored_polygon(hitbox.sweetbox, Color(0.0, 0.0, 0.0, 0.5))
#	for hitbox in mob_hitboxes:
#		draw_colored_polygon(hitbox.polygon, Color(1.5, 0.2, 0.2, 0.5))
#		if "sweetbox" in hitbox:
#			draw_colored_polygon(hitbox.sweetbox, Color(0.0, 0.0, 0.0, 0.5))
#	for hurtbox in player_hurtboxes:
#		draw_colored_polygon(hurtbox.polygon, Color(0.0, 1.0, 0.0, 0.25))
#		if "sdhurtbox" in hurtbox:
#			draw_colored_polygon(hurtbox.sdhurtbox, Color(0.2, 0.2, 1.5, 0.5))	
#	for hurtbox in mob_hurtboxes:
#		draw_colored_polygon(hurtbox.polygon, Color(0.0, 1.0, 0.0, 0.25))
#		if "sdhurtbox" in hurtbox:
#			draw_colored_polygon(hurtbox.sdhurtbox, Color(0.2, 0.2, 1.5, 0.5))	
#	for box in extra_boxes:
#		draw_rect(box, Color(1.0, 0.0, 1.0, 0.3))

	
#func activate(in_player_hitboxes: Array, in_mob_hitboxes: Array, in_player_hurtboxes: Array, in_mob_hurtboxes: Array):
#	player_hitboxes = in_player_hitboxes # no need to use duplicate(), since I am not changing the data inside, less memory needed
#	mob_hitboxes = in_mob_hitboxes
#	player_hurtboxes = in_player_hurtboxes
#	mob_hurtboxes = in_mob_hurtboxes
#	update()
