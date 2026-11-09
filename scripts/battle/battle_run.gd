class_name BattleRun
extends RefCounted
## Une partie : FIGHT_COUNT combats à la suite contre des équipes aléatoires
## de cartes AMINJ, de plus en plus fortes.
## Les PV des cartes du joueur sont conservés d'un combat à l'autre et une
## carte morte disparaît pour le reste de la partie.
## (Plus tard : quiz entre deux combats, lootbox à la fin.)

const FIGHT_COUNT := 3
## Multiplicateurs de PV et de puissance des ennemis, par combat.
## (Les ennemis sont les mêmes cartes que le joueur : il faut les affaiblir
## puisque le joueur garde ses PV d'un combat à l'autre.)
const HP_SCALE := [0.45, 0.55, 0.62]
const POWER_SCALE := [0.7, 0.72, 0.78]

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


## Tire les équipes de toute la partie : 3 cartes AMINJ différentes par
## combat, avec PV et puissance réduits au début puis de plus en plus forts.
static func random_enemy_teams(rng: RandomNumberGenerator = null) -> Array:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var teams: Array = []
	for fight in FIGHT_COUNT:
		var pool := CardLibrary.aminj_cards()
		var team: Array[CardData] = []
		for slot in 3:
			var card: CardData = pool.pop_at(rng.randi_range(0, pool.size() - 1))
			card.health = maxi(1, roundi(card.health * HP_SCALE[fight]))
			card.power = maxi(1, roundi(card.power * POWER_SCALE[fight]))
			_scale_skill(card.get_skill(), POWER_SCALE[fight])
			team.append(card)
		teams.append(team)
	return teams


## Réduit aussi les dégâts fixes et les soins des compétences ennemies.
static func _scale_skill(skill: CardSkills, factor: float) -> void:
	if skill is SkillAttack and skill.flat_damage > 0:
		skill.flat_damage = maxi(1, roundi(skill.flat_damage * factor))
	elif skill is SkillSupport:
		skill.amount = maxi(1, roundi(skill.amount * factor))
