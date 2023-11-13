extends Node2D

const ID = "tako" # for master to find it
const TRAITS = []

# cleaner code
onready var Entity = get_parent()
var Animator
var sprite


const MOVE_DATABASE = {
	"Active1" : {
		Em.move.ROOT : "Tako",
		Em.move.ATK_TYPE : Em.atk_type.ENTITY,
		Em.move.HITCOUNT : 1,
		Em.move.DMG : 40,
		Em.move.KB : 300 * FMath.S,
		Em.move.KB_TYPE: Em.knockback_type.VELOCITY,
		Em.move.ATK_LVL : 2,
		Em.move.FIXED_HITSTOP : 8,
		Em.move.KB_ANGLE : 0,
		Em.move.HITSPARK_TYPE : Em.hitspark_type.HIT,
#		Em.move.HITSPARK_PALETTE : "dark_purple",
		Em.move.PROJ_LVL : 1,
		Em.move.ATK_ATTR : [Em.atk_attr.CAN_REPEAT_ONCE],
		Em.move.HIT_SOUND : { ref = "impact39", aux_data = {"vol" : -15} },
	},
}

func _ready():
	get_node("TestSprite").free() # test sprite is for sizing collision box

func init(aux_data: Dictionary):
	
	Entity.unique_data = {"tako_state" : null, "orbit_pos_x" : 0, "orbit_pos_y" : 0, "orbit_vel_x": 0, "orbit_vel_y": 0, "invis" : false, \
			"ex" : false, "enhanced" : false}
	
	if "ex" in aux_data:
		Entity.unique_data.ex = true
	
	if "orbit" in aux_data:
		Entity.unique_data.tako_state = "orbit"
		var master_node = Globals.Game.get_player_node(Entity.master_ID)
		Entity.unique_data.orbit_pos_x = int(master_node.position.x * FMath.S)
		Entity.unique_data.orbit_pos_y = int(master_node.position.y * FMath.S)
		if master_node.dir == 0 and master_node.v_dir == 0:
			Entity.unique_data.orbit_vel_x = 0
			Entity.unique_data.orbit_vel_y = 0
		else:
			var vector = FVector.new()
			vector.set_vector(100 * FMath.S, 0)
			vector.rotate(Globals.dir_to_angle(master_node.dir, master_node.v_dir, master_node.facing))
			Entity.unique_data.orbit_vel_x = vector.x
			Entity.unique_data.orbit_vel_y = vector.y
			if master_node.dir != 0:
				Entity.face(master_node.dir)
	else:
		Entity.unique_data.tako_state = "base"
		
	match Entity.unique_data.tako_state:
		"orbit":
			Animator.play("Active2")
		"base":
			Animator.play("Active2")
			Entity.velocity.set_vector(100 * FMath.S, 0)
			Entity.velocity.rotate(aux_data.angle)
#		"slow":
#			Animator.play("Active2")
#			Entity.velocity.set_vector(50 * FMath.S * Entity.facing, 0)
#			Entity.velocity.rotate(aux_data.angle)
#		"fast":
#			Animator.play("Active3")
#			Entity.velocity.set_vector(50 * FMath.S * Entity.facing, 0)
#			Entity.velocity.rotate(aux_data.angle)
#			Entity.rotate_sprite(aux_data.angle)
#		"stop":

	Entity.absorption_value = 1
	Entity.life_point = 1
	
		
func refine_move_name(move_name):
		
	match move_name:
		"Active2", "Active3":
			return "Active1"
			
	return move_name
	
		
func query_move_data(move_name) -> Dictionary:
	
	move_name = refine_move_name(move_name)
	
	if !move_name in MOVE_DATABASE:
		print("Error: Cannot retrieve move_data for " + move_name + " in " + filename)
		return {}
	
	var move_data = MOVE_DATABASE[move_name].duplicate(true)
	move_data[Em.move.ATK_ATTR] = query_atk_attr(move_name)
	
	if Entity.unique_data.ex:
		move_data[Em.move.ROOT] = "TakoEX"
		move_data[Em.move.ATK_TYPE] = Em.atk_type.EX_ENTITY
		move_data[Em.move.PROJ_LVL] = 2
		move_data[Em.move.DMG] = 50
		
	if Entity.unique_data.enhanced:
		move_data[Em.move.PROJ_LVL] = 3
		move_data[Em.move.DMG] += 10
	
	if Globals.survival_level != null and Em.move.DMG in move_data:
		move_data[Em.move.DMG] = FMath.percent(move_data[Em.move.DMG], Inventory.modifier(Entity.master_ID, Cards.effect_ref.PROJ_DMG_MOD))
	
	return move_data
		
		
