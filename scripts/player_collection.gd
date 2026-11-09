extends Node
## Collection de cartes du joueur (autoload « PlayerCollection »).
## Les cartes sont des CardData, le même format que la scène de combat :
## l'inventaire les affiche et le combat s'en sert comme deck.
## Au lancement du jeu, le joueur possède uniquement les trois cartes de départ.
## Les autres scènes (gacha…) peuvent l'enrichir avec add_card().

signal collection_changed

var _cards: Array[CardData] = []


func _ready() -> void:
	reset_to_starter()


## Les trois cartes données au joueur au début de la partie (1 compétence chacune).
static func create_starter_cards() -> Array[CardData]:
	var chevalier := CardData.create("Chevalier", 3, 20, Color("2980b9")).with_style(CardData.AttackStyle.SWORD).with_skill(
			SkillSupport.create_support("Cri de guerre", 3, SkillSupport.SupportType.BUFF,
					SkillSupport.Stat.ATTACK, 2, 2, true))

	var mage := CardData.create("Mage", 4, 14, Color("8e44ad")).with_style(CardData.AttackStyle.MAGIC).with_skill(
			SkillAttack.create_attack("Pluie de flammes", 3, 1.0, 1, true))

	var voleur := CardData.create("Voleur", 3, 16, Color("d35400")).with_style(CardData.AttackStyle.DAGGER).with_skill(
			SkillAttack.create_attack("Double dague", 2, 1.0, 2))

	return [chevalier, mage, voleur]


## Remet la collection à son état de départ (les trois cartes initiales).
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
