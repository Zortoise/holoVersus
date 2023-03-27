extends Node

# holds all cross-nodes enumerations

enum char_state {DEAD, GROUND_STANDBY, CROUCHING, AIR_STANDBY, GROUND_STARTUP, GROUND_ACTIVE, GROUND_REC,
		GROUND_C_REC, GROUND_D_REC, AIR_STARTUP, AIR_ACTIVE, AIR_REC, AIR_C_REC, AIR_D_REC, GROUND_FLINCH_HITSTUN,
		AIR_FLINCH_HITSTUN, LAUNCHED_HITSTUN, GROUND_RESISTED_HITSTUN, AIR_RESISTED_HITSTUN, GROUND_ATK_STARTUP, 
		GROUND_ATK_ACTIVE, GROUND_ATK_REC, AIR_ATK_STARTUP, AIR_ATK_ACTIVE, AIR_ATK_REC, GROUND_BLOCK, AIR_BLOCK,
		SEQUENCE_USER, SEQUENCE_TARGET}
enum burst {AVAILABLE, CONSUMED, EXHAUSTED}
enum atk_type {LIGHT, FIERCE, HEAVY, SPECIAL, EX, SUPER, ENTITY, SUPER_ENTITY}
enum compass {N, NNE, NNE2, NE, ENE, E, ESE, SE, SSE2, SSE, S, SSW, SSW2, SW, WSW, W, WNW, NW, NNW2, NNW}
enum angle_split {TWO, FOUR, FOUR_X, SIX, EIGHT, EIGHT_X, SIXTEEN}
enum hitspark_type {NONE, CUSTOM, HIT, SLASH}
enum knockback_type {FIXED, RADIAL, MIRRORED, VELOCITY}
enum chain_combo {RESET, NO_CHAIN, NORMAL, HEAVY, SPECIAL, WEAKBLOCKED, STRONGBLOCKED, SUPER}
enum priority {aL, gL, aF, gF, aH, gH, aSp, gSp, aEX, gEX, SUPER}
enum atk_attr {NO_CHAIN, ANTI_AIR, AUTOCHAIN, FOLLOW_UP, LEDGE_DROP, NO_TURN, NO_QUICK_CANCEL, NOT_FROM_MOVE_REC
		NO_REC_CANCEL, SEMI_INVUL_STARTUP, UNBLOCKABLE, SCREEN_SHAKE, NO_IMPULSE
		SUPERARMOR_STARTUP, SUPERARMOR_ACTIVE, PROJ_ARMOR_ACTIVE, NORMALARMOR_STARTUP, NORMALARMOR_ACTIVE
		DRAG_KB, NO_STRAFE_NORMAL, STRAFE_NON_NORMAL, REPEATABLE, DI_MANUAL_SEAL
		ONLY_CHAIN_ON_HIT, CANNOT_CHAIN_INTO, LATE_CHAIN, LATE_CHAIN_INTO, CRUSH
		VULN_LIMBS, NO_REPEAT_MOVE, DESTROY_ENTITIES, DESTRUCTIBLE_ENTITY, INDESTRUCTIBLE_ENTITY, HARMLESS_ENTITY
		NO_TERMINAL_VEL_ACTIVE, FIXED_KNOCKBACK_STR, NO_SS_ATK_LVL_BOOST, QUICK_GRAB, GRAB_INVULN_STARTUP, WHIFF_SDASH_CANCEL
		AIR_REPEAT, REFLECT_ENTITIES, NO_SDASH_CANCEL, NO_SDC_DURING_ACTIVE, CAN_SDC_DURING_REC}
