extends Node2D

const TRAITS = []
# example: Em.entity_trait.GROUNDED

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box
	Entity.get_node("Sprite").modulate.a = 0

func init(_aux_data: Dictionary):
	 # starting animation
	Animator.play("Kill")

			
func simulate():
	var my_hitbox = Animator.query_polygon("expolygona")
	var my_rect = Entity.get_sprite_rect()
	
	var character_array = Globals.Game.get_node("Players").get_children()
	
	for character in character_array:
		if "player_ID" in character:
			if character.player_ID == Entity.master_ID:
				continue
		if "master_ID" in character: # assist
			if character.master_ID == Entity.master_ID:
				continue
		if "free" in character and character.free: # freed character
			continue
		if !character.is_atk_active(): # must be in active state
			continue
			
		var their_hitbox = character.get_hitbox() # scan for hit
		if their_hitbox != null:
			var their_rect = character.get_sprite_rect()
			if my_rect.intersects(their_rect):
				var intersect_polygons = Geometry.intersect_polygons_2d(their_hitbox, my_hitbox)
				if intersect_polygons.size() > 0: # detected intersection
					attacked()
					return
					
	var entity_array := []
	if Globals.survival_level != null: # in survival mode, scan mob entities only
		entity_array = get_tree().get_nodes_in_group("MobEntityNodes")
	elif Globals.player_count > 2:
		entity_array = get_tree().get_nodes_in_group("EntityNodes")
	else:
		match Entity.master_ID:
			0:
				entity_array = get_tree().get_nodes_in_group("P2EntityNodes")
			1:
				entity_array = get_tree().get_nodes_in_group("P1EntityNodes")
				
	for entity in entity_array: # scan for hit
		var their_hitbox = entity.get_hitbox()
		if their_hitbox != null:
			var their_rect = entity.get_sprite_rect()
			if my_rect.intersects(their_rect):
				var intersect_polygons = Geometry.intersect_polygons_2d(their_hitbox, my_hitbox)
				if intersect_polygons.size() > 0: # detected intersection
					attacked()
					return
					
func attacked():
	var master_node = Globals.Game.get_player_node(Entity.master_ID)
	if master_node.has_method("perfect_dodge"): master_node.perfect_dodge()
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(_anim_name):
	pass
			
func _on_SpritePlayer_anim_started(_anim_name):
	pass

