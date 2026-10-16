class_name CardFace
extends Control
## Face d'une carte personnage dessinée avec le cadre de « Carte et icône.png ».
## - mode compact (slot d'inventaire) : nom, rareté courte (C, R, SR…)
## - mode complet (fiche détaillée)   : nom, rareté en toutes lettres
## Le bandeau du bas affiche les PV et la puissance dans les deux modes.
## Les tailles de police suivent la hauteur de la carte.

## Rapport largeur / hauteur du cadre.
const ASPECT := 606.0 / 786.0

const RARITY_SHORT := ["C", "R", "SR", "SSR", "UR"]

var data: CharacterCardData
var compact: bool = true

var _frame: TextureRect
var _name_label: Label
var _rarity_label: Label
var _portrait: TextureRect
var _initial_label: Label
var _stats_row: HBoxContainer
var _stat_icons: Array[TextureRect] = []
var _stat_labels: Array[Label] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

	_frame = TextureRect.new()
	_frame.texture = CardArt.frame()
	_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	_name_label = _make_bar_label()
	CardArt.place(_name_label, CardArt.BAR_NAME)
	add_child(_name_label)

	_rarity_label = _make_bar_label()
	CardArt.place(_rarity_label, CardArt.BAR_RARITY)
	add_child(_rarity_label)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CardArt.place(_portrait, CardArt.ART_AREA)
	add_child(_portrait)

	_initial_label = _make_bar_label()
	_initial_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	CardArt.place(_initial_label, CardArt.ART_AREA)
	add_child(_initial_label)

	_stats_row = HBoxContainer.new()
	_stats_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	CardArt.place(_stats_row, CardArt.BAR_STATS)
	add_child(_stats_row)

	resized.connect(_update_sizes)


## Affiche une carte. `p_data` à null donne un emplacement vide (cadre estompé).
func set_card(p_data: CharacterCardData, p_compact: bool = true) -> void:
	data = p_data
	compact = p_compact
	_refresh()


func _refresh() -> void:
	var empty := data == null
	_frame.modulate = Color(1, 1, 1, 0.16) if empty else Color.WHITE
	for node: CanvasItem in [_name_label, _rarity_label, _portrait, _initial_label, _stats_row]:
		node.visible = not empty
	if empty:
		return

	var rarity_color := data.rarity_color()
	_name_label.text = data.display_name
	_rarity_label.text = RARITY_SHORT[data.rarity] if compact else data.rarity_name()
	_rarity_label.add_theme_color_override("font_color", rarity_color)

	_portrait.texture = data.portrait
	_initial_label.visible = data.portrait == null
	_initial_label.text = data.display_name.left(1).to_upper()
	_initial_label.add_theme_color_override("font_color", rarity_color)

	for child in _stats_row.get_children():
		child.queue_free()
	_stat_icons.clear()
	_stat_labels.clear()
	# Le bandeau du bas affiche PV et puissance ; la fiche détaillée liste le reste.
	_add_stat(&"hp", data.hp)
	_add_stat(&"power", data.power)

	_update_sizes()


func _add_stat(stat: StringName, value: int) -> void:
	var icon := TextureRect.new()
	icon.texture = CardArt.icon(stat)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_stats_row.add_child(icon)
	_stat_icons.append(icon)

	var label := _make_bar_label()
	label.text = str(value)
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_FILL
	_stats_row.add_child(label)
	_stat_labels.append(label)


func _update_sizes() -> void:
	var h := size.y
	if h <= 0.0:
		return
	var bar_font := maxi(8, roundi(h * 0.075))
	var outline := maxi(2, roundi(h * 0.012))
	for label in [_name_label, _rarity_label] + _stat_labels:
		label.add_theme_font_size_override("font_size", bar_font)
		label.add_theme_constant_override("outline_size", outline)
	_initial_label.add_theme_font_size_override("font_size", maxi(12, roundi(h * 0.22)))
	_initial_label.add_theme_constant_override("outline_size", outline * 2)

	var icon_size := h * 0.11
	for icon in _stat_icons:
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
	_stats_row.add_theme_constant_override("separation", maxi(2, roundi(h * 0.02)))


func _make_bar_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_outline_color", Color("1b1e2b"))
	return label
