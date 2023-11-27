extends Node

# holds all cross-nodes enumerations

enum detect {SOLID, CSOLID, PASS_SIDE, SOFT, SEMISOLIDWALLS, BLASTWALLS, BLASTCEILING, PLAYERS, MOBS}
enum char_state {DEAD, GRD_STANDBY, AIR_STANDBY, GRD_STARTUP, GRD_ACTIVE, GRD_REC,
		GRD_C_REC, GRD_D_REC, AIR_STARTUP, AIR_ACTIVE, AIR_REC, AIR_C_REC, AIR_D_REC, GRD_FLINCH_HITSTUN,
		AIR_FLINCH_HITSTUN, LAUNCHED_HITSTUN, GRD_RESISTED_HITSTUN, AIR_RESISTED_HITSTUN, GRD_ATK_STARTUP, 
		GRD_ATK_ACTIVE, GRD_ATK_REC, AIR_ATK_STARTUP, AIR_ATK_ACTIVE, AIR_ATK_REC, GRD_BLOCK, AIR_BLOCK,
		SEQ_USER, SEQ_TARGET, INACTIVE}
#enum burst {AVAILABLE, CONSUMED, EXHAUSTED}
enum atk_type {LIGHT, FIERCE, HEAVY, REINFORCE, SPECIAL, EX, SUPER, ENTITY, EX_ENTITY, SUPER_ENTITY}
enum compass {N, NNE, NNE2, NE, ENE, E, ESE, SE, SSE2, SSE, S, SSW, SSW2, SW, WSW, W, WNW, NW, NNW2, NNW}
enum angle_split {TWO, FOUR, FOUR_X, SIX, EIGHT, EIGHT_X, SIXTEEN}
enum hitspark_type {NONE, CUSTOM, HIT, SLASH}
enum knockback_type {FIXED, RADIAL, MIRRORED, VELOCITY}
enum chain_combo {RESET, NO_CHAIN, WHIFF, NORMAL, HEAVY, SPECIAL, BLOCKED, PARRIED, SUPER}
enum priority {aL, gL, aF, gF, aH, gH, aSp, gSp, aEX, gEX, aRF, gRF, SUPER}
enum js_cancel_target {ALL, NONE, SPECIALS}
enum atk_attr {ASSIST, NO_CHAIN, ANTI_AIR, AUTOCHAIN, FOLLOW_UP, LEDGE_DROP, NO_TURN, NO_QUICK_CANCEL
		NO_REC_CANCEL, SEMI_INVUL_STARTUP, UNBLOCKABLE, SCREEN_SHAKE, NO_IMPULSE
		SUPERARMOR_STARTUP, SUPERARMOR_ACTIVE, P_SUPERARMOR_STARTUP, P_SUPERARMOR_ACTIVE, 
		PROJ_ARMOR_ACTIVE, WEAKARMOR_STARTUP, WEAKARMOR_ACTIVE, P_WEAKARMOR_STARTUP, P_WEAKARMOR_ACTIVE
		DRAG_KB, NO_STRAFE_NORMAL, STRAFE_NON_NORMAL, REPEATABLE, CAN_REPEAT_ONCE, DI_MANUAL_SEAL, NO_CROSSUP
		ONLY_CHAIN_ON_HIT, ONLY_CHAIN_INTO_ON_HIT, CANNOT_CHAIN_INTO, LATE_CHAIN, LATE_CHAIN_INTO, CRUSH
		JUMP_CANCEL_ACTIVE, JUMP_CANCEL_ON_WHIFF, JUMP_CANCEL_ON_HIT, DASH_CANCEL_ACTIVE, DASH_CANCEL_ON_WHIFF, DASH_CANCEL_ON_HIT, NO_ACTIVE_CANCEL
		VULN_LIMBS, DESTROY_ENTITIES, DESTRUCTIBLE_ENTITY, INDESTRUCTIBLE_ENTITY, HARMLESS_ENTITY, NO_REFLECT_ENTITY
		NO_TERMINAL_VEL_ACTIVE, FIXED_KNOCKBACK_STR, NO_SS_ATK_LVL_BOOST, QUICK_GRAB, GRAB_INVULN_STARTUP, WHIFF_SDASH_CANCEL
		AIR_REPEAT, REFLECT_ENTITIES, NO_SDASH_CANCEL, NO_SDC_DURING_ACTIVE, CAN_SDC_DURING_REC, PUNISH_ENTITY, NO_HITCOUNT_RESET
		CHIPPER, LAST_HIT_WAVE, REPEL_ON_BLOCK, CROSSUP_PROTECTION, SS_LAUNCH}
