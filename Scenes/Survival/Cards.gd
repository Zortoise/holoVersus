extends Node

enum type {PERCENT, LINEAR, QUIRK}

enum effect_ref {
		STOCK, HP, COMBO_LEVEL, LANDED_EX_REGEN, PASSIVE_EX_REGEN, HITSTUN_EX_REGEN
		SPEED, FRICTION, JUMP_SPEED, GRAVITY_MOD, MAX_AIR_JUMP, MAX_AIR_DASH, MAX_AIR_DODGE, MAX_SUPER_DASH, 
		GRD_DASH_SPEED, AIR_DASH_SPEED, SDASH_SPEED, DODGE_SPEED,
		GUARD_DRAIN_MOD,
		GRD_NORMAL_DMG_MOD, AIR_NORMAL_DMG_MOD, LIGHT_DMG_MOD, FIERCE_DMG_MOD,
		HEAVY_DMG_MOD, SPECIAL_DMG_MOD, PROJ_DMG_MOD, SUPER_DMG_MOD, ASSIST_DMG_MOD
		COIN_GAIN, LIFESTEAL_RATE, HITSTUN_TAKEN, EXTRA_HITSTOP,
		LESS_GUARD_DRAIN, NO_CROSSUP, CAN_REPEAT, FULL_DAMAGE, AUTO_PARRY_PROJ, REDUCE_BURST_COST, SPECIAL_CHAIN,
		CAN_TRIP, REVENGE, DASH_IFRAME, SDASH_IFRAME, SUMMON_SHARK, HEAL_ON_KILL
		EX_RAISE_DMG, POISON_ATK, CHILLING_ATK, IGNITION_ATK, ENFEEBLING_ATK, RESPAWN_POWER, WILDCARD
		NO_BLOCK_COST, NO_CHIP_DMG, NO_DODGE_COST, BETTER_BLOCK, PASSIVE_WEAKARMOR, BLOCK_CANCEL, DODGE_CANCEL, AUTO_TECH, NO_HEIGHT_LIMIT
		SUMMON_HORROR, PHOENIX_PROJ, PEACOCK_PROJ, RAIN_PROJ, SUMMON_TAKO, KERIS_PROJ, SCYTHE_PROJ, TIME_BUBBLE, VORTEX, REWIND, TBLOCK_PROJ
		FLASK_PROJ, SUMMON_SSRB, SUMMON_NOUSAGI, FUWA_SLASH, MOCO_SLASH, RAVEN_PROJ, SUMMON_MOAI
}

const DESCRIBE = {
	effect_ref.STOCK : {
		"type" : type.LINEAR,
		"suffix" :"Stock",
	},
	
	effect_ref.HP : {
		"type" : type.PERCENT,
		"suffix" :"Max HP",
	},
	effect_ref.COMBO_LEVEL : {
		"type" : type.LINEAR,
		"suffix" :"Combo Level",
	},
	
	effect_ref.LANDED_EX_REGEN : {
		"type" : type.PERCENT,
		"suffix" :"EX Gain on Hit",
	},
	effect_ref.PASSIVE_EX_REGEN : {
		"type" : type.LINEAR,
		"suffix" :"Passive EX Gain",
	},
	effect_ref.HITSTUN_EX_REGEN : {
		"type" : type.PERCENT,
		"suffix" :"EX Gain when Atked",
	},
	
	effect_ref.FRICTION : {
		"type" : type.PERCENT,
		"suffix" :"Friction",
	},
	
	effect_ref.SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Movespeed",
	},
	effect_ref.JUMP_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Jump Power",
	},
	effect_ref.GRAVITY_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Gravity",
	},
	
	effect_ref.MAX_AIR_JUMP : {
		"type" : type.LINEAR,
		"suffix" :"Air Jump Count",
	},
	effect_ref.MAX_AIR_DASH : {
		"type" : type.LINEAR,
		"suffix" :"Air Dash Count",
	},
	effect_ref.MAX_AIR_DODGE : {
		"type" : type.LINEAR,
		"suffix" :"Air Dodge Count",
	},
	effect_ref.MAX_SUPER_DASH : {
		"type" : type.LINEAR,
		"suffix" :"Super Dash Count",
	},
	
	effect_ref.GRD_DASH_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Ground Dash Speed",
	},
	effect_ref.AIR_DASH_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Air Dash Speed",
	},
	effect_ref.SDASH_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Super Dash Speed",
	},
	effect_ref.DODGE_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Dodge Speed",
	},
	
	effect_ref.GUARD_DRAIN_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Guard Drain",
	},
	
	effect_ref.GRD_NORMAL_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Ground Normals Dmg",
	},
	effect_ref.AIR_NORMAL_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Air Normals Dmg",
	},
	effect_ref.LIGHT_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Light Atk Dmg",
	},
	effect_ref.FIERCE_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Fierce Atk Dmg",
	},
	
	effect_ref.HEAVY_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Heavy Atk Dmg",
	},
	effect_ref.SPECIAL_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Non-Proj Special Dmg",
	},
	effect_ref.PROJ_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Projectile Dmg",
	},
	effect_ref.SUPER_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Super Move Dmg",
	},
	effect_ref.ASSIST_DMG_MOD: {
		"type" : type.PERCENT,
		"suffix" :"Assist Dmg",
	},
	
	effect_ref.COIN_GAIN : {
		"type" : type.LINEAR,
		"suffix" :"Coin Gain",
	},
	effect_ref.LIFESTEAL_RATE : {
		"type" : type.PERCENT,
		"suffix" :"Lifesteal",
	},
	effect_ref.HITSTUN_TAKEN : {
		"type" : type.PERCENT,
		"suffix" :"Hitstun Taken",
	},
	effect_ref.EXTRA_HITSTOP : {
		"type" : type.LINEAR,
		"suffix" :"Hitstop on Foe",
	},
	
	effect_ref.LESS_GUARD_DRAIN : {
		"type" : type.QUIRK,
		"suffix" :"Less GG Loss When Atked",
	},
	effect_ref.NO_CROSSUP : {
		"type" : type.QUIRK,
		"suffix" :"Cross-Up Immunity",
	},
	effect_ref.CAN_REPEAT : {
		"type" : type.QUIRK,
		"suffix" :"No Repeat Penalty",
	},
	effect_ref.FULL_DAMAGE : {
		"type" : type.QUIRK,
		"suffix" :"Always Full Damage",
	},
	effect_ref.AUTO_PARRY_PROJ : {
		"type" : type.QUIRK,
		"suffix" :"Auto-Parry Projectiles",
	},
