extends Node2D


#func _ready():
#	init(Cards.card_ref.AQUA)


func init(card_ref: int, half_price = false):
	$Name.text = Cards.DATABASE[card_ref].name
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