# NO_CHAIN = mostly for autochain moves, some can chain but some cannot
# ANTI_AIR = startup and active are immune to non-grounded moves above you on the same tier
# AUTOCHAIN = for rekkas and supers with more than one strike for non-finishers, will have fixed KB and hitstun, considered weak hits
# FOLLOW_UP = follow-ups for autochain moves, deal no Guard Drain, does not proc Guard Swell
# NO_REC_CANCEL = cannot jump/dash/fdash/fastfall cancel recovery frames, but still can chain
# LEDGE_DROP = if move during attack will fall off ledges
# NO_TURN = prevent turning during startup
# NO_QUICK_CANCEL = prevent quick canceling during startup
# NOT_FROM_MOVE_REC = cannot do from cancellable recovery
# SEMI_INVUL_STARTUP = startup is invulnerable to anything but EX Moves/Supers
# UNBLOCKABLE = certain attacks that are not physical specials are unblockable
# SCREEN_SHAKE = cause screen to shake on hit
# NO_IMPULSE = cannot do impulse, for secondary hits of autochained moves
# SUPERARMOR_STARTUP = weakblock all attacks during startup frames
# SUPERARMOR_ACTIVE = weakblock all attacks during active frames
# PROJ_ARMOR_ACTIVE = weakblock all projectiles during active frames
# NORMALARMOR_STARTUP = weakblock all Normals/non-strong projectiles during startup frames
# NORMALARMOR_ACTIVE = weakblock all Normals/non-strong projectiles during active frames
# DRAG_KB = for multi-hit moves, unless it is the last one, knockback = velocity of the attacker/entity
# NO_STRAFE_NORMAL = for certain aerial normals, prevent air strafing during active frames
# STRAFE_NON_NORMAL = for certain aerial non-normals, allow air strafing during active frames
# REPEATABLE = will not incur repeat penalty, use for multi-entities
# DI_MANUAL_SEAL = seal DI till next hit
# ONLY_CHAIN_ON_HIT = cannot chain into other moves on whiff and weakblock
# CANNOT_CHAIN_INTO = automatically fails test_chain_combo(), for stuff like command grabs
# LATE_CHAIN = can only chain into other moves during recovery and not active frames
# LATE_CHAIN_INTO = can only be chained into from other moves during recovery and not active frames
# CRUSH = cause Crush on punish hits, score punish hits on hitting opponent during startup
# VULN_LIMBS = take full damage from SDHits
# NO_REPEAT_MOVE = a move that can only be repeated once
# DESTROY_ENTITIES = hitbox destroys entities
# DESTRUCTIBLE_ENTITY = this entity can be destroyed by opponent's non-projectile attacks
# INDESTRUCTIBLE_ENTITY = this entity cannot be destroyed by attacks with DESTROY_ENTITIES attribute
# HARMLESS_ENTITY = this entity has a hitbox but does not hit opponent (for clashing and being destroyed)
# NO_TERMINAL_VEL_ACTIVE = no terminal velocity on active frames
# FIXED_KNOCKBACK_STR = fixed knockback, used for nothing currently but may be useful
# NO_SS_ATK_LVL_BOOST = no sweetspot boost in atk level, for sweetspot hitgrabs
# QUICK_GRAB = command grab that fails if target is in movement STARTUP
# GRAB_INVULN_STARTUP = immune to command grabs during startup, for slower command grabs
# WHIFF_SDASH_CANCEL = can s_dash cancel on whiff
# AIR_REPEAT = not logged in aerial_sp_memory but is in aerial_memory
# REFLECT_ENTITIES = reflect entities touched by hitbox
# NO_SDASH_CANCEL = cannot be SDash Cancelled
# NO_SDC_DURING_ACTIVE = cannot SDash Cancel during active, for non-damaging moves
# CAN_SDC_DURING_REC = can SDash Cancel during recovery

enum status_effect {LETHAL, STUN, STUN_RECOVER, CRUSH, RESPAWN_GRACE, POS_FLOW, POISON, CHILL, IGNITE, ENFEEBLE, SLOWED}
# STUN_RECOVER = get this when you got stunned, remove when out of hitstun and recovery some Guard Gauge

enum block_state {UNBLOCKED, STRONG, WEAK}
enum trait {AIR_CHAIN_DASH, VULN_GRD_DASH, VULN_AIR_DASH, AIR_PERFECT_BLOCK, WAVE_DASH_BLOCK, AIR_DASH_BLOCK, PASSIVE_NORMALARMOR, 
		PERMA_SUPERARMOR, NO_LAUNCH}
# PASSIVE_NORMALARMOR = when GG is full, gain superarmor to Light/Fierce/non-strong projectiles

