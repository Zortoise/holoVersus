extends Node2D

var UniqEffect

# to save:
var free := false

var master_ID: int # can be different from creator

var effect_ref: String

var lifetime := 0
var lifespan = null
var unique_data = {} # data unique for the entity, stored as a dictionary
var effect_ID := 0
var birth_time := 0


func init(in_master_ID: int, in_effect_ref: String, aux_data: Dictionary):
	
	effect_ID = Globals.Game.entity_ID_ref
	Globals.Game.entity_ID_ref += 1
	birth_time = Globals.Game.frametime
	
	master_ID = in_master_ID
	effect_ref = in_effect_ref
	
	load_effect()
		
	if "UNIQUE_DATA_REF" in UniqEffect:
		unique_data = UniqEffect.UNIQUE_DATA_REF.duplicate(true)
		
	UniqEffect.init(aux_data)
	
		
func load_effect():

	if effect_ref in Loader.effect_data:
		UniqEffect = Loader.effect_data[effect_ref].scene.instance() # load UniqEffect scene
	else:
		print("Error: " + effect_ref + " effect not found in Loader.effect_data")

	add_child(UniqEffect)
	move_child(UniqEffect, 0)
			
	if UniqEffect.has_method("load_effect"):
		UniqEffect.load_effect()
				

func simulate():
	
	if Globals.Game.is_stage_paused(): return
	if free: return
	
	UniqEffect.simulate()
	
	if free:
		return
		
	lifetime += 1
	if !Em.entity_trait.PERMANENT in UniqEffect.TRAITS and lifetime >= Globals.ENTITY_AUTO_DESPAWN:
		free = true
	elif lifespan != null and lifetime >= lifespan and UniqEffect.has_method("expire"):
		UniqEffect.expire()


func save_state():
	var state_data = {
		"effect_ref" : effect_ref,
		"master_ID" : master_ID,
		
		"free" : free,
		"lifetime" : lifetime,
		"lifespan" : lifespan,
		"unique_data" : unique_data,
		"effect_ID" : effect_ID,
		"birth_time" : birth_time,
	}
	return state_data

func load_state(state_data):

	effect_ref = state_data.effect_ref
	master_ID = state_data.master_ID

	effect_ID = state_data.effect_ID
	
	birth_time = state_data.birth_time
	load_effect()
	
	free = state_data.free
	lifetime = state_data.lifetime
	lifespan = state_data.lifespan
	unique_data = state_data.unique_data

		
#--------------------------------------------------------------------------------------------------
