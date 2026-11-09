class_name SkillSupport
extends CardSkills
## Skill de soutien : buff (cartes alliées) ou debuff (cartes adverses).

enum SupportType { BUFF, DEBUFF }
enum Stat { ATTACK, HEALTH }

@export var support_type: SupportType = SupportType.BUFF
## Statistique modifiée (ATTACK = attaque, HEALTH = points de vie max).
@export var stat: Stat = Stat.ATTACK
## Valeur absolue de la modification (toujours positive).
@export var amount: int = 1
## Durée en tours (0 = permanent).
@export var duration: int = 2
## Vrai = affecte toutes les cartes ciblées.
@export var target_all: bool = false


static func create_support(
		s_name: String,
		cool: int,
		p_type: SupportType,
		p_stat: Stat,
		p_amount: int,
		p_duration: int = 2,
		p_target_all: bool = false) -> SkillSupport:
	var skill := SkillSupport.new()
	skill.skill_name = s_name
	skill.cooldown = cool
	skill.support_type = p_type
	skill.stat = p_stat
	skill.amount = absi(p_amount)
	skill.duration = p_duration
	skill.target_all = p_target_all
	return skill


func is_debuff() -> bool:
	return support_type == SupportType.DEBUFF


## Valeur à ajouter à la stat (négative pour un debuff).
func get_signed_amount() -> int:
	return -amount if is_debuff() else amount