# ASSIST = add "Assist" behind move name when adding to Repeat Memory
# NO_CHAIN = mostly for autochain moves, some can chain but some cannot
# ANTI_AIR = startup and active are immune to non-grounded moves above you on the same tier
# AUTOCHAIN = for rekkas and supers with more than one strike for non-finishers, will have fixed KB and hitstun, considered weak hits
# FOLLOW_UP = follow-ups for autochain moves, deal no RES drain, does not proc RES Swell
# NO_REC_CANCEL = cannot jump/dash/fdash/fastfall cancel recovery frames, but still can chain
# LEDGE_DROP = if move during attack will fall off ledges
# NO_TURN = prevent turning during startup
# NO_QUICK_CANCEL = prevent quick canceling during startup
# //	NOT_FROM_MOVE_REC = cannot do from cancellable recovery
# SEMI_INVUL_STARTUP = startup is invulnerable to anything but EX Moves/Supers
# UNBLOCKABLE = certain attacks that are not physical specials are unblockable
# SCREEN_SHAKE = cause screen to shake on hit
# NO_IMPULSE = cannot do impulse, for secondary hits of autochained moves
# SUPERARMOR_STARTUP = armor all attacks during startup frames
# SUPERARMOR_ACTIVE = armor all attacks during active frames
# P_SUPERARMOR_STARTUP = armor all attacks during startup frames if RES is >= 0
# P_SUPERARMOR_ACTIVE = armor all attacks during active frames if RES is >= 0
# PROJ_ARMOR_ACTIVE = armor all projectiles during active frames
# WEAKARMOR_STARTUP = armor all Normals/non-strong projectiles during startup frames
# WEAKARMOR_ACTIVE = armor all Normals/non-strong projectiles during active frames
# P_WEAKARMOR_STARTUP = armor all Normals/non-strong projectiles during startup frames if RES is >= 0
# P_WEAKARMOR_ACTIVE = armor all Normals/non-strong projectiles during active frames if RES is >= 0
# DRAG_KB = for multi-hit moves, unless it is the last one, knockback = velocity of the attacker/entity
# NO_STRAFE_NORMAL = for certain aerial normals, prevent air strafing during active frames
# STRAFE_NON_NORMAL = for certain aerial non-normals, allow air strafing during active frames
# REPEATABLE = will not incur repeat penalty, use for multi-entities
# CAN_REPEAT_ONCE = no penalty on partial penalty
# DI_MANUAL_SEAL = seal DI till next hit
# NO_CROSSUP = cannot crossup
# ONLY_CHAIN_ON_HIT = cannot chain into other moves on whiff and block
# ONLY_CHAIN_INTO_ON_HIT = cannot chain into from other moves on whiff and block, for command dashes?
# CANNOT_CHAIN_INTO = automatically fails test_chain_combo(), for stuff like command grabs
# LATE_CHAIN = can only chain into other moves during recovery and not active frames
# LATE_CHAIN_INTO = can only be chained into from other moves during recovery and not active frames
# CRUSH = cause Crush on punish hits, score punish hits on hitting opponent during startup
# JUMP_CANCEL_ACTIVE = can jump cancel during active frames on hit
# JUMP_CANCEL_ON_WHIFF = can jump cancel during recovery on whiff
# JUMP_CANCEL_ON_HIT = can jump cancel during recovery on hit, for Specials since can already do it for Normals
# DASH_CANCEL_ACTIVE = can dash cancel during active frames on hit
# DASH_CANCEL_ON_WHIFF = can dash cancel during recovery on whiff
# DASH_CANCEL_ON_HIT = can dash cancel during recovery on hit, for Specials since can already do it for Normals
# NO_ACTIVE_CANCEL = for certain sweetspotted normals and heavies
# VULN_LIMBS = take full damage from SDHits
# DESTROY_ENTITIES = hitbox destroys entities, mostly for other entities
# DESTRUCTIBLE_ENTITY = this entity can be destroyed by opponent's non-projectile attacks
# INDESTRUCTIBLE_ENTITY = this entity cannot be destroyed by attacks with DESTROY_ENTITIES attribute
# HARMLESS_ENTITY = this entity has a hitbox but does not hit opponent (for clashing and being destroyed)
# NO_REFLECT_ENTITY = this entity cannot be reflected
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
# PUNISH_ENTITY = entity can land punish hit without being Proj Level 3, used for projectiles with special effects on landing punish hits
# NO_HITCOUNT_RESET = attack does not reset hitcount on being active frames being animated, used for multi-part attacks sharing hitcount
# CHIPPER = on block/armored deals base damage + chip damage
# LAST_HIT_WAVE = for multi-hit wave-type entities that have 999 ignore time and pass on their hitcount, last one will always do LAST_HIT
# REPEL_ON_BLOCK = on block, repel defender away
# CROSSUP_PROTECTION = iframes/armor/anti-air will work on cross-up
# SS_LAUNCH = on sweetspot, knockback is set to at least launch threshold

