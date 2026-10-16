class_name CardSlot
extends PanelContainer
## Emplacement de carte.
## - PLAYER_SLOT : accepte 1 carte du joueur (échange si déjà occupé)
## - ENEMY_SLOT  : emplacement adverse, n'accepte aucun drop
## - DECK        : zone du deck, accepte plusieurs cartes

signal cards_changed

enum Kind { PLAYER_SLOT, ENEMY_SLOT, DECK }

var kind: Kind = Kind.PLAYER_SLOT
var locked: bool = false
var holder: Container

var _placeholder: Label


func setup(p_kind: Kind) -> void:
	kind = p_kind

	var border := Color(0.35, 0.45, 0.75)
	var placeholder_text := "Déposer\nune carte"
	match kind:
		Kind.ENEMY_SLOT:
			border = Color(0.75, 0.35, 0.35)
			placeholder_text = "Vide"
		Kind.DECK:
			border = Color(0.5, 0.5, 0.5)
			placeholder_text = "Deck vide"

	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.05)
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	if kind == Kind.DECK:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		holder = row
		custom_minimum_size = Vector2(0, CardView.CARD_SIZE.y + 16)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		holder = CenterContainer.new()
		custom_minimum_size = CardView.CARD_SIZE + Vector2(16, 16)

	_placeholder = Label.new()
	_placeholder.text = placeholder_text
	_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placeholder.modulate = Color(1, 1, 1, 0.4)
	_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(holder)
	add_child(_placeholder)
	holder.child_order_changed.connect(_update_placeholder)


func _update_placeholder() -> void:
	_placeholder.visible = holder.get_child_count() == 0


## Retourne la carte posée (slots simples uniquement).
func get_card() -> CardView:
	if holder.get_child_count() == 0:
		return null
	return holder.get_child(0) as CardView


func add_card(card: CardView) -> void:
	var old_slot := card.slot
	var old_parent := card.get_parent()
	if old_parent != null:
		old_parent.remove_child(card)
	holder.add_child(card)
	card.slot = self
	cards_changed.emit()
	if old_slot != null and old_slot != self:
		old_slot.cards_changed.emit()


# --- Drag & drop -------------------------------------------------------------

func _can_drop_data(_at_position: Vector2, drag_data: Variant) -> bool:
	if locked or kind == Kind.ENEMY_SLOT:
		return false
	if not (drag_data is Dictionary and drag_data.has("card")):
		return false
	var card: CardView = drag_data["card"]
	return card.draggable


func _drop_data(_at_position: Vector2, drag_data: Variant) -> void:
	var card: CardView = drag_data["card"]
	var origin := card.slot
	if origin == self:
		return

	# Slot déjà occupé : la carte présente retourne à l'emplacement d'origine.
	if kind != Kind.DECK:
		var existing := get_card()
		if existing != null and origin != null:
			origin.add_card(existing)

	add_card(card)
