extends Node2D


#func _ready():
#	init(Cards.card_ref.AQUA)


func init(card_ref: int, half_price = false):
	$Name.text = Cards.DATABASE[card_ref].name
	var card_ref2 := card_ref
	match card_ref2:
		Cards.card_ref.IRYS_b:
			card_ref2 = Cards.card_ref.IRYS
		Cards.card_ref.BAELZ_b, Cards.card_ref.BAELZ_c, Cards.card_ref.BAELZ_d, Cards.card_ref.BAELZ_e, Cards.card_ref.BAELZ_f:
			card_ref2 = Cards.card_ref.BAELZ
	$Sprite.texture = Globals.Game.LevelControl.card_art[card_ref2]
	
	if !half_price:
		$Price/Cost.text = str(Inventory.get_price(card_ref))
	else:
		$Price/Cost.text = str(FMath.percent(Inventory.get_price(card_ref), 50))
		
func blank():
	$Sprite.hide()
	$Name.hide()
	$Type.hide()
	$Price.hide()
	modulate = Color(0.5, 0.5, 0.5)

func buy():
	$AnimationPlayer.play("buy")
	$Sprite.hide()
	$Name.hide()
	$Type.hide()
	$Price.hide()