enum status_effect {LETHAL, STUN, STUN_RECOVER, RESPAWN_GRACE, POS_FLOW, POISON, CHILL, IGNITE, ENFEEBLE, SLOWED, INVERT_DIR
		NO_CROSSUP, SCANNED}
# STUN_RECOVER = get this when you got stunned, remove when out of hitstun and recovery some RES Gauge

enum block_state {UNBLOCKED, PARRIED, BLOCKED}
enum trait {AIR_CHAIN_DASH, VULN_GRD_DASH, VULN_AIR_DASH, PASSIVE_WEAKARMOR, D_REC_BLOCK
		DASH_IMPULSE, PERMA_SUPERARMOR, NO_LAUNCH, GRD_DASH_JUMP, AIR_DASH_JUMP}
# PASSIVE_WEAKARMOR = when RES is full, gain superarmor to Light/Fierce/non-strong projectiles
# D_REC_BLOCK = can block out of dash recovery, for heavy characters only
# DASH_IMPULSE = can impulse during D_REC, used for characters with certain unique dashes (like blinking)
# GRD/AIR_DASH_JUMP = can jump while dashing

#enum reset_type {STARTUP_RESET, ACTIVE_RESET}
# STARTUP_RESET = can only a_reset this Special during startup just like Normals
## EARLY_RESET = can a_reset within 1st 3 frames of the active frames of this Special
# ACTIVE_RESET = can a_reset anytime during active frames of this Special

enum move {ROOT, ATK_TYPE, HITCOUNT, DMG, KB, KB_TYPE, KB_ANGLE, ATK_LVL, ATK_ATTR, MOVE_SOUND, HIT_SOUND, BURST
		FIXED_HITSTOP, FIXED_HITSTOP_MULTI, FIXED_ATKER_HITSTOP, FIXED_ATKER_HITSTOP_MULTI, 
		FIXED_SS_HITSTOP, FIXED_HITSTUN, FIXED_KB_MULTI, FIXED_KB_ANGLE_MULTI
		PRIORITY_ADD, IGNORE_TIME, HITSPARK_TYPE, HITSPARK_PALETTE, SEQ, STARTER, SEQ_HITS, SEQ_LAUNCH
		SEQ_HITSTOP, SEQ_WEAK, PROJ_LVL, BURSTLOCK, REKKA, MULTI_HIT_REFRESH, LAST_HIT_RANGE}
# PROJ_LVL
# REKKA = can only QC into another move with the same REKKA
# MULTI_HIT_REFRESH = an array of Animator.time to refresh ignore time, also give 999 ignore time, after last entry hit become LAST_HIT
# LAST_HIT_RANGE = for multi-hit moves, if Animator.time >= LAST_HIT_RANGE, become LAST_HIT

