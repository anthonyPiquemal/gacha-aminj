extends Control
## Scène de combat.
## 1. Sélection : le joueur glisse jusqu'à 3 cartes de son deck dans ses slots.
## 2. Partie : BattleRun.FIGHT_COUNT combats à la suite contre des équipes fixes.
##    Les tours s'enchaînent seuls (BattleSimulator) et chaque compétence se
##    lance d'elle-même dès qu'elle est rechargée. Sous chaque carte, un
##    indicateur rond montre la recharge. Pause et ×2 règlent le rythme.
## Les PV sont conservés entre deux combats, une carte morte disparaît.

enum Phase { SELECT, FIGHTING, BETWEEN, OVER }

const SLOT_COUNT := 3
## Délai entre deux actions (en secondes, à vitesse ×1).
const ACTION_DELAY := 0.8

var enemy_slots: Array[CardSlot] = []
var player_slots: Array[CardSlot] = []
var deck: CardSlot

var _phase: Phase = Phase.SELECT
var _run: BattleRun
var _sim: BattleSimulator
var _paused: bool = false
## Équipes ennemies de la partie, tirées au hasard à l'ouverture de la scène.
var _enemy_teams: Array = []

## BattleUnit → CardView affichée.
var _views: Dictionary = {}
## Bouton de compétence sous chaque slot joueur, et info sous chaque ennemi.
var _skill_buttons: Array[SkillButton] = []
var _enemy_infos: Array[Label] = []

## Compétence de l'action en cours (null = attaque de base).
var _current_skill: CardSkills = null
var _hits_in_action: int = 0
var _fx: BattleFx

## Nœuds de la scène (battle.tscn), modifiables dans l'éditeur.
@onready var _title_label: Label = %Title
@onready var _status_label: Label = %StatusLabel
@onready var _round_label: Label = %RoundLabel
@onready var _action_button: Button = %ActionButton
@onready var _pause_button: Button = %PauseButton
@onready var _speed_button: Button = %SpeedButton
@onready var _deck_title: Label = %DeckTitle


func _ready() -> void:
	_setup_ui()
	_fill_deck()
	_enemy_teams = BattleRun.random_enemy_teams()
	var first_team: Array[CardData] = []
	first_team.assign(_enemy_teams[0])
	_show_enemies(first_team)
	_update_ui()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# --- Construction de l'interface ---------------------------------------------

## Relie les nœuds de battle.tscn au script (la mise en page est dans la scène).
func _setup_ui() -> void:
	for i in range(1, SLOT_COUNT + 1):
		var enemy_slot: CardSlot = get_node("%%EnemySlot%d" % i)
		enemy_slot.setup(CardSlot.Kind.ENEMY_SLOT)
		enemy_slots.append(enemy_slot)
		_enemy_infos.append(get_node("%%EnemyInfo%d" % i))

		var player_slot: CardSlot = get_node("%%PlayerSlot%d" % i)
		player_slot.setup(CardSlot.Kind.PLAYER_SLOT)
		player_slot.cards_changed.connect(_update_ui)
		player_slots.append(player_slot)
		_skill_buttons.append(get_node("%%SkillButton%d" % i))

	deck = %Deck
	deck.setup(CardSlot.Kind.DECK)
	deck.cards_changed.connect(_update_ui)
	_fx = %Fx
	_round_label.text = ""

	%BackButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/Main-menu.tscn"))
	_pause_button.pressed.connect(_on_pause_pressed)
	_speed_button.toggled.connect(func(on: bool) -> void: Engine.time_scale = 2.0 if on else 1.0)
	_action_button.pressed.connect(_on_action_pressed)


func _fill_deck() -> void:
	for data in PlayerCollection.get_cards():
		var card := CardView.new()
		card.setup(data, true)
		deck.add_card(card)


func _show_enemies(team: Array[CardData], units: Array[BattleUnit] = []) -> void:
	for i in SLOT_COUNT:
		var old := enemy_slots[i].get_card()
		if old != null:
			old.queue_free()
			enemy_slots[i].holder.remove_child(old)
		if i >= team.size():
			continue
		var card := CardView.new()
		card.setup(team[i], false)
		enemy_slots[i].add_card(card)
		if i < units.size():
			card.bind_unit(units[i])
			_views[units[i]] = card


# --- Boutons -----------------------------------------------------------------

func _on_action_pressed() -> void:
	match _phase:
		Phase.SELECT:
			_start_run()
		Phase.BETWEEN:
			# (Plus tard : le quiz s'affichera ici avant le combat suivant.)
			_run.next_fight()
			_start_fight()
		Phase.OVER:
			get_tree().reload_current_scene()


