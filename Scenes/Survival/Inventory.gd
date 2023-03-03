extends Node


		

var inventory = [
	[ # P1

	],
	
	[ # P2
		
	]
]

func _ready():
#	print(get_card_name(Cards.card_ref.INA))
#	print(get_describe(Cards.card_ref.INA))
	pass


func get_card_name(card: int) -> String:
	return Cards.DATABASE[card].name


func get_describe(card: int) -> String:
	var full_string := ""
	
	for key in Cards.DATABASE[card]:
		if key is String and key == "price":
			continue
		elif key is String and key == "quirks":
			for quirk in Cards.DATABASE[card][key]:
				if full_string != "":
					full_string += "\n"
				full_string += get_describe_stat(quirk)
		elif key is int:
			if full_string != "":
				full_string += "\n"
			full_string += get_describe_stat(key, Cards.DATABASE[card][key])
			
	return full_string
			

func get_describe_stat(stat, number = null):
	match Cards.DESCRIBE[stat].type:
		Cards.type.PERCENT:
			var text = Cards.DESCRIBE[stat].suffix
			if number >= 0:
				text += " +" + str(number) + "%"
			else:
				text += " " + str(number) + "%"
			return text
		Cards.type.LINEAR:
			var text = Cards.DESCRIBE[stat].suffix
			if number >= 0:
				text += " +" + str(number)
			else:
				text += " " + str(number)
			return text
		Cards.type.QUIRK:
			return Cards.DESCRIBE[stat].suffix

func modifier(player_ID: int, stat: int, from_zero: bool = false):
	match Cards.DESCRIBE[stat].type:
		Cards.type.PERCENT:
			return percent_modifier(player_ID, stat, from_zero)
		Cards.type.LINEAR:
			return linear_modifier(player_ID, stat)
		

func has_quirk(player_ID: int, quirk: int) -> bool:
	if Globals.survival_level == null:
		print("Error: Attempted to access inventory outside Survival Mode.")
		return false
	
	for card in inventory[player_ID]:
		if "quirks" in Cards.DATABASE[card]:
			if quirk in Cards.DATABASE[card].quirks:
				return true
		
	return false
	
func has_stat_mod(player_ID: int, stat: int) -> bool:
	if Globals.survival_level == null:
		print("Error: Attempted to access inventory outside Survival Mode.")
		return false
	
	for card in inventory[player_ID]:
		if stat in Cards.DATABASE[card]:
			return true
		
	return false


func percent_modifier(player_ID: int, stat: int, from_zero: bool = false) -> int:
	if Globals.survival_level == null:
		print("Error: Attempted to access inventory outside Survival Mode.")
		return 100
	
	var modifier := 100
	if from_zero:
		modifier = 0
	
	for card in inventory[player_ID]:
		if stat in Cards.DATABASE[card]:
			modifier += Cards.DATABASE[card][stat]
	
	modifier = int(max(modifier, 0))
	return modifier
	
	
func linear_modifier(player_ID: int, stat: int) -> int:
	if Globals.survival_level == null:
		print("Error: Attempted to access inventory outside Survival Mode.")
		return 0
	
	var modifier := 0
	
	for card in inventory[player_ID]:
		if stat in Cards.DATABASE[card]:
			modifier += Cards.DATABASE[card][stat]
	
	return modifier
	
	


