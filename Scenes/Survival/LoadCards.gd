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
}

var card_sfx = {
	"SmallSplash" : {
		"frame_data" : ResourceLoader.load("res://Characters/Gura/SFX/FrameData/SmallSplash.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/SmallSplashSprite.png"),
	},
	"BigSplash" : {
		"frame_data" : ResourceLoader.load("res://Characters/Gura/SFX/FrameData/BigSplash.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/BigSplashSprite.png"),
	}
}

var card_audio = {
	"water1": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water1.wav"),
	"water6": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water6.wav"),
	"water11": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water11.wav"),
	"water15": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water15.wav"),
}
