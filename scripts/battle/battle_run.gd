class_name BattleRun
extends RefCounted
## Une partie : FIGHT_COUNT combats à la suite contre des équipes aléatoires
## de plus en plus fortes (le dernier combat a un boss au centre).
## Les PV des cartes du joueur sont conservés d'un combat à l'autre et une
## carte morte disparaît pour le reste de la partie.
## (Plus tard : quiz entre deux combats, lootbox à la fin.)

const FIGHT_COUNT := 3
## Multiplicateur de PV et bonus de puissance des ennemis, par combat.
const HP_SCALE := [1.0, 1.1, 1.0]
const POWER_BONUS := [0, 0, 0]

## Cartes du joueur (index = emplacement). Une carte morte y reste avec hp = 0.
var players: Array[BattleUnit] = []
var fight_index: int = 0
## Une équipe (Array[CardData]) par combat, tirée au début de la partie.
var enemy_teams: Array = []


func _init(team: Array[CardData], p_enemy_teams: Array = []) -> void:
	for i in team.size():
		players.append(BattleUnit.new(team[i], BattleUnit.Team.PLAYER, i))
	enemy_teams = p_enemy_teams if not p_enemy_teams.is_empty() else random_enemy_teams()


func is_last_fight() -> bool:
	return fight_index >= FIGHT_COUNT - 1


func next_fight() -> void:
	fight_index = mini(fight_index + 1, FIGHT_COUNT - 1)


func current_enemy_team() -> Array[CardData]:
	var team: Array[CardData] = []
	team.assign(enemy_teams[fight_index])
	return team


func create_enemies() -> Array[BattleUnit]:
	var units: Array[BattleUnit] = []
	var team := current_enemy_team()
	for i in team.size():
		units.append(BattleUnit.new(team[i], BattleUnit.Team.ENEMY, i))
	return units


## Tire les équipes de toute la partie (3 ennemis par combat, sans doublon
## dans une même équipe). Dernier combat : boss au centre.
static func random_enemy_teams(rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var teams: Array = []
	for fight in FIGHT_COUNT:
		var pool := enemy_pool()
		var team: Array[CardData] = []
		for slot in 3:
			var card: CardData = pool.pop_at(rng.randi_range(0, pool.size() - 1))
			card.health = roundi(card.health * HP_SCALE[fight])
			card.power += POWER_BONUS[fight]
			team.append(card)
		if fight == FIGHT_COUNT - 1:
			team[1] = create_boss()
		teams.append(team)
	return teams


## Ennemis possibles (stats du premier combat, recréés à chaque appel).
static func enemy_pool() -> Array[CardData]:
	return [
		CardData.create("Gobelin", 2, 8, Color("c0392b")).with_style(CardData.AttackStyle.DAGGER).with_skill(
				SkillAttack.create_attack("Coup bas", 3, 2.0)),
		CardData.create("Archer", 3, 6, Color("27ae60")).with_style(CardData.AttackStyle.ARROW).with_skill(
				SkillAttack.create_attack("Tir précis", 2, 1.5)),
		CardData.create("Loup", 2, 7, Color("95a5a6")).with_style(CardData.AttackStyle.CLAW).with_skill(
				SkillAttack.create_attack("Morsure double", 2, 1.0, 2)),
		CardData.create("Squelette", 2, 9, Color("d5d0b5")).with_style(CardData.AttackStyle.SWORD).with_skill(
				SkillAttack.create_attack("Coup d'os", 3, 1.5)),
		CardData.create("Chamane", 2, 8, Color("16a085")).with_style(CardData.AttackStyle.MAGIC).with_skill(
				SkillSupport.create_support("Soin", 3, SkillSupport.SupportType.BUFF,
						SkillSupport.Stat.HEALTH, 4)),
		CardData.create("Orc", 3, 10, Color("6d8a2b")).with_style(CardData.AttackStyle.SWORD).with_skill(
				SkillSupport.create_support("Rage", 3, SkillSupport.SupportType.BUFF,
						SkillSupport.Stat.ATTACK, 2, 2, true)),
		CardData.create("Golem", 2, 14, Color("7f8c8d")).with_style(CardData.AttackStyle.SMASH).with_skill(
				SkillAttack.create_attack("Séisme", 3, 1.0, 1, true)),
		CardData.create("Sorcière", 2, 7, Color("6c3483")).with_style(CardData.AttackStyle.MAGIC).with_skill(
				SkillSupport.create_support("Malédiction", 3, SkillSupport.SupportType.DEBUFF,
						SkillSupport.Stat.ATTACK, 1, 2, true)),
		CardData.create("Kobold", 2, 6, Color("a0522d")).with_style(CardData.AttackStyle.CLAW).with_skill(
				SkillAttack.create_attack("Morsure", 3, 1.5)),
	]


static func create_boss() -> CardData:
	return CardData.create("Dragon", 3, 18, Color("8e1b1b")).with_style(CardData.AttackStyle.FIRE).with_skill(
			SkillAttack.create_attack("Souffle", 3, 1.0, 1, true))
