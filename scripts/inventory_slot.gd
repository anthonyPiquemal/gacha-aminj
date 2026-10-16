class_name InventorySlot
extends Button
## Case de la grille d'inventaire. Affiche une carte possédée ou un
## emplacement vide. Les cases d'une même page partagent un ButtonGroup
## pour qu'une seule soit sélectionnée à la fois.

signal card_selected(data: CharacterCardData)

const SLOT_SIZE := Vector2(74, 96)

var data: CharacterCardData

var _face: CardFace
var _styles: Dictionary = {}


func _init() -> void:
	custom_minimum_size = SLOT_SIZE
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	_face = CardFace.new()
	_face.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Léger retrait pour laisser voir la bordure de sélection autour du cadre.
	_face.offset_left = 4
	_face.offset_top = 4
	_face.offset_right = -4
	_face.offset_bottom = -4
	add_child(_face)

	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.0)
		style.set_corner_radius_all(6)
		style.set_border_width_all(2)
		style.border_color = Color(1, 1, 1, 0.0)
		add_theme_stylebox_override(state, style)
		_styles[state] = style

	toggled.connect(_on_toggled)


func set_card(p_data: CharacterCardData) -> void:
	data = p_data
	disabled = data == null
	button_pressed = false
	mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	tooltip_text = "" if data == null else "%s — %s" % [data.display_name, data.rarity_name()]
	_face.set_card(data, true)

	var rarity := Color.WHITE if data == null else data.rarity_color()
	_styles["normal"].border_color = Color(rarity, 0.0)
	_styles["disabled"].border_color = Color(1, 1, 1, 0.0)
	_styles["hover"].border_color = Color(rarity, 0.6)
	_styles["pressed"].border_color = rarity
	_styles["hover_pressed"].border_color = rarity
	_styles["pressed"].bg_color = Color(rarity, 0.15)
	_styles["hover_pressed"].bg_color = Color(rarity, 0.15)


func _on_toggled(on: bool) -> void:
	if on and data != null:
		card_selected.emit(data)
