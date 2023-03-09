extends Node

enum type {PERCENT, LINEAR, QUIRK}

enum effect_ref {
		STOCK, HP, COMBO_LEVEL, LANDED_EX_REGEN, PASSIVE_EX_REGEN,
		SPEED, FRICTION, JUMP_SPEED, GRAVITY_MOD, MAX_AIR_JUMP, MAX_AIR_DASH, MAX_AIR_DODGE, MAX_SUPER_DASH, 
		GROUND_DASH_SPEED, AIR_DASH_SPEED, SDASH_SPEED, DODGE_SPEED,
		GUARD_DRAIN_MOD,
		GROUND_NORMAL_DMG_MOD, AIR_NORMAL_DMG_MOD, LIGHT_DMG_MOD, FIERCE_DMG_MOD,
		HEAVY_DMG_MOD, SPECIAL_DMG_MOD, PROJ_DMG_MOD, SUPER_DMG_MOD, 
		COIN_GAIN, LIFESTEAL_RATE, HITSTUN_TAKEN, EXTRA_HITSTOP,
		NO_GUARD_DRAIN, NO_CROSSUP, CAN_REPEAT, ARMOR_PIERCE, AUTO_PBLOCK_PROJ, FREE_RESET, HALF_BURST_COST, SPECIAL_CHAIN,
		CAN_TRIP, REVENGE, GROUND_DASH_IFRAME, AIR_DASH_IFRAME, SDASH_IFRAME, SUMMON_SHARK, HEAL_ON_KILL
		EX_RAISE_DMG, POISON_ATK, CHILLING_ATK, IGNITION_ATK, GRAVITIZING_ATK, ENFEEBLING_ATK, RESPAWN_POWER, WILDCARD
		NO_BLOCK_COST, NO_CHIP_DMG, NO_DODGE_COST, PROXIMITY_PARRY, BETTER_BLOCK
}
# NO_CROSSUP = can perfect block too
# ARMOR_PIERCE = full damage on armored mobs

