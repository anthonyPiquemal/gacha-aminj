extends Control
## Scène de combat : 3 slots adverses (cartes prédéfinies), 3 slots joueur,
## le deck du joueur en bas et un bouton "Combat".

const SLOT_COUNT := 3

var enemy_slots: Array[CardSlot] = []
var player_slots: Array[CardSlot] = []
var deck: CardSlot
var fight_button: Button

var _status_label: Label
var _fighting: bool = false
var _finished: bool = false


func _ready() -> void:
	_build_ui()
	_fill_enemy_slots()
	_fill_deck()
	_update_button()


# --- Construction de l'interface ---------------------------------------------

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("1b1e2b")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	# Adversaire (+ bouton de retour au menu à gauche)
	var top_row := HBoxContainer.new()
	root.add_child(top_row)
	var back := Button.new()
	back.text = "← Menu"
	back.custom_minimum_size = Vector2(120, 32)
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/Main-menu.tscn"))
	top_row.add_child(back)
	var enemy_title := _make_label("Adversaire", 18)
	enemy_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(enemy_title)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(120, 0)
	top_row.add_child(balance)
	root.add_child(_make_slots(enemy_slots, CardSlot.Kind.ENEMY_SLOT))

	_status_label = _make_label("VS", 22)
	root.add_child(_status_label)

	# Slots du joueur + bouton Combat à droite
	var player_row := HBoxContainer.new()
	root.add_child(player_row)

	var left_spacer := Control.new()
	left_spacer.custom_minimum_size = Vector2(170, 0)
	player_row.add_child(left_spacer)

	var slots_row := _make_slots(player_slots, CardSlot.Kind.PLAYER_SLOT)
	slots_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_row.add_child(slots_row)

	fight_button = Button.new()
	fight_button.text = "Combat"
	fight_button.custom_minimum_size = Vector2(170, 60)
	fight_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fight_button.add_theme_font_size_override("font_size", 22)
	fight_button.pressed.connect(_on_fight_pressed)
	player_row.add_child(fight_button)

	# Deck en bas
	root.add_child(_make_label("Votre deck", 18))
	deck = CardSlot.new()
	deck.setup(CardSlot.Kind.DECK)
	deck.cards_changed.connect(_update_button)
	root.add_child(deck)


func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_slots(target: Array[CardSlot], kind: CardSlot.Kind) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	for i in SLOT_COUNT:
		var slot := CardSlot.new()
		slot.setup(kind)
		slot.cards_changed.connect(_update_button)
		row.add_child(slot)
		target.append(slot)
	return row


# --- Cartes prédéfinies ------------------------------------------------------

func _fill_enemy_slots() -> void:
	var enemy_cards: Array[CardData] = [
		CardData.create("Gobelin", 2, 3, Color("c0392b")),
		CardData.create("Golem", 1, 6, Color("7f8c8d")),
		CardData.create("Archer", 3, 2, Color("27ae60")),
	]
	for i in SLOT_COUNT:
		var card := CardView.new()
		card.setup(enemy_cards[i], false)
		enemy_slots[i].add_card(card)


## Le deck du joueur = les cartes de sa collection (voir l'inventaire).
func _fill_deck() -> void:
	for data in PlayerCollection.get_cards():
		var card := CardView.new()
		card.setup(data, true)
		deck.add_card(card)


# --- Combat ------------------------------------------------------------------

func _update_button() -> void:
	if fight_button == null:
		return
	if _finished:
		fight_button.disabled = false
		return
	var has_card := false
	for slot in player_slots:
		if slot.get_card() != null:
			has_card = true
	fight_button.disabled = _fighting or not has_card


func _on_fight_pressed() -> void:
	if _finished:
		get_tree().reload_current_scene()
		return
	if _fighting:
		return

	_fighting = true
	_status_label.text = "Combat !"
	for slot in player_slots:
		slot.locked = true
	deck.locked = true
	_update_button()

	var player_wins := 0
	var enemy_wins := 0
	for i in SLOT_COUNT:
		var result := await _duel(player_slots[i].get_card(), enemy_slots[i].get_card())
		if result > 0:
			player_wins += 1
		elif result < 0:
			enemy_wins += 1
		await get_tree().create_timer(0.3).timeout

	if player_wins > enemy_wins:
		_status_label.text = "Victoire ! (%d - %d)" % [player_wins, enemy_wins]
	elif enemy_wins > player_wins:
		_status_label.text = "Défaite... (%d - %d)" % [player_wins, enemy_wins]
	else:
		_status_label.text = "Égalité (%d - %d)" % [player_wins, enemy_wins]

	_fighting = false
	_finished = true
	fight_button.text = "Rejouer"
	_update_button()


## Résout un duel sur une ligne. Retourne 1 (joueur gagne), -1 (adversaire gagne) ou 0.
func _duel(player_card: CardView, enemy_card: CardView) -> int:
	if player_card != null and enemy_card != null:
		var player_attack := player_card.data.attack
		var enemy_attack := enemy_card.data.attack
		player_card.punch()
		enemy_card.punch()
		await get_tree().create_timer(0.25).timeout
		player_card.take_damage(enemy_attack)
		enemy_card.take_damage(player_attack)
		await get_tree().create_timer(0.6).timeout

	var player_alive := player_card != null and not player_card.is_dead()
	var enemy_alive := enemy_card != null and not enemy_card.is_dead()
	if player_alive and not enemy_alive:
		return 1
	if enemy_alive and not player_alive:
		return -1
	return 0
