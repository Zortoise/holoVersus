extends Node

const AIR_STRAFE_SPEED_MOD = [Em.class_type.class2, 7, 10, 16] # percent of ground speed
const AIR_STRAFE_LIMIT_MOD = [Em.class_type.class2, 900, 800, 700] # speed limit of air strafing, limit depends on calculated air strafe speed

const VAR_JUMP_TIME = [Em.class_type.class2, 7, 10, 20] # frames after jumping where holding jump will reduce gravity

const VAR_JUMP_SLOW_POINT = 5 # frames where JUMP_SLOW starts
const DIR_JUMP_HEIGHT_MOD = 85 # % of JUMP_SPEED when jumping while holding left/right
const HORIZ_JUMP_BOOST_MOD = 20 # % of SPEED to gain when jumping with left/right held
const HORIZ_JUMP_SPEED_MOD = 150 # % of velocity.x to gain when jumping with left/right held
const AIR_HORIZ_JUMP_SPEED_MOD = 125
const HIGH_JUMP_SLOW = 10 # slow down velocity.y to PEAK_DAMPER_LIMIT when jumping with up/jump held
const SHORT_JUMP_SLOW = 20 # slow down velocity.y to PEAK_DAMPER_LIMIT when jumping with up/jump unheld

const AIR_JUMP_HEIGHT_MOD = [Em.class_type.class2, 90, 90, 70] # percentage of JUMP_SPEED, reduce height of air jumps
const REVERSE_AIR_JUMP_MOD = 70 # percentage of SPEED when air jumping backwards
const WALL_AIR_JUMP_HORIZ_MOD = 150 # percentage of SPEED when wall jumping
const WALL_AIR_JUMP_VERT_MOD = [Em.class_type.class2, 100, 100, 70] # percentage of JUMP_SPEED when wall jumping
const GRAVITY_MOD = [Em.class_type.class2, 110, 100, 90]
const TERMINAL_VELOCITY_MOD = [Em.class_type.class2, 800, 800, 600] # affect terminal velocity downward
const FASTFALL_MOD = [Em.class_type.class2, 100, 100, 115] # fastfall speed, mod of terminal velocity
const FRICTION = 15 # between 0 and 100
const ACCELERATION = 20 # between 0 and 100
const AIR_RESISTANCE = 3 # between 0 and 100
const FALL_GRAV_MOD = [Em.class_type.class2, 120, 100, 40] # reduced gravity when going down

const MAX_AIR_DODGE = 1
const MAX_SUPER_DASH = 1
const GRD_DASH_SPEED = [Em.class_type.class2, 450 * FMath.S, 500 * FMath.S, 550 * FMath.S] # duration in animation data
const AIR_DASH_SPEED = [Em.class_type.class2, 350 * FMath.S, 400 * FMath.S, 450 * FMath.S] # duration in animation data
const SDASH_SPEED = [Em.class_type.class2, 500 * FMath.S, 450 * FMath.S, 385 * FMath.S] # super dash
const SDASH_TURN_RATE = [Em.class_type.class2, 4, 5, 6] # exact navigate speed when sdashing

const IMPULSE_MOD = [Em.class_type.class2, 175, 150, 75] # multiply by SPEED to get impulse velocity
const WAVE_DASH_SPEED_MOD = [Em.class_type.class2, 130, 110, 90] # affect speed of wavelanding, multiplied by GRD_DASH_SPEED

#/////////////////////////////////////////////////

const DAMAGE_VALUE_LIMIT = 1000
const VULNERABILITY_MOD = [Em.class_type.class1, 90, 100, 110] # multiply most taken damage

const DODGE_RES_COST = [Em.class_type.class1, 4000, 3500, 3000]
const DODGE_SPEED = 1000 * FMath.S

const REINFORCE_COST = [Em.class_type.class1, 3000, 4000, 5000]

const RES_REGEN_AMOUNT = [Em.class_type.class1, 25, 20, 15] # exact RES regened per frame when RES < 100%
const GRD_BLOCK_RES_COST = [Em.class_type.class1, 13, 15, 17] # exact RES loss per frame when blocking on ground
const AIR_BLOCK_RES_COST = [Em.class_type.class1, 18, 20, 25] # exact RES loss per frame when blocking in air
const CHIP_DMG_MOD = [Em.class_type.class1, 20, 40, 50] # % of damage taken as chip damage when blocking
const PROJ_ARMOR_RES_DRAIN_MOD = [Em.class_type.class1, 300, 400, 500] # RES_Drain when armoring through projectiles

const BASE_EX_REGEN = 20
const HITSTUN_EX_REGEN_MOD = 200  # increase EX Regen during hitstun
const LANDED_EX_REGEN_MOD = 600 # increase EX Regen when doing an unblocked attack
const BLOCKED_EX_REGEN_MOD = 200 # increase EX Regen when doing a blocked attack
const BLOCKING_EX_REGEN_MOD = 200 # increase EX Regen when blocking attack
const PARRYING_EX_REGEN_MOD = 600 # increase EX Regen when parrying attack

const ULT_GEN = 0
#const ULT_GEN = 2000 # amount of Ulimate Gauge gain per frame


func retrieve(stat:String, class1:int, class2:int):
	if !stat in self:
		print("Error: Stat " + stat + " not found in StandardStats.gd")
		return null
	var value = get(stat)
	if !value is Array:
		return value
	else:
		match value[0]:
			Em.class_type.class1:
				return value[1 + class1]
			Em.class_type.class2:
				return value[1 + class2]