enum hit {RECT, POLYGON, OWNER_ID, FACING, MOVE_NAME, MOVE_DATA, MOB, HURTBOX, SDHURTBOX, HITBOX, SWEETBOX, KBORIGIN, VACPOINT
		ATKER_ID, DEFENDER_ID, HIT_CENTER, ATK_FACING, DEFEND_FACING, TOUGH_MOB, NO_HIT_SOUND_MOB
		CANCELLED, ENTITY_PATH, NPC_PATH, ATKER, ATKER_OR_ENTITY, DEFENDER, ANGLE_TO_ATKER, LETHAL_HIT, PUNISH_HIT, CRUSH, STUN, BLOCK_STATE
		REPEAT, DOUBLE_REPEAT, ANTI_AIRED, PULL, SECONDARY_HIT, LAST_HIT, SINGLE_REPEAT, SOUR_HIT, GUARDCRASH
		MULTIHIT, FIRST_HIT, AUTOCHAIN, FOLLOW_UP, NON_STRONG_PROJ, WEAKARMORABLE, WEAK_HIT, SUPERARMORED, HITSTOP, DEALT_DMG
		ADJUSTED_ATK_LVL, KB, KB_ANGLE, SEMI_DISJOINT, SWEETSPOTTED, PULL, MOB_BREAK, RESISTED, SDASH_ARMORED, MOB_ARMORED, IGNORE_RESIST
		DEFENDER_MOVE_DATA, DEFENDER_ATTR, NPC_DEFENDER_PATH, PROJ_ON_HITSTOP, CROSSED_UP}
#// RES_DRAIN, CORNERED

enum entity_trait {GROUNDED, LEDGE_STOP, BLAST_BARRIER_COLLIDE, PERMANENT, BEAM, NO_BOUNCE, FLOATY_ITEM, SPAWN_OFFSET}
enum afterimage_shader {NONE, MASTER, MONOCHROME, WHITE}
enum mov_platform {MOVING, WARPING, ACTIVATE, ANIMATE, AUDIO}
enum dmg_num_col {WHITE, RED, GRAY, GREEN}
enum mob_attr {POWER, HP, TOUGH, SPEED, CHAIN, TRAIL, BLACK_TRAIL, WHITE_TRAIL, PROJ_SPEED,
		PROJ_TRAIL, WHITE_PROJ_TRAIL, BLACK_PROJ_TRAIL, RAGE, PRISM, PASSIVE_ARMOR}
enum peak_flag {GROUNDED, JUMPING, PEAK, PEAK_SPENT} # for mob AI command
enum strafe_style {NONE, TOWARDS, AWAY, AWAY_ON_DESCEND}
enum field_target {EFFECTS, MOBS, MOB_ENTITIES, PLAYERS, PLAYER_ENTITIES, OPPONENTS, OPPONENT_ENTITIES, MASTER, MASTER_ENTITIES
	NPCS, MASTER_NPCS, OPPONENT_NPCS}
enum wall_slam {CANNOT_SLAM, CAN_SLAM, HAS_SLAMMED}
enum success_block {NONE, PARRIED, BLOCKED}
enum afterimage_type {CHAR, ENTITY, NPC}
enum sticky_sfx_type {CHAR, ENTITY, NPC}
enum seq_partner {CHAR, ENTITY, NPC, ASSIST}
enum assist {NEUTRAL, DOWN, UP}

enum button {P1_UP, P1_DOWN, P1_LEFT, P1_RIGHT, P1_JUMP, P1_LIGHT, P1_FIERCE, P1_DASH, P1_BLOCK, P1_AUX, P1_MODIFIER, 
		P1_UNIQUE, P1_PAUSE, P1_RS_LEFT, P1_RS_RIGHT, P1_RS_UP, P1_RS_DOWN
		P2_UP, P2_DOWN, P2_LEFT, P2_RIGHT, P2_JUMP, P2_LIGHT, P2_FIERCE, P2_DASH, P2_BLOCK, P2_AUX, P2_MODIFIER, P2_UNIQUE,
		P2_PAUSE, P2_RS_LEFT, P2_RS_RIGHT, P2_RS_UP, P2_RS_DOWN}

