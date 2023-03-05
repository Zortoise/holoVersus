extends Node2D


#func _ready():
#	init(Cards.card_ref.AQUA)


func init(card_ref: int, hide_price = false):
	$Name.text = Cards.DATABASE[card_ref].name
	if !hide_price:
		$Price/Cost.text = str(Cards.DATABASE[card_ref].price)
		$Price.show()
	else:
		$Price.hide()
		
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
