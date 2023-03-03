extends Node

enum type {PERCENT, LINEAR, QUIRK}

enum stat_ref {
		STOCK, HP, BREAK_LEVEL, LANDED_EX_REGEN, PASSIVE_EX_REGEN,
		SPEED, JUMP_SPEED, GRAVITY_MOD, MAX_AIR_JUMP, MAX_AIR_DASH, MAX_AIR_DODGE, MAX_SUPER_DASH, 
		GROUND_DASH_SPEED, AIR_DASH_SPEED, SDASH_SPEED, DODGE_GG_COST, DODGE_SPEED, GG_REGEN_AMOUNT, 
		BLOCK_GG_COST, WEAKBLOCK_CHIP_DMG_MOD,
		GROUND_LIGHT_DMG_MOD, GROUND_FIERCE_DMG_MOD, AIR_LIGHT_DMG_MOD, AIR_FIERCE_DMG_MOD, GROUND_HEAVY_DMG_MOD, AIR_HEAVY_DMG_MOD,
		SPECIAL_DMG_MOD, PROJ_DMG_MOD, SUPER_DMG_MOD, 
		COIN_GAIN, LIFESTEAL_RATE, HITSTUN_REDUCE
		
		NO_GUARD_DRAIN, NO_CROSSUP, CAN_REPEAT, ARMOR_PIERCE, AUTO_PBLOCK_PROJ, FREE_RESET, HALF_BURST_COST, SPECIAL_CHAIN,
		CAN_TRIP
}
# NO_CROSSUP = can perfect block too
# ARMOR_PIERCE = full damage on armored mobs

const DESCRIBE = {
	stat_ref.STOCK : {
		"type" : type.LINEAR,
		"suffix" :"Stock Left",
	},
	
	stat_ref.HP : {
		"type" : type.PERCENT,
		"suffix" :"Max HP",
	},
	stat_ref.BREAK_LEVEL : {
		"type" : type.LINEAR,
		"suffix" :"Break Lvl",
	},
	
	stat_ref.LANDED_EX_REGEN : {
		"type" : type.PERCENT,
		"suffix" :"EX Gain on Hit",
	},
	stat_ref.PASSIVE_EX_REGEN : {
		"type" : type.LINEAR,
		"suffix" :"Passive EX Gain",
	},
	
	stat_ref.SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Movespeed",
	},
	stat_ref.JUMP_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Jump Power",
	},
	stat_ref.GRAVITY_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Gravity",
	},
	
	stat_ref.MAX_AIR_JUMP : {
		"type" : type.LINEAR,
		"suffix" :"AirJump Count",
	},
	stat_ref.MAX_AIR_DASH : {
		"type" : type.LINEAR,
		"suffix" :"AirDash Count",
	},
	stat_ref.MAX_AIR_DODGE : {
		"type" : type.LINEAR,
		"suffix" :"AirDodge Count",
	},
	stat_ref.MAX_SUPER_DASH : {
		"type" : type.LINEAR,
		"suffix" :"AirSDash Count",
	},
	
	stat_ref.GROUND_DASH_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"GrdDash Speed",
	},
	stat_ref.AIR_DASH_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"AirDash Speed",
	},
	stat_ref.SDASH_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"SDash Speed",
	},
	stat_ref.DODGE_GG_COST : {
		"type" : type.PERCENT,
		"suffix" :"Dodge GG Cost",
	},
	stat_ref.DODGE_SPEED : {
		"type" : type.PERCENT,
		"suffix" :"Dodge Speed",
	},
	
	stat_ref.GG_REGEN_AMOUNT : {
		"type" : type.PERCENT,
		"suffix" :"GG Regen",
	},
	stat_ref.BLOCK_GG_COST : {
		"type" : type.PERCENT,
		"suffix" :"Block GG Cost",
	},
	stat_ref.WEAKBLOCK_CHIP_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"ChipDmg Taken",
	},
	
	stat_ref.GROUND_LIGHT_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"GrdLight Dmg",
	},
	stat_ref.GROUND_FIERCE_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"GrdFierce Dmg",
	},
	stat_ref.AIR_LIGHT_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"AirLight Dmg",
	},
	stat_ref.AIR_FIERCE_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"AirFierce Dmg",
	},
	stat_ref.GROUND_HEAVY_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"GrdHeavy Dmg",
	},
	stat_ref.AIR_HEAVY_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"AirHeavy Dmg",
	},
	stat_ref.SPECIAL_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"PhySpecial Dmg",
	},
	stat_ref.PROJ_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Proj Dmg",
	},
	stat_ref.SUPER_DMG_MOD : {
		"type" : type.PERCENT,
		"suffix" :"Super Dmg",
	},
	
	stat_ref.COIN_GAIN : {
		"type" : type.PERCENT,
		"suffix" :"Coin Gain",
	},
	stat_ref.LIFESTEAL_RATE : {
		"type" : type.PERCENT,
		"suffix" :"Lifesteal",
	},
	stat_ref.HITSTUN_REDUCE : {
		"type" : type.PERCENT,
		"suffix" :"Hitstun Reduce",
	},
	
	stat_ref.NO_GUARD_DRAIN : {
		"type" : type.QUIRK,
		"suffix" :"No Guard Drain",
	},
	stat_ref.NO_CROSSUP : {
		"type" : type.QUIRK,
		"suffix" :"Cross-Up Immune",
	},
	stat_ref.CAN_REPEAT : {
		"type" : type.QUIRK,
		"suffix" :"Attacks Can Repeat",
	},
	stat_ref.ARMOR_PIERCE : {
		"type" : type.QUIRK,
		"suffix" :"Full Dmg on Armored",
	},
	stat_ref.AUTO_PBLOCK_PROJ : {
		"type" : type.QUIRK,
		"suffix" :"Auto-PBlock Proj",
	},
	stat_ref.FREE_RESET : {
		"type" : type.QUIRK,
		"suffix" :"Free Resets",
	},
	stat_ref.HALF_BURST_COST : {
		"type" : type.QUIRK,
		"suffix" :"Halves Burst Cost",
	},
	stat_ref.SPECIAL_CHAIN : {
		"type" : type.QUIRK,
		"suffix" :"Special Chaining",
	},
	stat_ref.CAN_TRIP : {
		"type" : type.QUIRK,
		"suffix" :"Randomly Trips",
	},
}