#	effect_ref.FREE_RESET : {
#		"type" : type.QUIRK,
#		"suffix" :"Free Resets",
#	},
	effect_ref.REDUCE_BURST_COST : {
		"type" : type.QUIRK,
		"suffix" :"Reduce Burst Cost",
	},
	effect_ref.SPECIAL_CHAIN : {
		"type" : type.QUIRK,
		"suffix" :"Chainable Specials",
	},
	effect_ref.CAN_TRIP : {
		"type" : type.QUIRK,
		"suffix" :"Randomly Trips",
	},
	effect_ref.REVENGE : {
		"type" : type.QUIRK,
		"suffix" :"Stronger at Low HP",
	},
	
	effect_ref.DASH_IFRAME : {
		"type" : type.QUIRK,
		"suffix" :"Dashes has Iframes",
	},
	effect_ref.SDASH_IFRAME : {
		"type" : type.QUIRK,
		"suffix" :"Super Dash has Iframes",
	},
	effect_ref.SUMMON_SHARK : {
		"type" : type.QUIRK,
		"suffix" :"Summon Sharks",	
	},
	effect_ref.HEAL_ON_KILL : {
		"type" : type.QUIRK,
		"suffix" :"Heal on Kills",	
	},
	effect_ref.EX_RAISE_DMG : {
		"type" : type.QUIRK,
		"suffix" :"EX Gauge Raises Dmg",	
	},
	effect_ref.POISON_ATK : {
		"type" : type.QUIRK,
		"suffix" :"Poison Touch",	
	},
	effect_ref.CHILLING_ATK : {
		"type" : type.QUIRK,
		"suffix" :"Chilling Touch",	
	},
	effect_ref.IGNITION_ATK : {
		"type" : type.QUIRK,
		"suffix" :"Igniting Touch",	
	},
#	effect_ref.GRAVITIZING_ATK : {
#		"type" : type.QUIRK,
#		"suffix" :"Gravitizing Touch",	
#	},
	effect_ref.ENFEEBLING_ATK : {
		"type" : type.QUIRK,
		"suffix" :"Enfeebling Touch",	
	},
	effect_ref.RESPAWN_POWER : {
		"type" : type.QUIRK,
		"suffix" :"Full EX on Respawn",	
	},
	effect_ref.WILDCARD : {
		"type" : type.QUIRK,
		"suffix" :"Changes Every Wave",	
	},
	
	effect_ref.NO_BLOCK_COST : {
		"type" : type.QUIRK,
		"suffix" :"Blocking cost no GG",
	},
	effect_ref.NO_CHIP_DMG : {
		"type" : type.QUIRK,
		"suffix" :"No Chip Dmg Taken",
	},
	effect_ref.NO_DODGE_COST : {
		"type" : type.QUIRK,
		"suffix" :"Dodging cost no GG",
	},
