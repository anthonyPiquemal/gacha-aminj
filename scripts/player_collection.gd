extends Node
## Collection de cartes du joueur (autoload « PlayerCollection »).
## Au lancement du jeu, le joueur possède uniquement les trois cartes de départ.
## Les autres scènes (gacha, combat…) peuvent l'enrichir avec add_card().

signal collection_changed

const STARTER_CARDS: Array[CharacterCardData] = [
	preload("res://resources/cards/ecuyer.tres"),
	preload("res://resources/cards/herboriste.tres"),
	preload("res://resources/cards/barde.tres"),
]

var _cards: Array[CharacterCardData] = []


func _ready() -> void:
	reset_to_starter()


## Remet la collection à son état de départ (les trois cartes initiales).
func reset_to_starter() -> void:
	_cards.clear()
	for card in STARTER_CARDS:
		_cards.append(card)
	collection_changed.emit()


func add_card(card: CharacterCardData) -> void:
	if card == null:
		return
	_cards.append(card)
	collection_changed.emit()


func remove_card(card: CharacterCardData) -> void:
	_cards.erase(card)
	collection_changed.emit()


## Copie de la liste des cartes possédées, dans l'ordre d'obtention.
func get_cards() -> Array[CharacterCardData]:
	return _cards.duplicate()


func count() -> int:
	return _cards.size()