const DESCRIBE = {
	effect_ref.STOCK : {
		"type" : type.LINEAR,
		"suffix" :"Stock Left",
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
	
	effect_ref.GROUND_DASH_SPEED : {
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
	
	effect_ref.GROUND_NORMAL_DMG_MOD : {
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
	
	effect_ref.NO_GUARD_DRAIN : {
		"type" : type.QUIRK,
		"suffix" :"No GG Loss When Atked",
	},
	effect_ref.NO_CROSSUP : {
		"type" : type.QUIRK,
		"suffix" :"Cross-Up Immunity",
	},
	effect_ref.CAN_REPEAT : {
		"type" : type.QUIRK,
		"suffix" :"No Repeat Penalty",
	},
	effect_ref.ARMOR_PIERCE : {
		"type" : type.QUIRK,
		"suffix" :"Full Dmg on Armored",
	},
	effect_ref.AUTO_PBLOCK_PROJ : {
		"type" : type.QUIRK,
		"suffix" :"Auto-PBlock Proj",
	},
	effect_ref.FREE_RESET : {
		"type" : type.QUIRK,
		"suffix" :"Free Resets",
	},
	effect_ref.HALF_BURST_COST : {
		"type" : type.QUIRK,
		"suffix" :"Halves Burst Cost",
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
	
	effect_ref.GROUND_DASH_IFRAME : {
		"type" : type.QUIRK,
		"suffix" :"Ground Dash has Iframes",
	},
	effect_ref.AIR_DASH_IFRAME : {
		"type" : type.QUIRK,
		"suffix" :"Air Dash has Iframes",
	},
	effect_ref.SDASH_IFRAME : {
		"type" : type.QUIRK,
		"suffix" :"Super Dash has Iframes",
	},
	effect_ref.SUMMON_SHARK : {
		"type" : type.QUIRK,
		"suffix" :"Summon Shark every 5 sec",	
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
	effect_ref.GRAVITIZING_ATK : {
		"type" : type.QUIRK,
		"suffix" :"Gravitizing Touch",	
	},
	effect_ref.ENFEEBLING_ATK : {
		"type" : type.QUIRK,
		"suffix" :"Enfeebling Touch",	
	},
	effect_ref.RESPAWN_POWER : {
		"type" : type.QUIRK,
		"suffix" :"Full Power on Respawn",	
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
	effect_ref.PROXIMITY_PARRY : {
		"type" : type.QUIRK,
		"suffix" :"PBlock at Close Range",
	},
	effect_ref.BETTER_BLOCK : {
		"type" : type.QUIRK,
		"suffix" :"Improved Blocking",
	},
}

const TRIP_CHANCE = 5
const SHARK_COOLDOWN = 300
const KILL_HEAL_PERCENT = 40
const POISON_DURATION = 180
const POISON_DMG = 40
const CHILL_DURATION = 120
const CHILL_SLOW = 50
const IGNITE_DURATION = 90
const IGNITE_DMG = 50
const GRAVITIZE_DURATION = 240
const GRAVITIZE_DEGREE = 300
const ENFEEBLE_DURATION = 180
const ENFEEBLE_DEGREE = 50

# CARDS ------------------------------------------------------------------------------------------------------------------------------------

enum card_ref {
	GURA, INA, SORA, MARINE, AQUA, FLARE, NOEL, ROBOCO, SHION, BOTAN, LAMY, AYAME, IROHA,
	KORONE, MUMEI, KIARA, MORI, AMELIA, FAUNA, IRYS, IRYS_b, KOBO, FUBUKI, MIO, PEKORA, POLKA, HAATO, HAATO_b,
	SUISEI, KANATA, LUI, ANYA, COCO, RUSHIA, KRONII, MIKO, OLLIE, AKI, WATAME, 
	BAELZ, BAELZ_b, BAELZ_c, BAELZ_d, BAELZ_e, BAELZ_f, KAELA,
	MEL, TOWA, LUNA, CHLOE, KOYORI, KOYORI_b, KOYORI_c, SUBARU, ALOE, AZKI, OKAYU, CHOCO, MOONA, IOFIFTEEN,
	MATSURI, NENE, ZETA, REINE, RISU, LAPLUS, SANA
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
	card_ref.ZETA, card_ref.REINE, card_ref.RISU, card_ref.LAPLUS, card_ref.SANA
]

const DATABASE = {
#	card_ref.TEST : {
#		"name" : "Test",
#		"price" : 120,
#		effect_ref.LANDED_EX_REGEN : 0,
#		"quirks" : [effect_ref.ARMOR_PIERCE],
#	},
	
	card_ref.GURA : {
		"name" : "Gura",
		"price" : 120,
		effect_ref.COMBO_LEVEL : 1,
		"quirks" : [effect_ref.SUMMON_SHARK]
	},
	card_ref.INA : {
		"name" : "Ina'nis",
		"price" : 120,
		effect_ref.GRAVITY_MOD : -60,
		effect_ref.FRICTION : -50,
		effect_ref.SPECIAL_DMG_MOD : 50,
		effect_ref.PROJ_DMG_MOD : 50,
		effect_ref.PASSIVE_EX_REGEN : 10,
	},
	card_ref.SORA : {
		"name" : "Sora",
		"price" : 120,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.MAX_AIR_DASH : 1,
		effect_ref.JUMP_SPEED : 20,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
	},
	card_ref.MARINE : {
		"name" : "Marine",
		"price" : 120,
		effect_ref.COIN_GAIN : 2,
		effect_ref.HITSTUN_TAKEN : -30,
		effect_ref.HEAVY_DMG_MOD : 50,
	},
	card_ref.AQUA : {
		"name" : "Aqua",
		"price" : 120,
		effect_ref.GROUND_DASH_SPEED : 40,
		effect_ref.AIR_DASH_SPEED : 40,
		effect_ref.SPECIAL_DMG_MOD: 50,
		"quirks" : [effect_ref.SPECIAL_CHAIN, effect_ref.CAN_TRIP],
	},
	card_ref.FLARE : {
		"name" : "Flare",
		"price" : 120,
		effect_ref.SPEED : 10,
		effect_ref.AIR_DASH_SPEED : 25,
		effect_ref.PROJ_DMG_MOD : 40,
		"quirks" : [effect_ref.SPECIAL_CHAIN]
	},
	card_ref.NOEL : {
		"name" : "Noel",
		"price" : 120,
		effect_ref.SPEED : -15,
		effect_ref.HP: 30,
		effect_ref.HEAVY_DMG_MOD : 50,
		"quirks" : [effect_ref.BETTER_BLOCK, effect_ref.PROXIMITY_PARRY],
	},
	card_ref.ROBOCO : {
		"name" : "Roboco",
		"price" : 120,
		effect_ref.SPEED : -10,
		effect_ref.AIR_DASH_SPEED : 40,
		effect_ref.GROUND_DASH_SPEED : 40,
		effect_ref.SPECIAL_DMG_MOD : 60,
		"quirks" : [effect_ref.NO_GUARD_DRAIN],
	},
	card_ref.SHION : {
		"name" : "Shion",
		"price" : 120,
		effect_ref.PASSIVE_EX_REGEN : 15,
		effect_ref.LANDED_EX_REGEN : 40,
		effect_ref.PROJ_DMG_MOD : 50
	},
	card_ref.BOTAN : {
		"name" : "Botan",
		"price" : 120,
		effect_ref.PROJ_DMG_MOD : 80,
		"quirks" : [effect_ref.ARMOR_PIERCE],
	},
	card_ref.LAMY : {
		"name" : "Lamy",
		"price" : 120,
		effect_ref.SPEED : -10,
		effect_ref.FRICTION : -50,
		effect_ref.PROJ_DMG_MOD : 40,
		effect_ref.SPECIAL_DMG_MOD : 40,
		"quirks" : [effect_ref.CHILLING_ATK]
	},
	card_ref.AYAME : {
		"name" : "Ayame",
		"price" : 120,
		effect_ref.FIERCE_DMG_MOD : 50,
		effect_ref.COMBO_LEVEL : 1,
		"quirks" : [effect_ref.NO_CROSSUP, effect_ref.REVENGE],
	},
	card_ref.IROHA : {
		"name" : "Iroha",
		"price" : 120,
		effect_ref.DODGE_SPEED : 30,
		effect_ref.MAX_AIR_DODGE : 1,
		"quirks" : [effect_ref.NO_DODGE_COST]
	},
	card_ref.KORONE : {
		"name" : "Korone",
		"price" : 120,
		effect_ref.JUMP_SPEED : -10,
		effect_ref.GROUND_NORMAL_DMG_MOD : 50,
		effect_ref.GROUND_DASH_SPEED : 30,
		"quirks" : [effect_ref.GROUND_DASH_IFRAME]
	},
	card_ref.MUMEI : {
		"name" : "Mumei",
		"price" : 120,
		effect_ref.SDASH_SPEED : 60,
		effect_ref.MAX_SUPER_DASH : 1,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
	},
	card_ref.KIARA : {
		"name" : "Kiara",
		"price" : 120,
		effect_ref.STOCK : 1,
		"quirks" : [effect_ref.AUTO_PBLOCK_PROJ, effect_ref.RESPAWN_POWER, effect_ref.IGNITION_ATK],
	},
	card_ref.MORI : {
		"name" : "Mori",
		"price" : 120,
		effect_ref.FIERCE_DMG_MOD : 30,
		effect_ref.HEAVY_DMG_MOD : 30,
		effect_ref.SPECIAL_DMG_MOD : 30,
		"quirks" : [effect_ref.HEAL_ON_KILL]
	},
	card_ref.AMELIA : {
		"name" : "Amelia",
		"price" : 120,
		effect_ref.JUMP_SPEED : 30,
		effect_ref.AIR_NORMAL_DMG_MOD : 30,
		effect_ref.EXTRA_HITSTOP : 5,
		"quirks" : [effect_ref.CAN_REPEAT],
	},
	card_ref.FAUNA : {
		"name" : "Fauna",
		"price" : 120,
		effect_ref.STOCK : 1,
		effect_ref.HP : 20,
		effect_ref.LANDED_EX_REGEN : 30,
		effect_ref.PASSIVE_EX_REGEN : 5,
		"quirks" : [effect_ref.POISON_ATK],
	},
	card_ref.IRYS : {
		"name" : "IRyS",
		"price" : 120,
		"replace" : "Random Out of 2 Sets",
		"random" : [card_ref.IRYS, card_ref.IRYS_b],
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
		effect_ref.SDASH_SPEED : 30,
		"quirks" : [effect_ref.SDASH_IFRAME],
	},
	card_ref.IRYS_b : {
		"name" : "IRyS",
		"price" : 120,
		effect_ref.SPECIAL_DMG_MOD : 60,
		effect_ref.PROJ_DMG_MOD: 60,
		effect_ref.GUARD_DRAIN_MOD: 60,
	},
	card_ref.KOBO : {
		"name" : "Kobo",
		"price" : 120,
		effect_ref.STOCK : 1,
		effect_ref.FRICTION : -50,
		effect_ref.SPECIAL_DMG_MOD : 50,
		"quirks" : [effect_ref.CAN_REPEAT],
	},
	card_ref.FUBUKI : {
		"name" : "Fubuki",
		"price" : 120,
		effect_ref.SPEED : 10,
		effect_ref.GROUND_DASH_SPEED : 20,
		effect_ref.AIR_DASH_SPEED : 20,
		"quirks" : [effect_ref.CHILLING_ATK]
	},
	card_ref.MIO : {
		"name" : "Mio",
		"price" : 120,
		effect_ref.LIGHT_DMG_MOD : 30,
		effect_ref.FIERCE_DMG_MOD : 30,
		effect_ref.HEAVY_DMG_MOD : 30,
		"quirks" : [effect_ref.IGNITION_ATK],
	},
	card_ref.PEKORA : {
		"name" : "Pekora",
		"price" : 120,
		effect_ref.JUMP_SPEED : 50,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
	},
	card_ref.POLKA : {
		"name" : "Polka",
		"price" : 120,
		effect_ref.SPEED : 10,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.MAX_AIR_DASH : 1,
		effect_ref.MAX_AIR_DODGE : 1,
		"quirks" : [effect_ref.AIR_DASH_IFRAME]
	},
	card_ref.HAATO : {
		"name" : "Haato",
		"price" : 120,
		"random" : [card_ref.HAATO, card_ref.HAATO_b],
		"replace" : "Random Out of 2 Sets\nChanges Every Wave",
		effect_ref.HP : 50,
		effect_ref.HITSTUN_TAKEN : -70,
		"quirks" : [effect_ref.HALF_BURST_COST, effect_ref.NO_BLOCK_COST, effect_ref.WILDCARD]
	},
	card_ref.HAATO_b : {
		"name" : "Haachama",
		"price" : 120,
		"random" : [card_ref.HAATO, card_ref.HAATO_b],
		effect_ref.HP : -15, 
		effect_ref.COMBO_LEVEL : 3,
		"quirks" : [effect_ref.REVENGE, effect_ref.POISON_ATK, effect_ref.WILDCARD]
	},
	card_ref.SUISEI : {
		"name" : "Suisei",
		"price" : 120,
		effect_ref.AIR_DASH_SPEED : 30,
		effect_ref.SDASH_SPEED : 30,
		effect_ref.COMBO_LEVEL : 2,
		effect_ref.FIERCE_DMG_MOD : 50,
	},
	card_ref.KANATA : {
		"name" : "Kanata",
		"price" : 120,
		effect_ref.GRAVITY_MOD: -40,
		effect_ref.JUMP_SPEED: -20,
		effect_ref.MAX_AIR_JUMP: 3,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
	},
	card_ref.LUI : {
		"name" : "Lui",
		"price" : 120,
		effect_ref.MAX_AIR_DASH : 2,
		effect_ref.AIR_DASH_SPEED : 30,
		effect_ref.SDASH_SPEED : 30,
		effect_ref.AIR_NORMAL_DMG_MOD : 50,
	},
	card_ref.ANYA : {
		"name" : "Anya",
		"price" : 120,
		effect_ref.SPEED : 10,
		effect_ref.LIGHT_DMG_MOD : 50,
		effect_ref.GUARD_DRAIN_MOD : 50,
		"quirks" : [effect_ref.ARMOR_PIERCE]
	},
	card_ref.COCO : {
		"name" : "Coco",
		"price" : 120,
		effect_ref.HEAVY_DMG_MOD : 50,
		effect_ref.SPECIAL_DMG_MOD : 50,
		"quirks" : [effect_ref.IGNITION_ATK, effect_ref.NO_CHIP_DMG],
	},
	card_ref.RUSHIA : {
		"name" : "Rushia",
		"price" : 120,
		effect_ref.HP : -15,
		effect_ref.LIFESTEAL_RATE : 20,
		effect_ref.LIGHT_DMG_MOD : 70,
		"quirks" : [effect_ref.HEAL_ON_KILL],
	},
	card_ref.KRONII : {
		"name" : "Kronii",
		"price" : 120,
		effect_ref.LIGHT_DMG_MOD : 50,
		effect_ref.HEAVY_DMG_MOD : 50,
		effect_ref.EXTRA_HITSTOP : 10,
	},
	card_ref.MIKO : {
		"name" : "Miko",
		"price" : 120,
		effect_ref.HP : 25,
		effect_ref.JUMP_SPEED : 20,
		effect_ref.LIGHT_DMG_MOD : 40,
		effect_ref.FIERCE_DMG_MOD : 40,
	},
	card_ref.OLLIE : {
		"name" : "Ollie",
		"price" : 120,
		effect_ref.STOCK: 1,
		effect_ref.HITSTUN_TAKEN : -50,
		"quirks" : [effect_ref.RESPAWN_POWER, effect_ref.POISON_ATK]
	},
	card_ref.AKI : {
		"name" : "Aki",
		"price" : 120,
		effect_ref.HP : 30,
		effect_ref.HITSTUN_TAKEN : -50,
		effect_ref.GROUND_NORMAL_DMG_MOD : 50,
		"quirks" : [effect_ref.BETTER_BLOCK, effect_ref.NO_CHIP_DMG]
	},
	card_ref.WATAME : {
		"name" : "Watame",
		"price" : 120,
		effect_ref.STOCK: 1,
		effect_ref.HP : 25,
		"quirks": [effect_ref.BETTER_BLOCK, effect_ref.NO_BLOCK_COST, effect_ref.NO_GUARD_DRAIN],
	},
	card_ref.BAELZ : {
		"name" : "Baelz",
		"price" : 120,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		"replace" : "Random Out of 6 Sets\nChanges Every Wave",
		effect_ref.SPEED : -50,
		effect_ref.GROUND_DASH_SPEED : 50,
		effect_ref.AIR_DASH_SPEED : 50,
		effect_ref.SDASH_SPEED : 50,
		"quirks" : [effect_ref.WILDCARD],
	},
	card_ref.BAELZ_b : {
		"name" : "Baelz",
		"price" : 120,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		effect_ref.HP : -69,
		effect_ref.LIFESTEAL_RATE : 100,
		"quirks" : [effect_ref.HEAL_ON_KILL, effect_ref.WILDCARD],
	},
	card_ref.BAELZ_c : {
		"name" : "Baelz",
		"price" : 120,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		"quirks" : [effect_ref.GROUND_DASH_IFRAME, effect_ref.AIR_DASH_IFRAME, effect_ref.SDASH_IFRAME, effect_ref.WILDCARD],
	},
	card_ref.BAELZ_d : {
		"name" : "Baelz",
		"price" : 120,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		effect_ref.HITSTUN_TAKEN : 100,
		effect_ref.COMBO_LEVEL : 3,
		"quirks" : [effect_ref.WILDCARD],
	},
	card_ref.BAELZ_e : {
		"name" : "Baelz",
		"price" : 120,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		effect_ref.JUMP_SPEED: -90,
		effect_ref.SPEED : 50,
		effect_ref.GROUND_DASH_SPEED: 100,
		"quirks" : [effect_ref.WILDCARD],
	},
	card_ref.BAELZ_f : {
		"name" : "Baelz",
		"price" : 120,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
		"quirks" : [effect_ref.POISON_ATK, effect_ref.CHILLING_ATK, effect_ref.IGNITION_ATK, effect_ref.GRAVITIZING_ATK, \
				effect_ref.ENFEEBLING_ATK, effect_ref.WILDCARD]
	},
	card_ref.KAELA : {
		"name" : "Kaela",
		"price" : 120,
		effect_ref.HITSTUN_TAKEN : -50,
		effect_ref.FIERCE_DMG_MOD : 50,
		"quirks": [effect_ref.PROXIMITY_PARRY, effect_ref.NO_CHIP_DMG]
	},
	card_ref.MEL: {
		"name" : "Mel",
		"price" : 120,
		effect_ref.LIFESTEAL_RATE : 30,
	},
	card_ref.TOWA : {
		"name" : "Towa",
		"price" : 120,
		effect_ref.SPEED : 10,
		effect_ref.COMBO_LEVEL : 2,
		effect_ref.PROJ_DMG_MOD : 50,
		"quirks" : [effect_ref.FREE_RESET],
	},
	card_ref.LUNA : {
		"name" : "Luna",
		"price" : 120,
		effect_ref.HP : 25,
		effect_ref.COIN_GAIN : 1,
		"quirks" : [effect_ref.EX_RAISE_DMG]
	},
	card_ref.CHLOE : {
		"name" : "Chloe",
		"price" : 120,
		effect_ref.LIGHT_DMG_MOD : 30,
		effect_ref.GUARD_DRAIN_MOD : 30,
		"quirks" : [effect_ref.FREE_RESET, effect_ref.NO_DODGE_COST],
	},
	card_ref.KOYORI : {
		"name" : "Koyori",
		"price" : 120,
		"random" : [card_ref.KOYORI, card_ref.KOYORI_b, card_ref.KOYORI_c],
		"replace" : "Random Out of 3 Sets",
		effect_ref.HP: -15,
		effect_ref.LIFESTEAL_RATE: 50,
		"quirks" : [effect_ref.POISON_ATK]
	},
	card_ref.KOYORI_b : {
		"name" : "Koyori",
		"price" : 120,
		effect_ref.DODGE_SPEED: 50,
		"quirks" : [effect_ref.NO_BLOCK_COST, effect_ref.NO_CROSSUP, effect_ref.CHILLING_ATK]
	},
	card_ref.KOYORI_c : {
		"name" : "Koyori",
		"price" : 120,
		effect_ref.SPEED: -15,
		effect_ref.FIERCE_DMG_MOD: 60,
		effect_ref.HEAVY_DMG_MOD : 60,
		effect_ref.SPECIAL_DMG_MOD : 60,
		"quirks" : [effect_ref.IGNITION_ATK]
	},
	card_ref.SUBARU : {
		"name" : "Subaru",
		"price" : 120,
		effect_ref.SPEED : 10,
		effect_ref.JUMP_SPEED : 20,
		effect_ref.MAX_AIR_JUMP : 1,
		effect_ref.AIR_NORMAL_DMG_MOD : 50
	},
	card_ref.ALOE : {
		"name" : "Aloe",
		"price" : 120,
		effect_ref.GUARD_DRAIN_MOD : 50,
		effect_ref.SPECIAL_DMG_MOD : 50,
		"quirks": [effect_ref.ENFEEBLING_ATK]
	},
	card_ref.AZKI : {
		"name" : "AZKi",
		"price" : 120,
		effect_ref.HP : 20,
		effect_ref.SPECIAL_DMG_MOD : 20,
		effect_ref.LANDED_EX_REGEN : 20,
		"quirks" : [effect_ref.EX_RAISE_DMG]
	},
	card_ref.OKAYU : {
		"name" : "Okayu",
		"price" : 120,
		effect_ref.HP : 70,
		"quirks" : [effect_ref.POISON_ATK]
	},
	card_ref.CHOCO : {
		"name" : "Choco",
		"price" : 120,
		effect_ref.STOCK : 1,
		effect_ref.HP : 25,
		effect_ref.SPECIAL_DMG_MOD : 30,
		"quirks": [effect_ref.ENFEEBLING_ATK]
	},
	card_ref.MOONA : {
		"name" : "Moona",
		"price" : 120,
		effect_ref.GRAVITY_MOD : -40,
		effect_ref.HP : 20,
		effect_ref.HEAVY_DMG_MOD : 30,
		effect_ref.SPECIAL_DMG_MOD : 30,
		"quirks": [effect_ref.NO_BLOCK_COST]
	},
	card_ref.IOFIFTEEN : {
		"name" : "Iofifteen",
		"price" : 120,
		effect_ref.HP : 25,
		effect_ref.SPECIAL_DMG_MOD : 20,
		effect_ref.PASSIVE_EX_REGEN : 5,
		"quirks" : [effect_ref.EX_RAISE_DMG]
	},
	card_ref.MATSURI : {
		"name" : "Matsuri",
		"price" : 120,
		effect_ref.SPEED : 10,
		effect_ref.JUMP_SPEED : 20,
		effect_ref.FIERCE_DMG_MOD : 50,
		effect_ref.LIGHT_DMG_MOD : 50,
		"quirks" : [effect_ref.NO_GUARD_DRAIN]
	},
	card_ref.NENE : {
		"name" : "Nene",
		"price" : 120,
		effect_ref.HP : 25,
		effect_ref.PASSIVE_EX_REGEN : 10,
		effect_ref.LANDED_EX_REGEN : 25,
		effect_ref.SPECIAL_DMG_MOD : 25,
		"quirks" : [effect_ref.HALF_BURST_COST],
	},
	card_ref.ZETA : {
		"name" : "Zeta",
		"price" : 120,
		effect_ref.SPEED : 10,
		effect_ref.LIGHT_DMG_MOD : 35,
		effect_ref.FIERCE_DMG_MOD : 35,
		"quirks" : [effect_ref.AIR_DASH_IFRAME, effect_ref.NO_CROSSUP],
	},
	card_ref.REINE : {
		"name" : "Reine",
		"price" : 120,
		effect_ref.PASSIVE_EX_REGEN : 5,
		effect_ref.SPECIAL_DMG_MOD : 50,
		"quirks" : [effect_ref.AUTO_PBLOCK_PROJ, effect_ref.HALF_BURST_COST],
	},
	card_ref.RISU : {
		"name" : "Risu",
		"price" : 120,
		effect_ref.JUMP_SPEED : 15,
		effect_ref.SPEED : 15,
		effect_ref.LIGHT_DMG_MOD : 50,
		"quirks" : [effect_ref.GROUND_DASH_IFRAME]
	},
	card_ref.LAPLUS : {
		"name" : "La+",
		"price" : 120,
		effect_ref.HP : -10,
		effect_ref.JUMP_SPEED : -10,
		effect_ref.SPECIAL_DMG_MOD: 60,
		effect_ref.PROJ_DMG_MOD: 60,
		effect_ref.LANDED_EX_REGEN: 50
	},
	card_ref.SANA : {
		"name" : "Sana",
		"price" : 120,
		effect_ref.SPEED : -10,
		effect_ref.GRAVITY_MOD : -60,
		effect_ref.HP : 50,
		effect_ref.HEAVY_DMG_MOD : 70,
		"quirks" : [effect_ref.GRAVITIZING_ATK],
	},

}