#	effect_ref.PROXIMITY_PARRY : {
#		"type" : type.QUIRK,
#		"suffix" :"PBlock at Close Range",
#	},
	effect_ref.BETTER_BLOCK : {
		"type" : type.QUIRK,
		"suffix" :"Improved Blocking",
	},
	effect_ref.PASSIVE_WEAKARMOR: {
		"type" : type.QUIRK,
		"suffix" :"Weakarmor at Full GG",
	},
	effect_ref.BLOCK_CANCEL: {
		"type" : type.QUIRK,
		"suffix" :"Can Block during Recovery",
	},
	effect_ref.DODGE_CANCEL: {
		"type" : type.QUIRK,
		"suffix" :"Can Dodge during Recovery",
	},
	effect_ref.AUTO_TECH: {
		"type" : type.QUIRK,
		"suffix" :"Automatic Tech",
	},
	effect_ref.NO_HEIGHT_LIMIT: {
		"type" : type.QUIRK,
		"suffix" :"No Height Penalties",
	},
	effect_ref.SUMMON_HORROR: {
		"type" : type.QUIRK,
		"suffix" :"Summon Horror when Atked",
	},
	
	effect_ref.PHOENIX_PROJ: {
		"type" : type.QUIRK,
		"suffix" :"Shoot Feathers via Fierce",
	},
	effect_ref.RAVEN_PROJ: {
		"type" : type.QUIRK,
		"suffix" :"Shoot Feathers via Fierce",
	},
	effect_ref.PEACOCK_PROJ: {
		"type" : type.QUIRK,
		"suffix" :"Spawn Feathers via Block",
	},
	effect_ref.RAIN_PROJ: {
		"type" : type.QUIRK,
		"suffix" :"Shoot Droplet via Air Jump",
	},
	effect_ref.SUMMON_TAKO: {
		"type" : type.QUIRK,
		"suffix" :"Summon Takodachi",
	},
	effect_ref.KERIS_PROJ: {
		"type" : type.QUIRK,
		"suffix" :"Shoot Daggers via Light",
	},
	effect_ref.SCYTHE_PROJ: {
		"type" : type.QUIRK,
		"suffix" :"Summon Scythe via Heavy",
	},
	effect_ref.TIME_BUBBLE: {
		"type" : type.QUIRK,
		"suffix" :"Make TimeBubble via Dodge",
	},
	effect_ref.VORTEX: {
		"type" : type.QUIRK,
		"suffix" :"Heavy Hit creates Vortex",
	},
	effect_ref.REWIND: {
		"type" : type.QUIRK,
		"suffix" :"Rewind Self when Atked",
	},
	effect_ref.TBLOCK_PROJ: {
		"type" : type.QUIRK,
		"suffix" :"Call Blocks via Fierce",
	},
	effect_ref.FLASK_PROJ: {
		"type" : type.QUIRK,
		"suffix" :"Throw Flask via Block",
	},
	effect_ref.SUMMON_SSRB: {
		"type" : type.QUIRK,
		"suffix" :"Throw SSRB via Heavy",
	},
	effect_ref.SUMMON_NOUSAGI: {
		"type" : type.QUIRK,
		"suffix" :"Call Nousagi via Light",
	},
	effect_ref.FUWA_SLASH: {
		"type" : type.QUIRK,
		"suffix" :"Light Hit performs Slash",
	},
	effect_ref.MOCO_SLASH: {
		"type" : type.QUIRK,
		"suffix" :"Light Hit performs Slash",
	},
	effect_ref.SUMMON_MOAI: {
		"type" : type.QUIRK,
		"suffix" :"Summon Moai on Block",	
	}
}

const TRIP_CHANCE = 5
const SHARK_COOLDOWN = 300
const HORROR_COOLDOWN = 1000
const TAKO_COOLDOWN = 300
const KILL_HEAL_PERCENT = 40
const POISON_DURATION = 180
const POISON_DMG = 40
const CHILL_DURATION = 120
const CHILL_SLOW = 50
const IGNITE_DURATION = 90
const IGNITE_DMG = 50
#const GRAVITIZE_DURATION = 240
#const GRAVITIZE_DEGREE = 300
const ENFEEBLE_DURATION = 180
const ENFEEBLE_DEGREE = 50
const KERIS_COOLDOWN = 600
const PHOENIX_COOLDOWN = 300
const RAVEN_COOLDOWN = 300
const PEACOCK_COOLDOWN = 600
const SCYTHE_COOLDOWN = 600
const TBLOCK_COOLDOWN = 600
#const RAIN_COOLDOWN = 30
const TIME_BUBBLE_COOLDOWN = 1000
const VORTEX_COOLDOWN = 1000
const REWIND_COOLDOWN = 1000
const REWIND_RANGE = 120
const FLASK_COOLDOWN = 600
const NOUSAGI_COOLDOWN = 600
const SSRB_COOLDOWN = 1000
const SLASH_COOLDOWN = 600
const MOAI_COOLDOWN = 1000

# CARDS ------------------------------------------------------------------------------------------------------------------------------------

enum card_ref {
	GURA, INA, SORA, MARINE, AQUA, FLARE, NOEL, ROBOCO, SHION, BOTAN, LAMY, AYAME, IROHA,
	KORONE, MUMEI, KIARA, MORI, AMELIA, FAUNA, IRYS, IRYS_b, KOBO, FUBUKI, MIO, PEKORA, POLKA, HAATO, HAATO_b,
	SUISEI, KANATA, LUI, ANYA, COCO, RUSHIA, KRONII, MIKO, OLLIE, AKI, WATAME, 
	BAELZ, BAELZ_b, BAELZ_c, BAELZ_d, BAELZ_e, BAELZ_f, KAELA,
	MEL, TOWA, LUNA, CHLOE, KOYORI, SUBARU, ALOE, AZKI, OKAYU, CHOCO, MOONA, IOFIFTEEN,
	MATSURI, NENE, ZETA, REINE, RISU, LAPLUS, SANA, FUWAWA, MOCOCO, NERISSA, SHIORI, BIJOU
}

