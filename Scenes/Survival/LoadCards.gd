extends Node

#enum effect_ref {SHARK}


var card_art = {
	Cards.card_ref.GURA : ResourceLoader.load("res://Cards/CardArt/Gura.png"),
	Cards.card_ref.INA : ResourceLoader.load("res://Cards/CardArt/Ina.png"),
	Cards.card_ref.SORA : ResourceLoader.load("res://Cards/CardArt/Sora.png"),
	Cards.card_ref.MARINE : ResourceLoader.load("res://Cards/CardArt/Marine.png"),
	Cards.card_ref.AQUA : ResourceLoader.load("res://Cards/CardArt/Aqua.png"),
	Cards.card_ref.FLARE : ResourceLoader.load("res://Cards/CardArt/Flare.png"),
	Cards.card_ref.NOEL : ResourceLoader.load("res://Cards/CardArt/Noel.png"),
	
	Cards.card_ref.ROBOCO : ResourceLoader.load("res://Cards/CardArt/Roboco.png"),
	Cards.card_ref.SHION : ResourceLoader.load("res://Cards/CardArt/Shion.png"),
	Cards.card_ref.BOTAN : ResourceLoader.load("res://Cards/CardArt/Botan.png"),
	Cards.card_ref.LAMY : ResourceLoader.load("res://Cards/CardArt/Lamy.png"),
	Cards.card_ref.AYAME : ResourceLoader.load("res://Cards/CardArt/Ayame.png"),
	Cards.card_ref.IROHA : ResourceLoader.load("res://Cards/CardArt/Iroha.png"),
	
	Cards.card_ref.KORONE : ResourceLoader.load("res://Cards/CardArt/Korone.png"),
	Cards.card_ref.MUMEI : ResourceLoader.load("res://Cards/CardArt/Mumei.png"),
	Cards.card_ref.KIARA : ResourceLoader.load("res://Cards/CardArt/Kiara.png"),
	Cards.card_ref.MORI : ResourceLoader.load("res://Cards/CardArt/Mori.png"),
	Cards.card_ref.AMELIA : ResourceLoader.load("res://Cards/CardArt/Amelia.png"),
	Cards.card_ref.FAUNA : ResourceLoader.load("res://Cards/CardArt/Fauna.png"),
	
	Cards.card_ref.IRYS : ResourceLoader.load("res://Cards/CardArt/IRyS.png"),
	Cards.card_ref.KOBO : ResourceLoader.load("res://Cards/CardArt/Kobo.png"),
	Cards.card_ref.FUBUKI : ResourceLoader.load("res://Cards/CardArt/Fubuki.png"),
	Cards.card_ref.MIO : ResourceLoader.load("res://Cards/CardArt/Mio.png"),
	Cards.card_ref.PEKORA : ResourceLoader.load("res://Cards/CardArt/Pekora.png"),
	Cards.card_ref.POLKA : ResourceLoader.load("res://Cards/CardArt/Polka.png"),
	Cards.card_ref.HAATO : ResourceLoader.load("res://Cards/CardArt/Haato.png"),
	Cards.card_ref.HAATO_b : ResourceLoader.load("res://Cards/CardArt/Haachama.png"),
	Cards.card_ref.SUISEI : ResourceLoader.load("res://Cards/CardArt/Suisei.png"),
	Cards.card_ref.KANATA : ResourceLoader.load("res://Cards/CardArt/Kanata.png"),
	Cards.card_ref.LUI : ResourceLoader.load("res://Cards/CardArt/Lui.png"),
	Cards.card_ref.ANYA : ResourceLoader.load("res://Cards/CardArt/Anya.png"),
	Cards.card_ref.COCO : ResourceLoader.load("res://Cards/CardArt/Coco.png"),
	Cards.card_ref.RUSHIA : ResourceLoader.load("res://Cards/CardArt/Rushia.png"),
	Cards.card_ref.KRONII : ResourceLoader.load("res://Cards/CardArt/Kronii.png"),
	
	Cards.card_ref.MIKO : ResourceLoader.load("res://Cards/CardArt/Miko.png"),
	Cards.card_ref.OLLIE : ResourceLoader.load("res://Cards/CardArt/Ollie.png"),
	Cards.card_ref.AKI : ResourceLoader.load("res://Cards/CardArt/Aki.png"),
	Cards.card_ref.WATAME : ResourceLoader.load("res://Cards/CardArt/Watame.png"),
	Cards.card_ref.BAELZ : ResourceLoader.load("res://Cards/CardArt/Baelz.png"),
	Cards.card_ref.KAELA : ResourceLoader.load("res://Cards/CardArt/Kaela.png"),
	
	Cards.card_ref.MEL : ResourceLoader.load("res://Cards/CardArt/Mel.png"),
	Cards.card_ref.TOWA : ResourceLoader.load("res://Cards/CardArt/Towa.png"),
	Cards.card_ref.LUNA : ResourceLoader.load("res://Cards/CardArt/Luna.png"),
	Cards.card_ref.CHLOE : ResourceLoader.load("res://Cards/CardArt/Chloe.png"),
	Cards.card_ref.KOYORI : ResourceLoader.load("res://Cards/CardArt/Koyori.png"),
	Cards.card_ref.SUBARU : ResourceLoader.load("res://Cards/CardArt/Subaru.png"),
	Cards.card_ref.ALOE : ResourceLoader.load("res://Cards/CardArt/Aloe.png"),
	
	Cards.card_ref.AZKI : ResourceLoader.load("res://Cards/CardArt/AZKi.png"),
	Cards.card_ref.OKAYU : ResourceLoader.load("res://Cards/CardArt/Okayu.png"),
	Cards.card_ref.CHOCO : ResourceLoader.load("res://Cards/CardArt/Choco.png"),
	Cards.card_ref.MOONA : ResourceLoader.load("res://Cards/CardArt/Moona.png"),
	Cards.card_ref.IOFIFTEEN : ResourceLoader.load("res://Cards/CardArt/Iofifteen.png"),
	Cards.card_ref.MATSURI : ResourceLoader.load("res://Cards/CardArt/Matsuri.png"),
	Cards.card_ref.NENE : ResourceLoader.load("res://Cards/CardArt/Nene.png"),
	
	Cards.card_ref.ZETA : ResourceLoader.load("res://Cards/CardArt/Zeta.png"),
	Cards.card_ref.REINE : ResourceLoader.load("res://Cards/CardArt/Reine.png"),
	Cards.card_ref.RISU : ResourceLoader.load("res://Cards/CardArt/Risu.png"),
	Cards.card_ref.LAPLUS : ResourceLoader.load("res://Cards/CardArt/Laplus.png"),
	Cards.card_ref.SANA : ResourceLoader.load("res://Cards/CardArt/Sana.png"),
}

