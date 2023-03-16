extends Node2D

var player_hitboxes = [] # array of dictionaries, each dictionary has a key "polygon" which contain an array of Vect2 points
var mob_hitboxes = []
var player_hurtboxes = []
var mob_hurtboxes = []

var extra_boxes = [] # set by other nodes, cleared at the start of each frame
	
func _draw():
	for hitbox in player_hitboxes:
		draw_colored_polygon(hitbox[Em.hit.POLYGON], Color(1.5, 0.2, 0.2, 0.5))
		if Em.hit.SWEETBOX in hitbox:
			draw_colored_polygon(hitbox[Em.hit.SWEETBOX], Color(0.0, 0.0, 0.0, 0.5))
	for hitbox in mob_hitboxes:
		draw_colored_polygon(hitbox[Em.hit.POLYGON], Color(1.5, 0.2, 0.2, 0.5))
		if Em.hit.SWEETBOX in hitbox:
			draw_colored_polygon(hitbox[Em.hit.SWEETBOX], Color(0.0, 0.0, 0.0, 0.5))
	for hurtbox in player_hurtboxes:
		draw_colored_polygon(hurtbox[Em.hit.POLYGON], Color(0.0, 1.0, 0.0, 0.25))
		if Em.hit.SDHURTBOX in hurtbox:
			draw_colored_polygon(hurtbox[Em.hit.SDHURTBOX], Color(0.2, 0.2, 1.5, 0.5))	
	for hurtbox in mob_hurtboxes:
		draw_colored_polygon(hurtbox[Em.hit.POLYGON], Color(0.0, 1.0, 0.0, 0.25))
		if Em.hit.SDHURTBOX in hurtbox:
			draw_colored_polygon(hurtbox[Em.hit.SDHURTBOX], Color(0.2, 0.2, 1.5, 0.5))	
	for box in extra_boxes:
		draw_rect(box, Color(1.0, 0.0, 1.0, 0.3))
	
func _ready():
	hide()
	
func activate(in_player_hitboxes: Array, in_mob_hitboxes: Array, in_player_hurtboxes: Array, in_mob_hurtboxes: Array):
	player_hitboxes = in_player_hitboxes # no need to use duplicate(), since I am not changing the data inside, less memory needed
	mob_hitboxes = in_mob_hitboxes
	player_hurtboxes = in_player_hurtboxes
	mob_hurtboxes = in_mob_hurtboxes
	update()
