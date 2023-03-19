extends Node

#enum effect_ref {SHARK}

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
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/Tako.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/TakoSprite.png"),
	},
	"TakoGateE" : {
		"scene" : load("res://Cards/TakoGateE.tscn"),
		"frame_data" : ResourceLoader.load("res://Cards/FrameData/TakoGate.tres"),
		"spritesheet" : ResourceLoader.load("res://Cards/Spritesheets/TakoGateSprite.png"),
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
}

var card_audio = {
	"water1": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water1.wav"),
	"water6": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water6.wav"),
	"water11": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water11.wav"),
	"water15": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water15.wav"),
}
