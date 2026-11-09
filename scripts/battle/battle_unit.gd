class_name BattleUnit
extends RefCounted
## État d'une carte pendant une partie (aucun visuel ici).
## Les PV sont conservés d'un combat à l'autre : on garde le même BattleUnit.

enum Team { PLAYER, ENEMY }

var data: CardData
var team: Team
var slot_index: int
var max_hp: int
var hp: int
## Actions restantes avant que la compétence soit prête (0 = prête).
var cooldown_left: int = 0
## Bonus/malus de puissance actifs : [{ "amount": int, "rounds": int }]
## rounds = -1 → jusqu'à la fin du combat.
var power_mods: Array[Dictionary] = []


func _init(p_data: CardData, p_team: Team, p_slot: int) -> void:
	data = p_data
	team = p_team
	slot_index = p_slot
	max_hp = data.health
	hp = max_hp


func is_alive() -> bool:
	return hp > 0


func skill() -> CardSkills:
	return data.get_skill()


func is_skill_ready() -> bool:
	return skill() != null and cooldown_left <= 0


func power() -> int:
	var total := data.power
	for mod in power_mods:
		total += int(mod["amount"])
	return maxi(total, 0)


## Appelé au début de chaque combat : recharge pleine, effets retirés.
## Les PV, eux, ne sont pas restaurés.
func prepare_for_fight() -> void:
	power_mods.clear()
	cooldown_left = skill().cooldown if skill() != null else 0


func take_damage(amount: int) -> int:
	var dealt := mini(amount, hp)
	hp -= dealt
	return dealt


func heal(amount: int) -> int:
	var healed := mini(amount, max_hp - hp)
	hp += healed
	return healed


## Fin d'un tour de combat : les effets temporaires s'usent.
func tick_round() -> void:
	for i in range(power_mods.size() - 1, -1, -1):
		var rounds: int = power_mods[i]["rounds"]
		if rounds < 0:
			continue
		rounds -= 1
		if rounds <= 0:
			power_mods.remove_at(i)
		else:
			power_mods[i]["rounds"] = rounds
