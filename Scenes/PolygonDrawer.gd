extends Node2D

var hitboxes = [] # array of dictionaries, each dictionary has a key "polygon" which contain an array of Vect2 points
var hurtboxes = []

var extra_boxes = [] # set by other nodes, cleared at the start of each frame
	
func _draw():
	for hitbox in hitboxes:
		draw_colored_polygon(hitbox.polygon, Color(1.5, 0.2, 0.2, 0.5))
		if "sweetbox" in hitbox:
			draw_colored_polygon(hitbox.sweetbox, Color(0.0, 0.0, 0.0, 0.5))
	for hurtbox in hurtboxes:
		draw_colored_polygon(hurtbox.polygon, Color(0.0, 1.0, 0.0, 0.25))
		if "sdhurtbox" in hurtbox:
			draw_colored_polygon(hurtbox.sdhurtbox, Color(0.2, 0.2, 1.5, 0.5))	
	for box in extra_boxes:
		draw_rect(box, Color(1.0, 0.0, 1.0, 0.3))
	
func _ready():
	hide()
	
func activate(in_hitboxes: Array, in_hurtboxes: Array):
	hitboxes = in_hitboxes # no need to use duplicate(), since I am not changing the data inside, less memory needed
	hurtboxes = in_hurtboxes
	update()