func _on_pause_pressed() -> void:
	_paused = not _paused
	_update_ui()


# --- Déroulement de la partie ------------------------------------------------

func _start_run() -> void:
	var team: Array[CardData] = []
	var views: Array[CardView] = []
	for slot in player_slots:
		var card := slot.get_card()
		if card != null:
			team.append(card.data)
			views.append(card)
	if team.is_empty():
		return

	# Les cartes choisies sont regroupées à gauche : slot i = carte i.
	_run = BattleRun.new(team, _enemy_teams)
	for i in views.size():
		if views[i].slot != player_slots[i]:
			player_slots[i].add_card(views[i])
		views[i].bind_unit(_run.players[i])
		_views[_run.players[i]] = views[i]
	for slot in player_slots:
		slot.locked = true
	deck.locked = true
	deck.visible = false
	_deck_title.visible = false
	_start_fight()


func _start_fight() -> void:
	var enemies := _run.create_enemies()
	_show_enemies(_run.current_enemy_team(), enemies)

	_sim = BattleSimulator.new(_run.players, enemies)
	_sim.round_started.connect(_on_round_started)
	_sim.action_started.connect(_on_action_started)
	_sim.skill_used.connect(_on_skill_used)
	_sim.damage_dealt.connect(_on_damage_dealt)
	_sim.healed.connect(_on_healed)
	_sim.buff_applied.connect(_on_buff_applied)
	_sim.stunned.connect(_on_stunned)
	_sim.action_skipped.connect(_on_action_skipped)
	_sim.power_changed.connect(_on_unit_changed)
	_sim.unit_updated.connect(_on_unit_changed)
	_sim.battle_ended.connect(_on_battle_ended)

	_phase = Phase.FIGHTING
	_status_label.text = "Combat !"
	_sim.start()
	_update_ui()
	_run_loop(_sim)


## Boucle d'animation : une action toutes les ACTION_DELAY secondes.
func _run_loop(sim: BattleSimulator) -> void:
	await get_tree().create_timer(0.6).timeout
	while is_inside_tree() and not sim.finished and sim == _sim:
		while _paused and is_inside_tree():
			await get_tree().process_frame
		if not is_inside_tree():
			return
		sim.step()
		_update_ui()
		await get_tree().create_timer(ACTION_DELAY).timeout
	for view in _views.values():
		if is_instance_valid(view):
			view.set_active(false)


func _on_battle_ended(result: int, by_timer: bool) -> void:
	var suffix := " (temps écoulé, plus de PV)" if by_timer and result != 0 else ""
	if result > 0 and not _run.is_last_fight():
		_phase = Phase.BETWEEN
		_status_label.text = "Victoire !%s Vos PV ne sont pas restaurés." % suffix
		_remove_dead_player_cards()
	elif result > 0:
		_phase = Phase.OVER
		_status_label.text = "Partie gagnée !%s 🎁 Lootbox (à venir)" % suffix
	elif result < 0:
		_phase = Phase.OVER
		_status_label.text = "Défaite...%s" % suffix
	else:
		_phase = Phase.OVER
		_status_label.text = "Égalité (temps écoulé, autant de PV)"
	_update_ui()


## Une carte morte disparaît pour le reste de la partie.
func _remove_dead_player_cards() -> void:
	for unit in _run.players:
		if not unit.is_alive() and _views.has(unit):
			var view: CardView = _views[unit]
			_views.erase(unit)
			if is_instance_valid(view):
				view.queue_free()


# --- Réactions aux événements du combat --------------------------------------

func _on_round_started(round_number: int) -> void:
	_round_label.text = "Tour %d / %d" % [round_number, BattleSimulator.MAX_ROUNDS]


func _on_action_started(unit: BattleUnit) -> void:
	for view in _views.values():
		if is_instance_valid(view):
			view.set_active(false)
	_current_skill = null
	_hits_in_action = 0
	var view := _view(unit)
	if view != null:
		view.set_active(true)
	_status_label.text = "%s attaque" % unit.data.card_name


func _on_skill_used(unit: BattleUnit, skill: CardSkills) -> void:
	_current_skill = skill
	_status_label.text = "%s lance %s !" % [unit.data.card_name, skill.skill_name]
	var view := _view(unit)
	if view != null:
		view.punch()
		view.show_number(skill.skill_name, BattleFx.GOLD)
		_fx.shockwave(view.center(), BattleFx.GOLD, 60.0)


