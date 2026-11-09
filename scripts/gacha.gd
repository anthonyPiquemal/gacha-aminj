# res://scripts/gacha.gd
extends Control

@export var booster_pool: Array[CardData] = []

var cards_container: HBoxContainer


func _ready() -> void:
	if booster_pool.is_empty():
		_generate_default_pool()
	
	_setup_cards_display()
	_connect_buttons_by_structure()


## Connecte directement les 3 boutons dans l'ordre de votre arbre de scène
func _connect_buttons_by_structure() -> void:
	# Récupère le bouton dans BoxContainer (X1)
	if has_node("BoxContainer/Button"):
		$BoxContainer/Button.pressed.connect(func(): open_booster(1))
		print("✓ Bouton X1 (BoxContainer) connecté !")

	# Récupère le bouton dans BoxContainer2 (X10)
	if has_node("BoxContainer2/Button"):
		$BoxContainer2/Button.pressed.connect(func(): open_booster(10))
		print("✓ Bouton X10 (BoxContainer2) connecté !")

	# Récupère le bouton dans BoxContainer3 (X100)
	if has_node("BoxContainer3/Button"):
		$BoxContainer3/Button.pressed.connect(func(): open_booster(100))
		print("✓ Bouton X100 (BoxContainer3) connecté !")


func _generate_default_pool() -> void:
	var c1 := CardData.create("Chevalier d'Élite", 4, 5, Color("2980b9"))
	var c2 := CardData.create("Archimage", 5, 3, Color("8e44ad"))
	var c3 := CardData.create("Assassin", 4, 2, Color("d35400"))
	var c4 := CardData.create("Gardien", 2, 7, Color("27ae60"))
	var c5 := CardData.create("Dragon Rouge", 6, 6, Color("c0392b"))
	booster_pool = [c1, c2, c3, c4, c5]


func open_booster(booster_count: int = 1) -> void:
	if booster_pool.is_empty():
		push_error("Aucune carte dans le pool !")
		return

	var total_cards := booster_count * 5
	var drawn_cards: Array[CardData] = []

	for i in range(total_cards):
		var card = booster_pool.pick_random()
		drawn_cards.append(card.duplicate())

	# 1. Ajout des cartes à votre inventaire (PlayerCollection)
	PlayerCollection.add_cards(drawn_cards)
	print("SUCCÈS : %d carte(s) ajoutée(s) à la collection !" % drawn_cards.size())

	# 2. Affichage des 5 dernières cartes obtenues à l'écran
	var cards_to_show = drawn_cards.slice(-5) if drawn_cards.size() > 5 else drawn_cards
	_display_cards(cards_to_show)


func _setup_cards_display() -> void:
	cards_container = HBoxContainer.new()
	cards_container.name = "DrawnCardsContainer"
	cards_container.set_anchors_preset(Control.PRESET_CENTER)
	cards_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cards_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	cards_container.position.y += 120 # Décalé vers le bas sous les boutons
	cards_container.add_theme_constant_override("separation", 20)
	add_child(cards_container)


func _display_cards(cards: Array[CardData]) -> void:
	for child in cards_container.get_children():
		child.queue_free()

	for data in cards:
		var card_view := CardView.new()
		card_view.setup(data, false)
		cards_container.add_child(card_view)
