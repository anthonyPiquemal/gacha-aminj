extends Node
## Collection de cartes du joueur (autoload « PlayerCollection »).
## Les cartes sont des CardData, le même format que la scène de combat :
## l'inventaire les affiche et le combat s'en sert comme deck.
## Au lancement du jeu, le joueur possède les cartes de départ (CardLibrary).
## Les autres scènes (gacha…) peuvent l'enrichir avec add_card().

signal collection_changed

var _cards: Array[CardData] = []


func _ready() -> void:
	reset_to_starter()


## Les cartes données au joueur au début de la partie : les 5 cartes AMINJ.
static func create_starter_cards() -> Array[CardData]:
	return CardLibrary.aminj_cards()


## Remet la collection à son état de départ.
func reset_to_starter() -> void:
	_cards = create_starter_cards()
	collection_changed.emit()


func add_card(card: CardData) -> void:
	if card == null:
		return
	_cards.append(card)
	collection_changed.emit()


func remove_card(card: CardData) -> void:
	_cards.erase(card)
	collection_changed.emit()


## Copie de la liste des cartes possédées, dans l'ordre d'obtention.
func get_cards() -> Array[CardData]:
	return _cards.duplicate()


func count() -> int:
	return _cards.size()


## Ajoute une liste de cartes à la collection (utilisé par le booster).
func add_cards(cards: Array[CardData]) -> void:
	for card in cards:
		if card != null:
			_cards.append(card)
	collection_changed.emit()
