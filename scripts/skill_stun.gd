class_name SkillStun
extends CardSkills
## Skill de contrôle : la cible est étourdie et passe ses prochaines actions.

## Nombre d'actions que la cible va passer.
@export var turns: int = 1


static func create_stun(s_name: String, cool: int, p_turns: int = 1) -> SkillStun:
	var skill := SkillStun.new()
	skill.skill_name = s_name
	skill.cooldown = cool
	skill.turns = p_turns
	return skill
