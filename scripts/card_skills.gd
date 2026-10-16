class_name CardSkills
extends Resource

@export var skill_name: String = ""
@export var cooldown: int = 1

static func create(s_name: String, cool: int) -> CardSkills:
	var skill := CardSkills.new()
	skill.skill_name = s_name
	skill.cooldown = cool
	return skill