const LIST = [
	card_ref.GURA, card_ref.INA, card_ref.SORA, card_ref.MARINE, card_ref.AQUA, card_ref.FLARE, card_ref.NOEL,
	card_ref.ROBOCO, card_ref.SHION, card_ref.BOTAN, card_ref.LAMY, card_ref.AYAME, card_ref.IROHA,
	card_ref.KORONE, card_ref.MUMEI, card_ref.KIARA, card_ref.MORI, card_ref.AMELIA, card_ref.FAUNA, 
	card_ref.IRYS, card_ref.KOBO, card_ref.FUBUKI, card_ref.MIO, card_ref.PEKORA, card_ref.POLKA, card_ref.HAATO,
	card_ref.SUISEI, card_ref.KANATA, card_ref.LUI, card_ref.ANYA, card_ref.COCO, card_ref.RUSHIA, card_ref.KRONII,
	card_ref.MIKO, card_ref.OLLIE, card_ref.AKI, card_ref.WATAME, card_ref.BAELZ, card_ref.KAELA,
	card_ref.MEL, card_ref.TOWA, card_ref.LUNA, card_ref.CHLOE, card_ref.KOYORI, card_ref.SUBARU, card_ref.ALOE,
	card_ref.AZKI, card_ref.OKAYU, card_ref.CHOCO, card_ref.MOONA, card_ref.IOFIFTEEN, card_ref.MATSURI, card_ref.NENE,
	card_ref.ZETA, card_ref.REINE, card_ref.RISU, card_ref.LAPLUS, card_ref.SANA, card_ref.FUWAWA, card_ref.MOCOCO,
	card_ref.NERISSA, card_ref.SHIORI, card_ref.BIJOU
]