func query_atk_attr(move_name):
	
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and Em.move.ATK_ATTR in MOVE_DATABASE[move_name]:
		var atk_atr = MOVE_DATABASE[move_name][Em.move.ATK_ATTR].duplicate(true)
		if Entity.unique_data.enhanced:
			atk_atr.append(Em.atk_attr.REPEATABLE)
#		elif Globals.survival_level != null: # non-EX
#			atk_atr.append(Em.atk_attr.TOUGH_NO_KB)
		return atk_atr
		
#	print("Error: Cannot retrieve atk_attr for " + move_name)
	return []
	
	
func get_proj_level(move_name):
	
	if Entity.unique_data.enhanced:
		return 3
	if Entity.unique_data.ex:
		return 2
	
	move_name = refine_move_name(move_name)

	if move_name in MOVE_DATABASE and Em.move.PROJ_LVL in MOVE_DATABASE[move_name]:
		return MOVE_DATABASE[move_name][Em.move.PROJ_LVL]
	
	return 1
			
			
func simulate():
	if Animator.to_play_anim != "Kill" and Animator.to_play_anim != "Exploding":
		check_command()
		
		if Entity.unique_data.invis and sprite.modulate.a > 0:
			sprite.modulate.a -= 0.1
			
		if Entity.unique_data.tako_state == "orbit":
			
			Entity.unique_data.orbit_pos_x += int(Entity.unique_data.orbit_vel_x / 60) # move orbit point
			Entity.unique_data.orbit_pos_y += int(Entity.unique_data.orbit_vel_y / 60)
			Entity.true_position.x += int(Entity.unique_data.orbit_vel_x / 60)
			Entity.true_position.y += int(Entity.unique_data.orbit_vel_y / 60)
			
			var vec = FVector.new()
			vec.set_vector(Entity.true_position.x - Entity.unique_data.orbit_pos_x, Entity.true_position.y - Entity.unique_data.orbit_pos_y)
			vec.rotate(2 * Entity.facing) # orbit speed
			Entity.true_position.x = Entity.unique_data.orbit_pos_x + vec.x
			Entity.true_position.y = Entity.unique_data.orbit_pos_y + vec.y
			var old_pos = Entity.position
			Entity.position = Entity.get_rounded_position()
			
			if Globals.Game.detect_offstage(Entity.get_node("EntitySpriteBox")):
				on_offstage()
			elif Entity.is_in_wall(): # if collided with surface
				Entity.unique_data.tako_state = "base"
				Animator.play("Active1")
				Entity.position = old_pos
				Entity.set_true_position()
				Entity.velocity.set_vector(0, -100 * FMath.S)

		
