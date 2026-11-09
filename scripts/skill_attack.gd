class_name SkillAttack
extends CardSkills
## Skill d'attaque : inflige des dégâts à une ou plusieurs cartes adverses.

@export var damage: int = 1
## Nombre de coups portés (ex : 2 = attaque double).
@export var hits: int = 1
## Vrai = touche toutes les cartes adverses.
@export var target_all: bool = false


static func create_attack(
		s_name: String,
		cool: int,
		p_damage: int,
		p_hits: int = 1,
		p_target_all: bool = false) -> SkillAttack:
	var skill := SkillAttack.new()
	skill.skill_name = s_name
	skill.cooldown = cool
	skill.damage = p_damage
	skill.hits = p_hits
	skill.target_all = p_target_all
	return skill