## Animation d'un coup : dépend du style de la carte (épée, magie, dague…)
## et de l'action (attaque de base, gros coup, coups multiples, zone).
func _on_damage_dealt(source: BattleUnit, target: BattleUnit, amount: int) -> void:
	var index := _hits_in_action
	_hits_in_action += 1
	var target_view := _view(target)
	if target_view == null:
		return
	target_view.refresh_unit()

	var skill := _current_skill
	var attack := skill as SkillAttack
	var multi_hit := attack != null and attack.hits > 1 and not attack.target_all
	var area := attack != null and attack.target_all
	var strength := 1.0 if skill == null else (1.0 if multi_hit or area else 1.6)
	var delay := 0.0
	if multi_hit:
		delay = index * 0.22
	elif area:
		delay = 0.15 + index * 0.08
	# Le lanceur ne bouge qu'une fois par action (sauf coups multiples).
	var move_source := index == 0 or multi_hit

	if skill is SkillSupport:
		# Malus de PV : projectile violet.
		_later(delay, func() -> void: _fx_projectile_hit(source, target, amount))
		return
	_later(delay, func() -> void:
		_play_style_hit(source, target, amount, strength, move_source, index))


## Effet du style d'attaque de `source` sur `target`, puis flash de dégâts.
func _play_style_hit(source: BattleUnit, target: BattleUnit, amount: int,
		strength: float, move_source: bool, index: int) -> void:
	var source_view := _view(source)
	var target_view := _view(target)
	if target_view == null:
		return
	var to := target_view.center()
	var from := source_view.center() if source_view != null else to
	var color := source.data.color.lightened(0.3)
	var hit_delay := 0.0

	match source.data.attack_style:
		CardData.AttackStyle.SWORD:
			if move_source and source_view != null:
				source_view.lunge(to, 30.0 * strength)
			_fx.slash(to, Color.WHITE if strength <= 1.0 else BattleFx.GOLD, strength, index % 2 == 1)
		CardData.AttackStyle.DAGGER:
			if move_source and source_view != null:
				source_view.lunge(to, 22.0)
			_fx.slash(to, Color("dfe6e9"), 0.7 * strength, false)
			_later(0.08, func() -> void: _fx.slash(to, Color("dfe6e9"), 0.7 * strength, true))
		CardData.AttackStyle.CLAW:
			if move_source and source_view != null:
				source_view.lunge(to, 26.0 * strength)
			_fx.claws(to, Color("ff6b6b"), strength)
		CardData.AttackStyle.SMASH:
			if move_source and source_view != null:
				source_view.hop()
			hit_delay = 0.22
			_later(hit_delay, func() -> void:
				_fx.shockwave(to, Color("f5d08a"), 55.0 * strength)
				_fx.burst(to, Color("b08d57"))
				var view := _view(target)
				if view != null:
					view.shake())
		CardData.AttackStyle.MAGIC:
			if move_source and source_view != null:
				source_view.levitate()
			_fx.magic_orb(from, to, color, strength)
			hit_delay = BattleFx.TRAVEL
		CardData.AttackStyle.ARROW:
			_fx.arrow_shot(from, to, strength)
			hit_delay = BattleFx.TRAVEL
		CardData.AttackStyle.FIRE:
			if move_source and source_view != null:
				source_view.punch()
			_fx.fireball(from, to, strength)
			hit_delay = BattleFx.TRAVEL

	_later(hit_delay, func() -> void:
		var view := _view(target)
		if view != null:
			view.play_hit(amount))


func _fx_projectile_hit(source: BattleUnit, target: BattleUnit, amount: int) -> void:
	var source_view := _view(source)
	var target_view := _view(target)
	if target_view == null:
		return
	if source_view != null:
		_fx.projectile(source_view.center(), target_view.center(), BattleFx.PURPLE)
	_later(BattleFx.TRAVEL, func() -> void:
		var view := _view(target)
		if view != null:
			view.play_hit(amount))


func _on_buff_applied(source: BattleUnit, target: BattleUnit, amount: int) -> void:
	var source_view := _view(source)
	var target_view := _view(target)
	if target_view == null:
		return
	if amount < 0 and source_view != null:
		_fx.projectile(source_view.center(), target_view.center(), BattleFx.PURPLE)
	_later(BattleFx.TRAVEL if amount < 0 else 0.15, func() -> void:
		var view := _view(target)
		if view == null:
			return
		if amount < 0:
			_fx.arrows(view.center(), Color("ff7b7b"), false)
			view.show_number("%d PUI" % amount, Color("ff7b7b"))
		else:
			_fx.arrows(view.center(), BattleFx.GOLD, true)
			view.show_number("+%d PUI" % amount, BattleFx.GOLD))


