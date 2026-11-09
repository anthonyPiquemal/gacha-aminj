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


## Les trois cartes données au joueur au début de la partie.
static func create_starter_cards() -> Array[CardData]:
	var chevalier := CardData.create("Chevalier", 3, 4, Color("2980b9"))
	chevalier.addSkill(SkillAttack.create_attack("Coup d'épée", 1, 3))
	chevalier.addSkill(SkillSupport.create_support(
			"Cri de guerre", 3, SkillSupport.SupportType.BUFF, SkillSupport.Stat.ATTACK, 1, 2, true))

	var mage := CardData.create("Mage", 4, 2, Color("8e44ad"))
	mage.addSkill(SkillAttack.create_attack("Boule de feu", 1, 4))
	mage.addSkill(SkillAttack.create_attack("Pluie de flammes", 3, 2, 1, true))

	var voleur := CardData.create("Voleur", 2, 3, Color("d35400"))
	voleur.addSkill(SkillAttack.create_attack("Double dague", 2, 1, 2))
	voleur.addSkill(SkillSupport.create_support(
			"Poison", 3, SkillSupport.SupportType.DEBUFF, SkillSupport.Stat.HEALTH, 1, 3))

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
