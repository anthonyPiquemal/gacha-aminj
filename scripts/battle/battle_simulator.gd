class_name BattleSimulator
extends RefCounted
## Logique d'un combat au tour par tour, sans aucun visuel.
## La scène appelle step() à son rythme (pause, ×2) et anime via les signaux.
##
## Règles :
## - un tour = chaque carte vivante agit une fois, en alternance
##   joueur 1, ennemi 1, joueur 2, ennemi 2… ;
## - action = compétence dès qu'elle est prête (joueur comme ennemi),
##   sinon attaque de base (puissance × 1) ;
## - cible : la carte en face, sinon l'adversaire vivant avec le moins de PV ;
## - limite de MAX_ROUNDS tours : l'équipe avec le plus de PV gagne, égalité sinon.

signal round_started(round_number: int)
signal action_started(unit: BattleUnit)
signal skill_used(unit: BattleUnit, skill: CardSkills)
signal damage_dealt(source: BattleUnit, target: BattleUnit, amount: int)
signal healed(target: BattleUnit, amount: int)
signal power_changed(unit: BattleUnit)
## Bonus (amount > 0) ou malus (amount < 0) de puissance appliqué par une compétence.
signal buff_applied(source: BattleUnit, target: BattleUnit, amount: int)
signal unit_died(unit: BattleUnit)
## `target` est étourdie par `source` (elle passera ses prochaines actions).
signal stunned(source: BattleUnit, target: BattleUnit)
## `unit` est étourdie : elle passe son action.
signal action_skipped(unit: BattleUnit)
signal unit_updated(unit: BattleUnit)
## result : 1 = victoire du joueur, -1 = défaite, 0 = égalité.
signal battle_ended(result: int, by_timer: bool)

const MAX_ROUNDS := 15

var players: Array[BattleUnit] = []
var enemies: Array[BattleUnit] = []
var round_number: int = 0
var finished: bool = false
var result: int = 0

var _queue: Array[BattleUnit] = []


func _init(p_players: Array[BattleUnit], p_enemies: Array[BattleUnit]) -> void:
	players = p_players
	enemies = p_enemies


func start() -> void:
	for unit in players + enemies:
		if unit.is_alive():
			unit.prepare_for_fight()
			unit_updated.emit(unit)
	_start_round()


## Joue la prochaine action. Sans effet si le combat est fini.
func step() -> void:
	if finished:
		return
	var actor := _next_actor()
	if actor == null:
		return
	_act(actor)
	_check_end()


# --- Déroulement -------------------------------------------------------------

func _start_round() -> void:
	round_number += 1
	_queue.clear()
	for i in maxi(players.size(), enemies.size()):
		if i < players.size():
			_queue.append(players[i])
		if i < enemies.size():
			_queue.append(enemies[i])
	round_started.emit(round_number)


func _next_actor() -> BattleUnit:
	while true:
		while not _queue.is_empty() and not _queue[0].is_alive():
			_queue.pop_front()
		if not _queue.is_empty():
			return _queue.pop_front()
		# Fin du tour.
		for unit in players + enemies:
			if unit.is_alive():
				unit.tick_round()
				power_changed.emit(unit)
		if round_number >= MAX_ROUNDS:
			_end_by_timer()
			return null
		_start_round()
	return null


func _act(unit: BattleUnit) -> void:
	if unit.stunned_turns > 0:
		unit.stunned_turns -= 1
		action_skipped.emit(unit)
		unit_updated.emit(unit)
		return
	action_started.emit(unit)
	if unit.is_skill_ready():
		var skill := unit.skill()
		skill_used.emit(unit, skill)
		_apply_skill(unit, skill)
		unit.cooldown_left = skill.cooldown
	else:
		var target := _pick_target(unit)
		if target != null:
			_deal(unit, target, unit.power())
		if unit.cooldown_left > 0:
			unit.cooldown_left -= 1
	unit_updated.emit(unit)


func _apply_skill(unit: BattleUnit, skill: CardSkills) -> void:
	if skill is SkillAttack:
		var attack := skill as SkillAttack
		var damage := attack.flat_damage
		if damage <= 0:
			damage = maxi(1, roundi(unit.power() * attack.multiplier))
		for hit in attack.hits:
			var targets: Array = _alive(_opponents(unit)) if attack.target_all else [_pick_target(unit)]
			for target: BattleUnit in targets:
				if target != null and target.is_alive():
					_deal(unit, target, damage)
	elif skill is SkillStun:
		var target := _pick_target(unit)
		if target != null:
			target.stunned_turns += (skill as SkillStun).turns
			stunned.emit(unit, target)
			unit_updated.emit(target)
	elif skill is SkillSupport:
		var support := skill as SkillSupport
		var targets: Array = []
		if support.is_debuff():
			targets = _alive(_opponents(unit)) if support.target_all else [_pick_target(unit)]
		else:
			targets = _alive(_allies(unit)) if support.target_all else [_most_hurt_ally(unit)]
		for target: BattleUnit in targets:
			if target == null or not target.is_alive():
				continue
			if support.stat == SkillSupport.Stat.ATTACK:
				var rounds := support.duration if support.duration > 0 else -1
				target.power_mods.append({"amount": support.get_signed_amount(), "rounds": rounds})
				buff_applied.emit(unit, target, support.get_signed_amount())
				power_changed.emit(target)
			elif support.is_debuff():
				_deal(unit, target, support.amount)
			else:
				healed.emit(target, target.heal(support.amount))
				unit_updated.emit(target)


func _deal(source: BattleUnit, target: BattleUnit, amount: int) -> void:
	var dealt := target.take_damage(amount)
	damage_dealt.emit(source, target, dealt)
	unit_updated.emit(target)
	if not target.is_alive():
		unit_died.emit(target)


func _check_end() -> void:
	if _alive(enemies).is_empty():
		_finish(1, false)
	elif _alive(players).is_empty():
		_finish(-1, false)


func _end_by_timer() -> void:
	var player_hp := 0
	var enemy_hp := 0
	for unit in _alive(players):
		player_hp += unit.hp
	for unit in _alive(enemies):
		enemy_hp += unit.hp
	_finish(signi(player_hp - enemy_hp), true)


func _finish(p_result: int, by_timer: bool) -> void:
	finished = true
	result = p_result
	battle_ended.emit(result, by_timer)


# --- Ciblage -----------------------------------------------------------------

func _opponents(unit: BattleUnit) -> Array[BattleUnit]:
	return enemies if unit.team == BattleUnit.Team.PLAYER else players


func _allies(unit: BattleUnit) -> Array[BattleUnit]:
	return players if unit.team == BattleUnit.Team.PLAYER else enemies


func _alive(units: Array[BattleUnit]) -> Array[BattleUnit]:
	var alive: Array[BattleUnit] = []
	for u in units:
		if u.is_alive():
			alive.append(u)
	return alive


## La carte en face si elle est vivante, sinon l'adversaire avec le moins de PV.
func _pick_target(unit: BattleUnit) -> BattleUnit:
	var candidates := _alive(_opponents(unit))
	if candidates.is_empty():
		return null
	for other in candidates:
		if other.slot_index == unit.slot_index:
			return other
	var best := candidates[0]
	for other in candidates:
		if other.hp < best.hp:
			best = other
	return best


## Allié vivant avec le moins de PV (cible des soins et buffs).
func _most_hurt_ally(unit: BattleUnit) -> BattleUnit:
	var best: BattleUnit = null
	for ally in _alive(_allies(unit)):
		if best == null or ally.hp < best.hp:
			best = ally
	return best