## Giffle de Guacamole : projectile vert, puis la cible est étourdie.
func _on_stunned(source: BattleUnit, target: BattleUnit) -> void:
	var source_view := _view(source)
	var target_view := _view(target)
	if target_view == null:
		return
	if source_view != null:
		source_view.hop()
		_fx.projectile(source_view.center(), target_view.center(), Color("8bc34a"), 9.0)
	_later(BattleFx.TRAVEL, func() -> void:
		var view := _view(target)
		if view != null:
			view.shake()
			view.show_number("Étourdi !", Color("b4ff7a"))
			_fx.star_burst(view.center(), Color("8bc34a")))


func _on_action_skipped(unit: BattleUnit) -> void:
	_status_label.text = "%s est étourdi et passe son tour" % unit.data.card_name
	var view := _view(unit)
	if view != null:
		view.show_number("Étourdi", Color("b4ff7a"))
		view.shake()


func _on_healed(target: BattleUnit, amount: int) -> void:
	var view := _view(target)
	if view != null:
		view.refresh_unit()
		view.show_number("+%d" % amount, BattleFx.GREEN)
		_fx.heal(view.center())


## Lance `callback` après `delay` secondes (immédiatement si 0).
func _later(delay: float, callback: Callable) -> void:
	if delay <= 0.0:
		callback.call()
	elif is_inside_tree():
		get_tree().create_timer(delay).timeout.connect(callback, CONNECT_ONE_SHOT)


func _on_unit_changed(unit: BattleUnit) -> void:
	var view := _view(unit)
	if view != null:
		view.refresh_unit()


func _view(unit: BattleUnit) -> CardView:
	var view = _views.get(unit)
	return view if is_instance_valid(view) else null


func _player_unit(index: int) -> BattleUnit:
	if _run == null or index >= _run.players.size():
		return null
	return _run.players[index]


# --- Interface ---------------------------------------------------------------

func _update_ui() -> void:
	if _action_button == null:
		return
	var fight_number := 1 if _run == null else _run.fight_index + 1
	_title_label.text = "Combat %d / %d" % [fight_number, BattleRun.FIGHT_COUNT]

	match _phase:
		Phase.SELECT:
			var has_card := false
			for slot in player_slots:
				if slot.get_card() != null:
					has_card = true
			_action_button.text = "Lancer la partie"
			_action_button.disabled = not has_card
			if _status_label.text == "":
				_status_label.text = "VS"
		Phase.FIGHTING:
			_action_button.text = "Combat en cours"
			_action_button.disabled = true
		Phase.BETWEEN:
			_action_button.text = "Combat suivant →"
			_action_button.disabled = false
		Phase.OVER:
			_action_button.text = "Rejouer"
			_action_button.disabled = false

	_round_label.visible = _phase != Phase.SELECT
	_pause_button.text = "▶ Reprendre" if _paused else "⏸ Pause"
	_pause_button.disabled = _phase != Phase.FIGHTING
	_speed_button.disabled = _phase == Phase.SELECT or _phase == Phase.OVER

	for i in _skill_buttons.size():
		_update_skill_button(i)
	for i in _enemy_infos.size():
		_update_enemy_info(i)


func _update_skill_button(index: int) -> void:
	var button := _skill_buttons[index]
	var unit := _player_unit(index)
	# Pendant la sélection, les indicateurs sont masqués pour laisser la place au deck.
	button.visible = _phase != Phase.SELECT
	if unit == null:
		button.clear()
		return
	if not unit.is_alive() or unit.skill() == null:
		button.clear()
	else:
		button.set_state(unit.skill(), unit.data.color, unit.cooldown_left,
				unit.is_skill_ready(), _phase == Phase.FIGHTING)


func _update_enemy_info(index: int) -> void:
	var info := _enemy_infos[index]
	var unit: BattleUnit = null
	if _sim != null and index < _sim.enemies.size():
		unit = _sim.enemies[index]
	if unit == null or not unit.is_alive() or unit.skill() == null:
		var slot_card := enemy_slots[index].get_card()
		var preview: CardSkills = slot_card.data.get_skill() if slot_card != null else null
		info.text = preview.skill_name if preview != null and unit == null else ""
		return
	var skill := unit.skill()
	info.text = "%s : %s" % [skill.skill_name, "prête" if unit.is_skill_ready() else str(unit.cooldown_left)]