func check_command():
	var master_node = Globals.Game.get_player_node(Entity.master_ID)
	if "instant_command" in master_node.unique_data and master_node.unique_data.instant_command != null:
		
		match master_node.unique_data.instant_command:
			"redirect":
				var angle = Globals.dir_to_angle(master_node.dir, master_node.v_dir, master_node.facing)
				Entity.unique_data.tako_state = "base"
				Entity.velocity.set_vector(200 * FMath.S, 0)
				Entity.velocity.rotate(angle)
				Animator.play("Active3")
				Entity.get_node("Sprite").rotation = 0
				Entity.rotate_sprite(angle)
				Globals.Game.spawn_SFX("Music1", "Music", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)
			"slow":
				Entity.unique_data.tako_state = "stop"
				Entity.velocity.x = 0
				Entity.velocity.y = 0
				Animator.play("Active1")
				Entity.get_node("Sprite").rotation = 0
				Globals.Game.spawn_SFX("Music1", "Music", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)
			"chase":
				var vec = FVector.new()
				vec.set_from_vec(master_node.get_target().position - Entity.position)
				Entity.unique_data.tako_state = "base"
				Entity.velocity.set_vector(100 * FMath.S, 0)
				Entity.velocity.rotate(vec.angle())
				Animator.play("Active2")
				Entity.get_node("Sprite").rotation = 0
				if Entity.velocity.x != 0:
					Entity.face(sign(Entity.velocity.x))
				Globals.Game.spawn_SFX("Music1", "Music", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)
			"rally":
				var vec = FVector.new()
				vec.set_from_vec(master_node.position - Entity.position)
				Entity.unique_data.tako_state = "base"
				Entity.velocity.set_vector(100 * FMath.S, 0)
				Entity.velocity.rotate(vec.angle())
				Animator.play("Active2")
				Entity.get_node("Sprite").rotation = 0
				if Entity.velocity.x != 0:
					Entity.face(sign(Entity.velocity.x))
				Globals.Game.spawn_SFX("Music1", "Music", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)
			"invis":
				Entity.unique_data.invis = true
				Globals.Game.spawn_SFX("Music1", "Music", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)
			"expire":
				expire()
			"enhance":
				Entity.unique_data.enhanced = true
				Globals.Game.spawn_SFX("Blink", "Blink", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)
			"scatter":
				var angle = Globals.Game.rng_generate(360)
				Entity.unique_data.tako_state = "base"
				Entity.velocity.set_vector(200 * FMath.S, 0)
				Entity.velocity.rotate(angle)
				Animator.play("Active3")
				Entity.get_node("Sprite").rotation = 0
				Entity.rotate_sprite(angle)
				Globals.Game.spawn_SFX("Music1", "Music", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)
			
func explode():
	Entity.unique_data.tako_state = "exploding"
	Entity.velocity.x = 0
	Entity.velocity.y = 0
	Entity.get_node("Sprite").rotation = 0
	Globals.Game.spawn_SFX("Music1", "Music", Entity.position, {"facing":Globals.Game.rng_facing()}, Entity.palette_ref, Entity.master_ref)
	Animator.play("Exploding")
#	Entity.free = true
#	Globals.Game.spawn_entity(Entity.master_ID, "TakoExplode", Entity.position, \
#			{"facing" : Entity.facing}, Entity.palette_ref, Entity.master_ref)	
#	Entity.play_audio("explosion3", {"vol" : -15, "bus":"PitchDown"})
#	Entity.play_audio("impact44", {"vol" : -10})
	
func kill(sound = true):
	if Animator.to_play_anim != "Kill":
		Animator.play("Kill")
		if sound: Entity.play_audio("impact25", {"vol" : -12})
	
func expire():
	Entity.free = true
	Globals.Game.spawn_SFX("TakoFlash", "TakoFlash", Entity.position, {"facing":Entity.facing}, Entity.palette_ref, Entity.master_ref)

func collision(landed := false, _orig_vel_x := 0, orig_vel_y := 0): # collided with a platform
	if Animator.to_play_anim != "Kill":
		if landed:
			match Entity.unique_data.tako_state:
				"base":
					Entity.velocity.y = -orig_vel_y
					if Animator.to_play_anim == "Active3":
						Entity.get_node("Sprite").rotation = 0
						Entity.rotate_sprite(Entity.velocity.angle())
		else:
			kill()

func landed_a_hit(_hit_data):
	kill(false)
		
func on_offstage():
	Entity.free = true
	
func _on_SpritePlayer_anim_finished(anim_name):
	match anim_name:
		"Exploding":
			Entity.free = true
			Globals.Game.spawn_entity(Entity.master_ID, "TakoExplode", Entity.position, \
					{"facing" : Entity.facing}, Entity.palette_ref, Entity.master_ref)	
			Entity.play_audio("explosion3", {"vol" : -15, "bus":"PitchDown"})
			Entity.play_audio("impact44", {"vol" : -10})
			
func _on_SpritePlayer_anim_started(anim_name):
	match anim_name:
		"Kill":
			sprite.modulate.a = 1.0
			Entity.velocity.set_vector(0, 0)

