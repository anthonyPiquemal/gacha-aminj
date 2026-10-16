class_name CardData
extends Resource
## Données d'une carte (nom, attaque, points de vie, couleur).

@export var card_name: String = ""
@export var attack: int = 1
@export var health: int = 1
@export var color: Color = Color.WHITE


static func create(p_name: String, p_attack: int, p_health: int, p_color: Color) -> CardData:
	var card := CardData.new()
	card.card_name = p_name
	card.attack = p_attack
	card.health = p_health
	card.color = p_color
	return card