const DATABASE = {
#	card_ref.TEST : {
#		"name" : "Test",
#		"price" : 100,
#		effect_ref.LANDED_EX_REGEN : 0,
#		"quirks" : [effect_ref.FULL_DAMAGE],
#	},
	
	card_ref.GURA : {
		"name" : "Gura",
		"price" : 100,
		effect_ref.COMBO_LEVEL : 1,
		effect_ref.LIGHT_DMG_MOD : 50,
		"quirks" : [effect_ref.SUMMON_SHARK]
	},
	card_ref.INA : {
		"name" : "Ina'nis",
		"price" : 100,
		effect_ref.GRAVITY_MOD : -30,
		effect_ref.FRICTION : -50,
		effect_ref.PROJ_DMG_MOD : 30,
		effect_ref.PASSIVE_EX_REGEN : 10,
		"quirks" : [effect_ref.SUMMON_TAKO]
	},
	card_ref.SORA : {
		"name" : "Sora",
		"price" : 100,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.MAX_AIR_DASH : 1,
		effect_ref.JUMP_SPEED : 20,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
		"quirks" : [effect_ref.AUTO_TECH]
	},
	card_ref.MARINE : {
		"name" : "Marine",
		"price" : 100,
		effect_ref.COIN_GAIN : 2,
		effect_ref.HITSTUN_TAKEN : -30,
		effect_ref.HEAVY_DMG_MOD : 50,
		effect_ref.HITSTUN_EX_REGEN: 150,
	},
	card_ref.AQUA : {
		"name" : "Aqua",
		"price" : 100,
		effect_ref.GRD_DASH_SPEED : 40,
		effect_ref.AIR_DASH_SPEED : 40,
		effect_ref.SPECIAL_DMG_MOD: 50,
		"quirks" : [effect_ref.SPECIAL_CHAIN, effect_ref.CAN_TRIP],
	},
	card_ref.FLARE : {
		"name" : "Flare",
		"price" : 100,
		effect_ref.SPEED : 10,
		effect_ref.AIR_DASH_SPEED : 25,
		effect_ref.SPECIAL_DMG_MOD: 50,
		"quirks" : [effect_ref.IGNITION_ATK],
	},
	card_ref.NOEL : {
		"name" : "Noel",
		"price" : 100,
		effect_ref.SPEED : -10,
		effect_ref.HEAVY_DMG_MOD : 50,
		"quirks" : [effect_ref.PASSIVE_WEAKARMOR],
	},
	card_ref.ROBOCO : {
		"name" : "Roboco",
		"price" : 100,
		effect_ref.SPEED : -10,
		effect_ref.AIR_DASH_SPEED : 40,
		effect_ref.GRD_DASH_SPEED : 40,
		effect_ref.SPECIAL_DMG_MOD : 60,
		"quirks" : [effect_ref.LESS_GUARD_DRAIN],
	},
	card_ref.SHION : {
		"name" : "Shion",
		"price" : 100,
		effect_ref.PASSIVE_EX_REGEN : 15,
		effect_ref.LANDED_EX_REGEN : 50,
		effect_ref.PROJ_DMG_MOD : 50
	},
	card_ref.BOTAN : {
		"name" : "Botan",
		"price" : 100,
		effect_ref.PROJ_DMG_MOD : 50,
		"quirks" : [effect_ref.SUMMON_SSRB],
	},
	card_ref.LAMY : {
		"name" : "Lamy",
		"price" : 100,
		effect_ref.SPEED : -10,
		effect_ref.FRICTION : -50,
		effect_ref.PROJ_DMG_MOD : 40,
		effect_ref.SPECIAL_DMG_MOD : 40,
		"quirks" : [effect_ref.CHILLING_ATK]
	},
	card_ref.AYAME : {
		"name" : "Ayame",
		"price" : 100,
		effect_ref.FIERCE_DMG_MOD : 50,
		effect_ref.COMBO_LEVEL : 2,
		"quirks" : [effect_ref.NO_CROSSUP, effect_ref.REVENGE],
	},
	card_ref.IROHA : {
		"name" : "Iroha",
		"price" : 100,
		effect_ref.COMBO_LEVEL : 2,
		effect_ref.DODGE_SPEED : 50,
		effect_ref.MAX_AIR_DODGE : 2,
		"quirks" : [effect_ref.NO_DODGE_COST, effect_ref.DODGE_CANCEL]
	},
	card_ref.KORONE : {
		"name" : "Korone",
		"price" : 100,
		effect_ref.SPEED : 10,
		effect_ref.GRAVITY_MOD : 10,
		effect_ref.GRD_NORMAL_DMG_MOD : 60,
		effect_ref.GRD_DASH_SPEED : 40,
	},
	card_ref.MUMEI : {
		"name" : "Mumei",
		"price" : 100,
		effect_ref.MAX_AIR_DASH : 1,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
		"quirks" : [effect_ref.SUMMON_HORROR]
	},
	card_ref.KIARA : {
		"name" : "Kiara",
		"price" : 100,
		effect_ref.STOCK : 1,
		effect_ref.FIERCE_DMG_MOD : 50,
		"quirks" : [effect_ref.RESPAWN_POWER, effect_ref.PHOENIX_PROJ],
	},
	card_ref.MORI : {
		"name" : "Mori",
		"price" : 100,
		effect_ref.HEAVY_DMG_MOD : 40,
		"quirks" : [effect_ref.HEAL_ON_KILL, effect_ref.SCYTHE_PROJ]
	},
	card_ref.AMELIA : {
		"name" : "Amelia",
		"price" : 100,
		effect_ref.JUMP_SPEED : 30,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
		effect_ref.EXTRA_HITSTOP : 7,
		"quirks" : [effect_ref.REWIND],
	},
	card_ref.FAUNA : {
		"name" : "Fauna",
		"price" : 100,
		effect_ref.STOCK : 1,
		effect_ref.HP : 20,
		effect_ref.LANDED_EX_REGEN : 30,
		effect_ref.PASSIVE_EX_REGEN : 5,
		"quirks" : [effect_ref.POISON_ATK],
	},
	card_ref.IRYS : {
		"name" : "IRyS",
		"price" : 100,
		"replace" : "Random Out of 2 Sets",
		"random" : [card_ref.IRYS, card_ref.IRYS_b],
		effect_ref.STOCK : 1,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
		effect_ref.SDASH_SPEED : 30,
		"quirks" : [effect_ref.SDASH_IFRAME, effect_ref.AUTO_TECH],
	},
	card_ref.IRYS_b : {
		"name" : "IRyS",
		"price" : 100,
		effect_ref.SPECIAL_DMG_MOD : 60,
		effect_ref.PROJ_DMG_MOD: 60,
		effect_ref.GUARD_DRAIN_MOD: 60,
	},
	card_ref.KOBO : {
		"name" : "Kobo",
		"price" : 100,
		effect_ref.STOCK : 1,
		effect_ref.FRICTION : -50,
		effect_ref.LIGHT_DMG_MOD : 30,
		"quirks" : [effect_ref.BLOCK_CANCEL, effect_ref.RAIN_PROJ]
	},
	card_ref.FUBUKI : {
		"name" : "Fubuki",
		"price" : 100,
		effect_ref.SPEED : 10,
		effect_ref.LIGHT_DMG_MOD : 30,
		effect_ref.GRD_DASH_SPEED : 20,
		effect_ref.AIR_DASH_SPEED : 20,
		"quirks" : [effect_ref.CHILLING_ATK]
	},
	card_ref.MIO : {
		"name" : "Mio",
		"price" : 100,
		effect_ref.LIGHT_DMG_MOD : 30,
		effect_ref.FIERCE_DMG_MOD : 30,
		effect_ref.HEAVY_DMG_MOD : 30,
		"quirks" : [effect_ref.IGNITION_ATK],
	},
	card_ref.PEKORA : {
		"name" : "Pekora",
		"price" : 100,
		effect_ref.JUMP_SPEED : 50,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
		"quirks" : [effect_ref.SUMMON_NOUSAGI],
	},
	card_ref.POLKA : {
		"name" : "Polka",
		"price" : 100,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.MAX_AIR_DASH : 1,
		effect_ref.MAX_AIR_DODGE : 1,
		"quirks" : [effect_ref.DASH_IFRAME, effect_ref.DODGE_CANCEL]
	},
	card_ref.HAATO : {
		"name" : "Haato",
		"price" : 100,
		"random" : [card_ref.HAATO, card_ref.HAATO_b],
		"replace" : "Random Out of 2 Sets\nChanges Every Wave",
		effect_ref.HP : 50,
		effect_ref.HITSTUN_TAKEN : -50,
		"quirks" : [effect_ref.REDUCE_BURST_COST, effect_ref.PASSIVE_WEAKARMOR, effect_ref.WILDCARD]
	},
	card_ref.HAATO_b : {
		"name" : "Haachama",
		"price" : 100,
		"random" : [card_ref.HAATO, card_ref.HAATO_b],
		effect_ref.HP : -15, 
		effect_ref.COMBO_LEVEL : 5,
		"quirks" : [effect_ref.REVENGE, effect_ref.EX_RAISE_DMG, effect_ref.POISON_ATK, effect_ref.WILDCARD]
	},
	card_ref.SUISEI : {
		"name" : "Suisei",
		"price" : 100,
		effect_ref.AIR_DASH_SPEED : 20,
		effect_ref.SDASH_SPEED : 20,
		effect_ref.FIERCE_DMG_MOD : 50,
		"quirks" : [effect_ref.TBLOCK_PROJ]
	},
	card_ref.KANATA : {
		"name" : "Kanata",
		"price" : 100,
		effect_ref.GRAVITY_MOD: -30,
		effect_ref.JUMP_SPEED: -20,
		effect_ref.MAX_AIR_JUMP: 3,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
		"quirks" : [effect_ref.BLOCK_CANCEL]
	},
	card_ref.LUI : {
		"name" : "Lui",
		"price" : 100,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
		effect_ref.SDASH_SPEED : 40,
		effect_ref.MAX_SUPER_DASH : 1,
		"quirks" : [effect_ref.SDASH_IFRAME, effect_ref.NO_HEIGHT_LIMIT]
	},
	card_ref.ANYA : {
		"name" : "Anya",
		"price" : 100,
		effect_ref.LIGHT_DMG_MOD : 50,
		effect_ref.GUARD_DRAIN_MOD : 50,
		"quirks" : [effect_ref.KERIS_PROJ]
	},
	card_ref.COCO : {
		"name" : "Coco",
		"price" : 100,
		effect_ref.HP : 20,
		effect_ref.HEAVY_DMG_MOD : 50,
		effect_ref.SPECIAL_DMG_MOD : 50,
		"quirks" : [effect_ref.FULL_DAMAGE]
	},
	card_ref.RUSHIA : {
		"name" : "Rushia",
		"price" : 100,
		effect_ref.HP : -15,
		effect_ref.LIFESTEAL_RATE : 20,
		effect_ref.LIGHT_DMG_MOD : 70,
		"quirks" : [effect_ref.HEAL_ON_KILL],
	},
	card_ref.KRONII : {
		"name" : "Kronii",
		"price" : 100,
		effect_ref.LIGHT_DMG_MOD : 50,
		effect_ref.HEAVY_DMG_MOD : 50,
		effect_ref.EXTRA_HITSTOP : 7,
		"quirks" : [effect_ref.TIME_BUBBLE]
	},
	card_ref.MIKO : {
		"name" : "Miko",
		"price" : 100,
		effect_ref.HP : 25,
		effect_ref.LIGHT_DMG_MOD : 50,
		effect_ref.FIERCE_DMG_MOD : 50,
		effect_ref.HEAVY_DMG_MOD : 50,
	},
	card_ref.OLLIE : {
		"name" : "Ollie",
		"price" : 100,
		effect_ref.STOCK: 1,
		effect_ref.HITSTUN_TAKEN : -50,
		effect_ref.GRD_NORMAL_DMG_MOD : 25,
		"quirks" : [effect_ref.RESPAWN_POWER, effect_ref.POISON_ATK]
	},
	card_ref.AKI : {
		"name" : "Aki",
		"price" : 100,
		effect_ref.HP : 30,
		effect_ref.SPEED : 10,
		effect_ref.GRD_DASH_SPEED : 20,
		effect_ref.GRD_NORMAL_DMG_MOD : 50,
		"quirks" : [effect_ref.NO_BLOCK_COST]
	},
	card_ref.WATAME : {
		"name" : "Watame",
		"price" : 100,
		effect_ref.STOCK: 1,
		effect_ref.HP : 25,
		effect_ref.GRD_NORMAL_DMG_MOD : 25,
		"quirks": [effect_ref.NO_BLOCK_COST, effect_ref.LESS_GUARD_DRAIN],
	},
	card_ref.BAELZ : {
		"name" : "Baelz",
		"price" : 100,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		"replace" : "Random Out of 6 Sets\nChanges Every Wave",
		effect_ref.SPEED : -50,
		effect_ref.GRD_DASH_SPEED : 50,
		effect_ref.AIR_DASH_SPEED : 50,
		effect_ref.SDASH_SPEED : 50,
		"quirks" : [effect_ref.WILDCARD],
	},
	card_ref.BAELZ_b : {
		"name" : "Baelz",
		"price" : 100,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		effect_ref.HP : -69,
		effect_ref.LIFESTEAL_RATE : 100,
		"quirks" : [effect_ref.HEAL_ON_KILL, effect_ref.WILDCARD],
	},
	card_ref.BAELZ_c : {
		"name" : "Baelz",
		"price" : 100,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		effect_ref.LIGHT_DMG_MOD: -40,
		effect_ref.FIERCE_DMG_MOD: -40,
		effect_ref.HEAVY_DMG_MOD: -40,
		effect_ref.PASSIVE_EX_REGEN : 20,
		effect_ref.LANDED_EX_REGEN: 60,
		"quirks" : [effect_ref.WILDCARD],
	},
	card_ref.BAELZ_d : {
		"name" : "Baelz",
		"price" : 100,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		effect_ref.HITSTUN_TAKEN : 100,
		effect_ref.COMBO_LEVEL : 5,
		"quirks" : [effect_ref.CAN_REPEAT, effect_ref.REDUCE_BURST_COST, effect_ref.WILDCARD],
	},
	card_ref.BAELZ_e : {
		"name" : "Baelz",
		"price" : 100,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		effect_ref.JUMP_SPEED: -90,
		effect_ref.SPEED : 50,
		effect_ref.GRD_DASH_SPEED: 100,
		"quirks" : [effect_ref.DASH_IFRAME, effect_ref.WILDCARD],
	},
	card_ref.BAELZ_f : {
		"name" : "Baelz",
		"price" : 100,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		"quirks" : [effect_ref.POISON_ATK, effect_ref.CHILLING_ATK, effect_ref.IGNITION_ATK, \
				effect_ref.ENFEEBLING_ATK, effect_ref.WILDCARD]
	},
	card_ref.KAELA : {
		"name" : "Kaela",
		"price" : 100,
		effect_ref.HITSTUN_TAKEN : -50,
		effect_ref.FIERCE_DMG_MOD : 50,
		"quirks" : [effect_ref.BETTER_BLOCK, effect_ref.NO_CHIP_DMG],
	},
	card_ref.MEL: {
		"name" : "Mel",
		"price" : 100,
		effect_ref.LIFESTEAL_RATE : 30,
	},
	card_ref.TOWA : {
		"name" : "Towa",
		"price" : 100,
		effect_ref.SPEED : 10,
		effect_ref.COMBO_LEVEL : 1,
		effect_ref.PROJ_DMG_MOD : 50,
		"quirks" : [effect_ref.CAN_REPEAT]
	},
	card_ref.LUNA : {
		"name" : "Luna",
		"price" : 100,
		effect_ref.HP : 35,
		effect_ref.COIN_GAIN : 1,
		"quirks" : [effect_ref.EX_RAISE_DMG, effect_ref.BETTER_BLOCK]
	},
	card_ref.CHLOE : {
		"name" : "Chloe",
		"price" : 100,
		effect_ref.LIGHT_DMG_MOD : 50,
		effect_ref.GUARD_DRAIN_MOD : 30,
		"quirks" : [effect_ref.CAN_REPEAT, effect_ref.NO_DODGE_COST],
	},
	card_ref.KOYORI : {
		"name" : "Koyori",
		"price" : 100,
		effect_ref.LANDED_EX_REGEN : 30,
		effect_ref.PROJ_DMG_MOD : 50,
		"quirks" : [effect_ref.FLASK_PROJ]
	},
	card_ref.SUBARU : {
		"name" : "Subaru",
		"price" : 100,
		effect_ref.HP : 20,
		effect_ref.SPEED : 10,
		effect_ref.JUMP_SPEED : 20,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
	},
	card_ref.ALOE : {
		"name" : "Aloe",
		"price" : 100,
		effect_ref.GUARD_DRAIN_MOD : 50,
		effect_ref.SPECIAL_DMG_MOD : 50,
		"quirks": [effect_ref.ENFEEBLING_ATK]
	},
	card_ref.AZKI : {
		"name" : "AZKi",
		"price" : 100,
		effect_ref.HP : 20,
		effect_ref.SPECIAL_DMG_MOD : 30,
		effect_ref.LANDED_EX_REGEN : 20,
		"quirks" : [effect_ref.EX_RAISE_DMG]
	},
	card_ref.OKAYU : {
		"name" : "Okayu",
		"price" : 100,
		effect_ref.HP : 70,
		"quirks" : [effect_ref.POISON_ATK]
	},
	card_ref.CHOCO : {
		"name" : "Choco",
		"price" : 100,
		effect_ref.STOCK : 1,
		effect_ref.HP : 25,
		effect_ref.SPECIAL_DMG_MOD : 30,
		"quirks": [effect_ref.ENFEEBLING_ATK]
	},
	card_ref.MOONA : {
		"name" : "Moona",
		"price" : 100,
		effect_ref.GRAVITY_MOD : -30,
		effect_ref.HP : 20,
		effect_ref.HEAVY_DMG_MOD : 40,
		effect_ref.SPECIAL_DMG_MOD : 40,
		"quirks": [effect_ref.NO_BLOCK_COST]
	},
	card_ref.IOFIFTEEN : {
		"name" : "Iofifteen",
		"price" : 100,
		effect_ref.HP : 25,
		effect_ref.SPECIAL_DMG_MOD : 25,
		effect_ref.PASSIVE_EX_REGEN : 5,
		"quirks" : [effect_ref.EX_RAISE_DMG]
	},
	card_ref.MATSURI : {
		"name" : "Matsuri",
		"price" : 100,
		effect_ref.SPEED : 10,
		effect_ref.JUMP_SPEED : 20,
		effect_ref.FIERCE_DMG_MOD : 50,
		effect_ref.LIGHT_DMG_MOD : 50,
		"quirks" : [effect_ref.LESS_GUARD_DRAIN]
	},
	card_ref.NENE : {
		"name" : "Nene",
		"price" : 100,
		effect_ref.HP : 25,
		effect_ref.PASSIVE_EX_REGEN : 10,
		effect_ref.LANDED_EX_REGEN : 25,
		effect_ref.SPECIAL_DMG_MOD : 50,
		"quirks" : [effect_ref.REDUCE_BURST_COST],
	},
	card_ref.ZETA : {
		"name" : "Zeta",
		"price" : 100,
		effect_ref.LIGHT_DMG_MOD : 50,
		"quirks" : [effect_ref.DASH_IFRAME, effect_ref.AUTO_PARRY_PROJ, effect_ref.NO_CROSSUP],
	},
	card_ref.REINE : {
		"name" : "Reine",
		"price" : 100,
		effect_ref.SPECIAL_DMG_MOD : 50,
		"quirks" : [effect_ref.REDUCE_BURST_COST, effect_ref.PEACOCK_PROJ],
	},
	card_ref.RISU : {
		"name" : "Risu",
		"price" : 100,
		effect_ref.JUMP_SPEED : 15,
		effect_ref.SPEED : 15,
		effect_ref.LIGHT_DMG_MOD : 50,
		"quirks" : [effect_ref.DASH_IFRAME]
	},
	card_ref.LAPLUS : {
		"name" : "La+",
		"price" : 100,
		effect_ref.HP : -10,
		effect_ref.JUMP_SPEED : -10,
		effect_ref.SPECIAL_DMG_MOD: 60,
		effect_ref.PROJ_DMG_MOD: 60,
		effect_ref.LANDED_EX_REGEN: 50
	},
	card_ref.SANA : {
		"name" : "Sana",
		"price" : 100,
		effect_ref.SPEED : -10,
		effect_ref.GRAVITY_MOD : -30,
		effect_ref.HP : 50,
		effect_ref.HEAVY_DMG_MOD : 50,
		"quirks" : [effect_ref.VORTEX],
	},
	card_ref.FUWAWA : {
		"name" : "Fuwawa",
		"price" : 100,
		effect_ref.AIR_DASH_SPEED : 20,
		effect_ref.JUMP_SPEED : 20,
		effect_ref.GRAVITY_MOD : -15,
		"quirks" : [effect_ref.FUWA_SLASH],
	},
	card_ref.MOCOCO : {
		"name" : "Mococo",
		"price" : 100,
		effect_ref.GRD_DASH_SPEED : 20,
		effect_ref.SPEED : 10,
		effect_ref.GRAVITY_MOD : 15,
		"quirks" : [effect_ref.MOCO_SLASH],
	},
	card_ref.NERISSA : {
		"name" : "Nerissa",
		"price" : 100,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.MAX_AIR_DASH : 1,
		effect_ref.FIERCE_DMG_MOD : 50,
		"quirks" : [effect_ref.RAVEN_PROJ],
	},
	card_ref.SHIORI : {
		"name" : "Shiori",
		"price" : 100,
		effect_ref.SPECIAL_DMG_MOD: 60,
		effect_ref.PASSIVE_EX_REGEN : 15,
		effect_ref.LIFESTEAL_RATE : 15,
		"quirks" : [effect_ref.NO_CROSSUP],
	},
	card_ref.BIJOU : {
		"name" : "Bijou",
		"price" : 100,
		effect_ref.GRAVITY_MOD : 15,
		effect_ref.SPEED : -10,
		"quirks" : [effect_ref.NO_BLOCK_COST, effect_ref.NO_CHIP_DMG, effect_ref.SUMMON_MOAI],
	},
}
