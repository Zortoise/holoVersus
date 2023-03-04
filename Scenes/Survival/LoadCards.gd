extends Node

enum effect_ref {SHARK}

var entity_data = {
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
}

var loaded_sfx = {
	"SmallSplash" : {
		"frame_data" : ResourceLoader.load("res://Characters/Gura/SFX/FrameData/SmallSplash.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/SmallSplashSprite.png"),
	},
	"BigSplash" : {
		"frame_data" : ResourceLoader.load("res://Characters/Gura/SFX/FrameData/BigSplash.tres"),
		"spritesheet" : ResourceLoader.load("res://Characters/Gura/SFX/Spritesheets/BigSplashSprite.png"),
	}
}

var unique_audio = {
	"water1": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water1.wav"),
	"water6": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water6.wav"),
	"water11": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water11.wav"),
	"water15": ResourceLoader.load("res://Characters/Gura/UniqueAudio/water15.wav"),
}