#enum reset_type {STARTUP_RESET, ACTIVE_RESET}
# STARTUP_RESET = can only a_reset this Special during startup just like Normals
## EARLY_RESET = can a_reset within 1st 3 frames of the active frames of this Special
# ACTIVE_RESET = can a_reset anytime during active frames of this Special

enum move {ROOT, ATK_TYPE, HITCOUNT, DMG, KB, KB_TYPE, KB_ANGLE, ATK_LVL, ATK_ATTR, MOVE_SOUND, HIT_SOUND, BURST
		FIXED_HITSTOP, FIXED_ATKER_HITSTOP, FIXED_SS_HITSTOP, FIXED_HITSTUN, FIXED_KB_MULTI, FIXED_KB_ANGLE_MULTI
		PRIORITY_ADD, IGNORE_TIME, HITSPARK_TYPE, HITSPARK_PALETTE, SEQ, STARTER, SEQ_HITS, SEQ_LAUNCH
		SEQ_HITSTOP, SEQ_WEAK, PROJ_LVL, BURSTLOCK}

enum hit {RECT, POLYGON, OWNER_ID, FACING, MOVE_NAME, MOVE_DATA, MOB, HURTBOX, SDHURTBOX, HITBOX, SWEETBOX, KBORIGIN, VACPOINT
		ATKER_ID, DEFENDER_ID, HIT_CENTER, ATK_FACING, DEFEND_FACING
		CANCELLED, ENTITY_PATH, ATKER, ATKER_OR_ENTITY, DEFENDER, ANGLE_TO_ATKER, LETHAL_HIT, PUNISH_HIT, CRUSH, STUN, BLOCK_STATE
		REPEAT, DOUBLE_REPEAT, ANTI_AIRED, PULL
		MULTIHIT, FIRST_HIT, AUTOCHAIN, FOLLOW_UP, NON_STRONG_PROJ, NORMALARMORABLE, CORNERED, WEAK_HIT, SUPERARMORED, HITSTOP, DEALT_DMG
		ADJUSTED_ATK_LVL, KB, KB_ANGLE, SEMI_DISJOINT, SWEETSPOTTED, PULL, MOB_BREAK, RESISTED, SDASH_ARMORED}


enum entity_trait {GROUNDED, LEDGE_STOP, BLAST_BARRIER_COLLIDE}
enum afterimage_shader {NONE, MASTER, MONOCHROME, WHITE}
enum moving_platform {MOVING, WARPING}
enum dmg_num_col {WHITE, RED, GRAY, GREEN}
enum mob_attr {POWER, HP, TOUGH, SPEED, CHAIN, TRAIL, BLACK_TRAIL, WHITE_TRAIL, PROJ_SPEED,
		PROJ_TRAIL, WHITE_PROJ_TRAIL, BLACK_PROJ_TRAIL, RAGE, COIN, PASSIVE_ARMOR}
enum peak_flag {GROUNDED, JUMPING, PEAK, PEAK_SPENT} # for mob AI command
enum strafe_style {NONE, TOWARDS, AWAY, AWAY_ON_DESCEND}
enum field_target {EFFECTS, MOBS, MOB_ENTITIES, PLAYERS, PLAYER_ENTITIES, OPPONENTS, OPPONENT_ENTITIES, MASTER, MASTER_ENTITIES}

enum button {P1_UP, P1_DOWN, P1_LEFT, P1_RIGHT, P1_JUMP, P1_LIGHT, P1_FIERCE, P1_DASH, P1_BLOCK, P1_AUX, P1_SPECIAL, 
		P1_UNIQUE, P1_PAUSE, P1_RS_LEFT, P1_RS_RIGHT, P1_RS_UP, P1_RS_DOWN
		P2_UP, P2_DOWN, P2_LEFT, P2_RIGHT, P2_JUMP, P2_LIGHT, P2_FIERCE, P2_DASH, P2_BLOCK, P2_AUX, P2_SPECIAL, P2_UNIQUE,
		P2_PAUSE, P2_RS_LEFT, P2_RS_RIGHT, P2_RS_UP, P2_RS_DOWN}