var card_entity_data = {
	"NibblerSpawnE" : {
		"scene" : load("res://Cards/NibblerSpawnE.tscn"),
		"frame_data" : ResourceLoader.load("res://Characters/Gura/Entities/FrameData/NibblerSpawn.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/NibblerSpawnSprite.png"),
	},
	"NibblerE" : {
		"scene" : load("res://Cards/NibblerE.tscn"),
		"frame_data" : ResourceLoader.load("res://Characters/Gura/Entities/FrameData/Nibbler.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Gura/Entities/Spritesheets/NibblerSprite.png"),
	},
	"HorrorE" : {
		"scene" : load("res://Cards/HorrorE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/Horror.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/HorrorSprite.png"),
	},
	"PhoenixFeatherE" : {
		"scene" : load("res://Cards/PhoenixFeatherE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/PhoenixFeather.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/PhoenixFeatherSprite.png"),
	},
	"PeacockFeatherE" : {
		"scene" : load("res://Cards/PeacockFeatherE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/PeacockFeather.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/PeacockFeatherSprite.png"),
	},
	"WaterBulletE" : {
		"scene" : load("res://Cards/WaterBulletE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/WaterBullet.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/WaterBulletSprite.png"),
	},
	"KerisE" : {
		"scene" : load("res://Cards/KerisE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/Keris.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/KerisSprite.png"),
	},
	"ScytheE" : {
		"scene" : load("res://Cards/ScytheE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/Scythe.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/ScytheSprite.png"),
	},
	"TimeBubbleE" : {
		"scene" : load("res://Cards/TimeBubbleE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/TimeBubble.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/TimeBubbleSprite.png"),
	},
	"VortexE" : {
		"scene" : load("res://Cards/VortexE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/Vortex.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/VortexSprite.png"),
	},
	"TakoE" : {
		"scene" : load("res://Cards/TakoE.tscn"),
		"frame_data" : ResourceLoader.load("res://Characters/Ina/Entities/FrameData/Tako.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Ina/Entities/Spritesheets/TakoSprite.png"),
	},
	"TakoGateE" : {
		"scene" : load("res://Cards/TakoGateE.tscn"),
		"frame_data" : ResourceLoader.load("res://Characters/Ina/Entities/FrameData/TakoGate.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Ina/Entities/Spritesheets/TakoGateSprite.png"),
	},
	"TBlockE" : {
		"scene" : load("res://Cards/TBlockE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/TBlock.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/TBlockSprite.png"),
	},
	"FlaskE" : {
		"scene" : load("res://Cards/FlaskE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/Flask.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/FlaskSprite.png"),
	},
	"SsrbE" : {
		"scene" : load("res://Cards/SsrbE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/SSRB.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/SSRBSprite.png"),
	},
	"SsrbTimerE" : {
		"scene" : load("res://Cards/SsrbTimerE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/SSRBTimer.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/SSRBTimerSprite.png"),
	},
	"NousagiE" : {
		"scene" : load("res://Cards/NousagiE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/Nousagi.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/NousagiSprite.png"),
	},
}

var card_sfx = {
	"SmallSplash" : {
		"frame_data" : ResourceLoader.load("res://Characters/Gura/SFX/FrameData/SmallSplash.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/SmallSplashSprite.png"),
	},
	"BigSplash" : {
		"frame_data" : ResourceLoader.load("res://Characters/Gura/SFX/FrameData/BigSplash.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/BigSplashSprite.png"),
	},
	"TakoFlash" : {
		"frame_data" : ResourceLoader.load("res://Characters/Ina/SFX/FrameData/TakoFlash.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Ina/SFX/Spritesheets/TakoFlashSprite.png"),
	},
}

var card_audio = {
	"water1": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water1.wav"),
	"water6": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water6.wav"),
	"water11": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water11.wav"),
	"water15": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water15.wav"),
}