# CARDS ------------------------------------------------------------------------------------------------------------------------------------

enum card_ref {
	TEST, GURA, INA, SORA, MARINE, AQUA, FLARE, NOEL, ROBOCO, SHION, BOTAN, LAMY, AYAME, IROHA,
	KORONE, MUMEI, KIARA, MORI, AMELIA, FAUNA, IRYS, KOBO, FUBUKI, MIO, PEKORA, POLKA, HAATO, HAATO_b,
	SUISEI, KANATA, LUI, ANYA, COCO, RUSHIA, KRONII, MIKO, OLLIE, AKI, WATAME, 
	BAELZ, BAELZ_b, BAELZ_c, BAELZ_d, BAELZ_e, BAELZ_f, KAELA,
	MEL, TOWA, LUNA, CHLOE, KOYORI, KOYORI_b, KOYORI_c, SUBARU, ALOE, AZKI, OKAYU, CHOCO, MOONA, IOFIFTEEN,
	MATSURI, NENE, ZETA, REINE, RISU, LAPLUS, SANA
}

const DATABASE = {
	card_ref.TEST : {
		"name" : "Test",
		"price" : 100,
		stat_ref.LANDED_EX_REGEN : 0,
		"quirks" : [stat_ref.ARMOR_PIERCE],
	},
	
	card_ref.GURA : {
		"name" : "Gura",
		"price" : 100,
		stat_ref.SPEED : 10,
		stat_ref.BREAK_LEVEL : 2,
	},
	card_ref.INA : {
		"name" : "Ina'nis",
		"price" : 100,
		stat_ref.GRAVITY_MOD : -60,
		stat_ref.PROJ_DMG_MOD : 25,
		"quirks" : [stat_ref.CAN_REPEAT, stat_ref.SPECIAL_CHAIN],
	},
	card_ref.SORA : {
		"name" : "Sora",
		"price" : 100,
		stat_ref.MAX_AIR_JUMP : 1,
		stat_ref.MAX_AIR_DASH : 1,
		stat_ref.JUMP_SPEED : 20,
		stat_ref.AIR_DASH_SPEED : 30,
		stat_ref.SDASH_SPEED : 30,
	},
	card_ref.MARINE : {
		"name" : "Marine",
		"price" : 100,
		stat_ref.COIN_GAIN : 30,
		stat_ref.HITSTUN_REDUCE : 30,
	},
	card_ref.AQUA : {
		"name" : "Aqua",
		"price" : 100,
		stat_ref.GROUND_DASH_SPEED : 40,
		stat_ref.AIR_DASH_SPEED : 40,
		stat_ref.SPECIAL_DMG_MOD: 50,
		"quirks" : [stat_ref.CAN_TRIP],
	},
	card_ref.FLARE : {
		"name" : "Flare",
		"price" : 100,
		stat_ref.SPEED : 10,
		stat_ref.JUMP_SPEED : 20,
		stat_ref.AIR_DASH_SPEED : 25,
		stat_ref.PROJ_DMG_MOD : 25
	},
	card_ref.NOEL : {
		"name" : "Noel",
		"price" : 100,
		stat_ref.SPEED : -10,
		stat_ref.HP : 25,
		stat_ref.GG_REGEN_AMOUNT : 50,
		stat_ref.WEAKBLOCK_CHIP_DMG_MOD : -50,
		stat_ref.GROUND_HEAVY_DMG_MOD : 30,
		"quirks" : [stat_ref.NO_GUARD_DRAIN],
	},
	card_ref.ROBOCO : {
		"name" : "Roboco",
		"price" : 100,
		stat_ref.SPEED : -10,
		stat_ref.JUMP_SPEED : 20,
		stat_ref.AIR_DASH_SPEED : 30,
		stat_ref.GROUND_DASH_SPEED : 30,
		stat_ref.SDASH_SPEED : 30,
		stat_ref.SPECIAL_DMG_MOD : 30,
	},
	card_ref.SHION : {
		"name" : "Shion",
		"price" : 100,
		stat_ref.PASSIVE_EX_REGEN : 10,
		stat_ref.LANDED_EX_REGEN : 20,
		stat_ref.PROJ_DMG_MOD : 30
	},
	card_ref.BOTAN : {
		"name" : "Botan",
		"price" : 100,
		stat_ref.PROJ_DMG_MOD : 50,
		"quirks" : [stat_ref.ARMOR_PIERCE],
	},
	card_ref.LAMY : {
		"name" : "Lamy",
		"price" : 100,
		stat_ref.SPEED : -10,
		stat_ref.PROJ_DMG_MOD : 40,
		stat_ref.SPECIAL_DMG_MOD : 40,
		stat_ref.HP : 20,
		stat_ref.PASSIVE_EX_REGEN : 10,
	},
	card_ref.AYAME : {
		"name" : "Ayame",
		"price" : 100,
		stat_ref.SPECIAL_DMG_MOD : 30,
		"quirks" : [stat_ref.NO_CROSSUP, stat_ref.SPECIAL_CHAIN],
	},
	card_ref.IROHA : {
		"name" : "Iroha",
		"price" : 100,
		stat_ref.SPEED : 10,
		stat_ref.JUMP_SPEED : 20,
		stat_ref.DODGE_GG_COST : -50,
		stat_ref.DODGE_SPEED : 50,
		stat_ref.MAX_AIR_DODGE : 1
	},
	card_ref.KORONE : {
		"name" : "Korone",
		"price" : 100,
		stat_ref.SPEED : 10,
		stat_ref.GROUND_DASH_SPEED : 50,
		stat_ref.JUMP_SPEED : -10,
		stat_ref.GROUND_LIGHT_DMG_MOD : 50,
	},
	card_ref.MUMEI : {
		"name" : "Mumei",
		"price" : 100,
		stat_ref.JUMP_SPEED : 20,
		stat_ref.SDASH_SPEED : 60,
		stat_ref.MAX_SUPER_DASH : 1,
	},
	card_ref.KIARA : {
		"name" : "Kiara",
		"price" : 100,
		stat_ref.STOCK : 1,
		stat_ref.GROUND_FIERCE_DMG_MOD : 20,
		stat_ref.AIR_FIERCE_DMG_MOD : 20,
		stat_ref.BLOCK_GG_COST : -30,
		"quirks" : [stat_ref.AUTO_PBLOCK_PROJ],
	},
	card_ref.MORI : {
		"name" : "Mori",
		"price" : 100,
		stat_ref.STOCK : -1,
		stat_ref.GROUND_FIERCE_DMG_MOD : 50,
		stat_ref.AIR_FIERCE_DMG_MOD : 50,
		stat_ref.GROUND_HEAVY_DMG_MOD : 50,
		stat_ref.AIR_HEAVY_DMG_MOD : 50,
		stat_ref.SPECIAL_DMG_MOD : 50,
	},
	card_ref.AMELIA : {
		"name" : "Amelia",
		"price" : 100,
		stat_ref.JUMP_SPEED : 30,
		stat_ref.AIR_FIERCE_DMG_MOD : 50,
		stat_ref.AIR_HEAVY_DMG_MOD : 50,
		"quirks" : [stat_ref.FREE_RESET, stat_ref.CAN_REPEAT],
	},
	card_ref.FAUNA : {
		"name" : "Fauna",
		"price" : 100,
		stat_ref.HP : 25
	},
	card_ref.IRYS : {
		"name" : "IRyS",
		"price" : 100,
	},
	card_ref.KOBO : {
		"name" : "Kobo",
		"price" : 100,
	},
	card_ref.FUBUKI : {
		"name" : "Fubuki",
		"price" : 100,
		stat_ref.JUMP_SPEED : 30,
	},
	card_ref.MIO : {
		"name" : "Mio",
		"price" : 100,
	},
	card_ref.PEKORA : {
		"name" : "Pekora",
		"price" : 100,
		stat_ref.JUMP_SPEED : 50,
		stat_ref.MAX_AIR_JUMP : 1,
		stat_ref.AIR_LIGHT_DMG_MOD : 50
	},
	card_ref.POLKA : {
		"name" : "Polka",
		"price" : 100,
		stat_ref.JUMP_SPEED : 30,
	},
	card_ref.HAATO : {
		"name" : "Haato",
		"price" : 100,
		"random" : [card_ref.HAATO, card_ref.HAATO_b],
		stat_ref.HP : 25
	},
	card_ref.HAATO_b : {
		"name" : "Haachama",
		stat_ref.HP : 25
	},
	card_ref.SUISEI : {
		"name" : "Suisei",
		"price" : 100,
		stat_ref.AIR_DASH_SPEED : 30,
		stat_ref.BREAK_LEVEL : 1,
		stat_ref.GROUND_FIERCE_DMG_MOD : 25,
		stat_ref.AIR_FIERCE_DMG_MOD : 25,
	},
	card_ref.KANATA : {
		"name" : "Kanata",
		"price" : 100,
		stat_ref.GRAVITY_MOD: -40,
		stat_ref.MAX_AIR_JUMP: 2,
		stat_ref.JUMP_SPEED: -20,
		stat_ref.AIR_FIERCE_DMG_MOD : 25,
		stat_ref.AIR_HEAVY_DMG_MOD : 25,
	},
	card_ref.LUI : {
		"name" : "Lui",
		"price" : 100,
		stat_ref.JUMP_SPEED : 30,
		stat_ref.MAX_AIR_DASH : 2,
		stat_ref.AIR_DASH_SPEED : 30,
		stat_ref.SDASH_SPEED : 30,
	},
	card_ref.ANYA : {
		"name" : "Anya",
		"price" : 100,
	},
	card_ref.COCO : {
		"name" : "Coco",
		"price" : 100,
		stat_ref.SDASH_SPEED : 30,
	},
	card_ref.RUSHIA : {
		"name" : "Rushia",
		"price" : 100,
		stat_ref.HP : -20
	},
	card_ref.KRONII : {
		"name" : "Kronii",
		"price" : 100,
		stat_ref.SDASH_SPEED : 30,
		"quirks" : [stat_ref.CAN_REPEAT],
	},
	card_ref.MIKO : {
		"name" : "Miko",
		"price" : 100,
		stat_ref.HP : 25,
		stat_ref.JUMP_SPEED : 20,
		stat_ref.GROUND_LIGHT_DMG_MOD : 20,
		stat_ref.GROUND_FIERCE_DMG_MOD : 20,
		stat_ref.AIR_LIGHT_DMG_MOD : 20,
		stat_ref.AIR_FIERCE_DMG_MOD : 20,
	},
	card_ref.OLLIE : {
		"name" : "Ollie",
		"price" : 100,
		stat_ref.STOCK: 1,
		stat_ref.HITSTUN_REDUCE : 50,
	},
	card_ref.AKI : {
		"name" : "Aki",
		"price" : 100,
		stat_ref.HP : 25
	},
	card_ref.WATAME : {
		"name" : "Watame",
		"price" : 100,
		stat_ref.HP : 25
	},
	card_ref.BAELZ : {
		"name" : "Baelz",
		"price" : 100,
		"random" : [card_ref.BAELZ, card_ref.BAELZ_b, card_ref.BAELZ_c, card_ref.BAELZ_d, card_ref.BAELZ_e, card_ref.BAELZ_f],
	},
	card_ref.BAELZ_b : {
		"name" : "Baelz",
	},
	card_ref.BAELZ_c : {
		"name" : "Baelz",
	},
	card_ref.BAELZ_d : {
		"name" : "Baelz",
	},
	card_ref.BAELZ_e : {
		"name" : "Baelz",
	},
	card_ref.BAELZ_f : {
		"name" : "Baelz",
	},
	card_ref.KAELA : {
		"name" : "Kaela",
		"price" : 100,
		stat_ref.GG_REGEN_AMOUNT : 50,
		stat_ref.WEAKBLOCK_CHIP_DMG_MOD : -50,
		stat_ref.BLOCK_GG_COST : -30,
		"quirks" : [stat_ref.NO_GUARD_DRAIN],
	},
	card_ref.MEL: {
		"name" : "Mel",
		"price" : 100,
		stat_ref.LIFESTEAL_RATE : 20,
	},
	card_ref.TOWA : {
		"name" : "Towa",
		"price" : 100,
		stat_ref.SPEED : 10,
		stat_ref.BREAK_LEVEL : 1,
		stat_ref.PROJ_DMG_MOD : 25,
	},
	card_ref.LUNA : {
		"name" : "Luna",
		"price" : 100,
		stat_ref.HP : 25,
		stat_ref.COIN_GAIN : 20,
	},
	card_ref.CHLOE : {
		"name" : "Chloe",
		"price" : 100,
		stat_ref.SPEED : 10,
		stat_ref.JUMP_SPEED : 20,
		"quirks" : [stat_ref.FREE_RESET],
	},
	card_ref.KOYORI : {
		"name" : "Koyori",
		"price" : 100,
		"random" : [card_ref.KOYORI, card_ref.KOYORI_b, card_ref.KOYORI_c]
	},
	card_ref.KOYORI_b : {
		"name" : "Koyori",
	},
	card_ref.KOYORI_c : {
		"name" : "Koyori",
	},
	card_ref.SUBARU : {
		"name" : "Subaru",
		"price" : 100,
		stat_ref.JUMP_SPEED : 20,
		stat_ref.SPEED : 10,
	},
	card_ref.ALOE : {
		"name" : "Aloe",
		"price" : 100,
	},
	card_ref.AZKI : {
		"name" : "AZKi",
		"price" : 100,
	},
	card_ref.OKAYU : {
		"name" : "Okayu",
		"price" : 100,
		stat_ref.HP : 60,
	},
	card_ref.CHOCO : {
		"name" : "Choco",
		"price" : 100,
		stat_ref.STOCK : 1,
		stat_ref.HP : 25,
	},
	card_ref.MOONA : {
		"name" : "Moona",
		"price" : 100,
	},
	card_ref.IOFIFTEEN : {
		"name" : "Iofifteen",
		"price" : 100,
	},
	card_ref.MATSURI : {
		"name" : "Matsuri",
		"price" : 100,
		stat_ref.HP : 25
	},
	card_ref.NENE : {
		"name" : "Nene",
		"price" : 100,
		stat_ref.HP : 25,
		stat_ref.JUMP_SPEED : 20,
		"quirks" : [stat_ref.HALF_BURST_COST],
	},
	card_ref.ZETA : {
		"name" : "Zeta",
		"price" : 100,
		"quirks" : [stat_ref.FREE_RESET],
	},
	card_ref.REINE : {
		"name" : "Reine",
		"price" : 100,
		stat_ref.JUMP_SPEED : 20,
		"quirks" : [stat_ref.AUTO_PBLOCK_PROJ],
	},
	card_ref.RISU : {
		"name" : "Risu",
		"price" : 100,
		stat_ref.JUMP_SPEED : 20,
		stat_ref.SPEED : 20,
		stat_ref.GROUND_LIGHT_DMG_MOD : 50,
		stat_ref.AIR_LIGHT_DMG_MOD : 50,
	},
	card_ref.LAPLUS : {
		"name" : "La+",
		"price" : 100,
		stat_ref.HP : -10,
		stat_ref.JUMP_SPEED : -10,
		stat_ref.SPECIAL_DMG_MOD: 60,
		stat_ref.PROJ_DMG_MOD: 60,
		stat_ref.LANDED_EX_REGEN: 20
	},
	card_ref.SANA : {
		"name" : "Sana",
		"price" : 100,
		stat_ref.SPEED : -10,
		stat_ref.HP : 50,
		stat_ref.GRAVITY_MOD : -60,
		stat_ref.GROUND_HEAVY_DMG_MOD : 50,
		stat_ref.AIR_HEAVY_DMG_MOD : 50,
	},

}
