extends Node

var shop_open := false

var pool = []

var shop = []
var bought_index = [] # array of indexes

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

func stock_pool():
	inventory = [[],[]]
	pool = []
	for card in Cards.LIST:
		pool.append(card)
		
func open_shop(): # draw 5 random cards from pool
	shop = []
	bought_index = []
	wildcards()
	
	for x in 5:
		if pool.size() > 0:
			var select = pool[Globals.Game.rng_generate(pool.size())]
			shop.append(select)
			pool.erase(select)
		else: # empty card
			bought_index.append(x)
			
			
func wildcards():
	for slot in inventory[0].size():
		if "quirks" in Cards.DATABASE[inventory[0][slot]] and Cards.effect_ref.WILDCARD in Cards.DATABASE[inventory[0][slot]].quirks:
			var random_array = Cards.DATABASE[inventory[0][slot]].random
			random_array.erase(inventory[0][slot])
			inventory[0][slot] = Globals.Game.rng_array(random_array)
			
	for slot in inventory[1].size():
		if "quirks" in Cards.DATABASE[inventory[1][slot]] and Cards.effect_ref.WILDCARD in Cards.DATABASE[inventory[1][slot]].quirks:
			var random_array = Cards.DATABASE[inventory[1][slot]].random
			random_array.erase(inventory[1][slot])
			inventory[1][slot] = Globals.Game.rng_array(random_array)
		
		
func close_shop(): # return unbought cards to pool
	for shop_card_index in shop.size():
		if !shop_card_index in bought_index:
			pool.append(shop[shop_card_index])


func can_player_afford(player_ID: int, shop_index: int) -> bool:
	if Globals.Game.get_player_node(player_ID).coin_count >= get_price(shop[shop_index]):
		return true
	else: return false
	
func can_player_afford_ref(player_ID: int, in_card_ref: int) -> bool:
	if Globals.Game.get_player_node(player_ID).coin_count >= get_price(in_card_ref):
		return true
	else: return false
	
func pay_coin(player_ID: int, shop_index: int):
	var player = Globals.Game.get_player_node(player_ID)
	player.coin_count -= get_price(shop[shop_index])
	Globals.Game.coin_update(player)


func sell_card(player_ID: int, index: int):
	var player = Globals.Game.get_player_node(player_ID)
	player.coin_count += FMath.percent(get_price(inventory[player_ID][index]), 50)
	Globals.Game.coin_update(player)
	
	inventory[0].remove(index)


func get_price(card_ref) -> int:
	var mod: int = 100 + (Globals.Game.LevelControl.wave_ID - 2) * Globals.Game.LevelControl.UniqLevel.PRICE_SCALING
	return FMath.percent(Cards.DATABASE[card_ref].price, mod)
	

func get_describe(card: int, shop_describe := true) -> String:
	var full_string := ""
	
	for key in Cards.DATABASE[card]:
		if key is String and key == "price":
			continue
		elif shop_describe and key is String and key == "replace":
			return Cards.DATABASE[card].replace
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
	
	


