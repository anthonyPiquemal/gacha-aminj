class_name InventorySlot
extends Button
## Case de la grille d'inventaire. Affiche une carte possédée avec le même
## visuel que le combat (CardView), réduit pour tenir dans la grille 4 × 5,
## ou un emplacement vide. Les cases partagent un ButtonGroup pour qu'une
## seule soit sélectionnée à la fois.

signal card_selected(data: CardData)

## Échelle de la carte dans la case (CardView fait 100 × 136 en taille réelle).
const CARD_SCALE := 0.68
const PADDING := 4.0

var data: CardData

var _card: CardView
var _styles: Dictionary = {}


func _init() -> void:
	custom_minimum_size = (CardView.CARD_SIZE * CARD_SCALE).round() + Vector2.ONE * PADDING * 2.0
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE

	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.0)
		style.set_corner_radius_all(8)
		style.set_border_width_all(2)
		style.border_color = Color(1, 1, 1, 0.0)
		add_theme_stylebox_override(state, style)
		_styles[state] = style

	toggled.connect(_on_toggled)


func set_card(p_data: CardData) -> void:
	data = p_data
	disabled = data == null
	set_pressed_no_signal(false)
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	tooltip_text = "" if data == null else "%s — PUI %d · PV %d" % [data.card_name, data.power, data.health]

	if _card != null:
		_card.queue_free()
		_card = null

	var accent := Color.WHITE
	if data != null:
		accent = data.color
		_card = CardView.new()
		# Carte dessinée directement à la taille de la case (texte net).
		_card.setup(data, false, CARD_SCALE)
		_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_card.position = Vector2.ONE * PADDING
		add_child(_card)

	# Case vide : simple cadre estompé.
	var empty_style: StyleBoxFlat = _styles["disabled"]
	empty_style.bg_color = Color(1, 1, 1, 0.04)
	empty_style.border_color = Color(1, 1, 1, 0.08)

	_styles["normal"].border_color = Color(accent, 0.0)
	_styles["hover"].border_color = Color(accent, 0.6)
	for state in ["pressed", "hover_pressed"]:
		_styles[state].border_color = accent
		_styles[state].bg_color = Color(accent, 0.18)


func _on_toggled(on: bool) -> void:
	if on and data != null:
		card_selected.emit(data)
