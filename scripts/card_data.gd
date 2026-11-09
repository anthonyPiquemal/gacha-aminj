class_name CardData
extends Resource
## Données d'une carte (nom, puissance, points de vie, couleur, compétence).
## Les dégâts d'une action = puissance × multiplicateur (attaque de base = × 1).

## Façon d'attaquer : choisit l'animation en combat.
enum AttackStyle { SWORD, MAGIC, DAGGER, ARROW, CLAW, SMASH, FIRE }

@export var card_name: String = ""
@export var power: int = 1
@export var health: int = 1
## Une seule compétence est utilisée en combat pour l'instant : skills[0].
@export var skills: Array[CardSkills] = []
@export var color: Color = Color.WHITE
@export var attack_style: AttackStyle = AttackStyle.SWORD


static func create(p_name: String, p_power: int, p_health: int, p_color: Color) -> CardData:
	var card := CardData.new()
	card.card_name = p_name
	card.power = p_power
	card.health = p_health
	card.color = p_color
	return card


## Variante chaînable : CardData.create(...).with_skill(...)
func with_skill(skill: CardSkills) -> CardData:
	addSkill(skill)
	return self


func with_style(style: AttackStyle) -> CardData:
	attack_style = style
	return self


## La compétence utilisée en combat (null si la carte n'en a pas).
func get_skill() -> CardSkills:
	return skills[0] if not skills.is_empty() else null


func addSkill(skill: CardSkills) -> void:
	skills.append(skill)


func removeSkill(skill: CardSkills) -> void:
	skills.erase(skill)
