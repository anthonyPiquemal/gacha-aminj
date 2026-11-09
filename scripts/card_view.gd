class_name CardView
extends PanelContainer
## Représentation visuelle d'une carte.
## Si `draggable` est vrai, elle peut être glissée vers un CardSlot.

const CARD_SIZE := Vector2(100, 136)

var data: CardData
var current_hp: int = 0
var draggable: bool = false
var slot: CardSlot = null

## Carte de combat liée (null hors combat, ex. inventaire).
var unit: BattleUnit = null

var _hp_label: Label
var _atk_label: Label
var _dead: bool = false
var _lunge_tween: Tween
## Textes flottants récents : on les empile pour qu'ils ne se chevauchent pas.
var _number_stack: int = 0
var _last_number_ms: int = 0
var _home: Vector2


## `p_scale` dessine la carte plus grande ou plus petite (1.0 = taille du combat).
## Les polices et bordures sont recalculées : le texte reste net, sans étirement.
func setup(p_data: CardData, p_draggable: bool, p_scale: float = 1.0) -> void:
	data = p_data
	current_hp = data.health
	draggable = p_draggable

	var card_size := (CARD_SIZE * p_scale).round()
	custom_minimum_size = card_size
	pivot_offset = card_size / 2.0
	if draggable:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.17, 0.23)
	style.set_border_width_all(maxi(1, roundi(3 * p_scale)))
	style.border_color = data.color
	style.set_corner_radius_all(roundi(8 * p_scale))
	style.set_content_margin_all(roundi(6 * p_scale))
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", roundi(4 * p_scale))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	var name_label := Label.new()
	name_label.text = data.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", maxi(6, roundi(14 * p_scale)))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var art := ColorRect.new()
	art.color = data.color
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(art)

	var stats := HBoxContainer.new()
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stats)

	_atk_label = Label.new()
	_atk_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_atk_label.add_theme_font_size_override("font_size", maxi(6, roundi(13 * p_scale)))
	_atk_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_child(_atk_label)

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", maxi(6, roundi(13 * p_scale)))
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_child(_hp_label)
	_refresh()


func _refresh() -> void:
	if unit == null:
		_atk_label.text = "PUI %d" % data.power
		_hp_label.text = "PV %d" % current_hp
		return
	var power := unit.power()
	_atk_label.text = "PUI %d" % power
	if power > data.power:
		_atk_label.add_theme_color_override("font_color", Color("6fdc8c"))
	elif power < data.power:
		_atk_label.add_theme_color_override("font_color", Color("ff7b7b"))
	else:
		_atk_label.remove_theme_color_override("font_color")
	_hp_label.text = "PV %d/%d" % [unit.hp, unit.max_hp]


# --- Combat ------------------------------------------------------------------

## Lie la carte à son état de combat (les PV affichés viennent de `unit`).
func bind_unit(p_unit: BattleUnit) -> void:
	unit = p_unit
	refresh_unit()


## Met à jour PV, puissance et aspect « mort » depuis `unit`.
func refresh_unit() -> void:
	if unit == null:
		return
	current_hp = unit.hp
	var was_dead := _dead
	_dead = not unit.is_alive()
	_refresh()
	if _dead and not was_dead:
		create_tween().tween_property(self, "modulate", Color(0.35, 0.35, 0.35), 0.4)
	elif not _dead and modulate != Color.WHITE:
		modulate = Color.WHITE


## Flash rouge + chiffre flottant (les PV sont lus dans `unit`).
func play_hit(amount: int) -> void:
	show_number("-%d" % amount, Color("ff6b6b"))
	if _dead:
		return
	modulate = Color(1.0, 0.4, 0.4)
	create_tween().tween_property(self, "modulate", Color.WHITE, 0.35)


## Texte qui monte et s'efface au-dessus de la carte.
func show_number(text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.top_level = true
	label.z_index = 10
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var now := Time.get_ticks_msec()
	_number_stack = _number_stack + 1 if now - _last_number_ms < 500 else 0
	_last_number_ms = now
	var text_width := label.get_minimum_size().x
	label.global_position = global_position + Vector2(size.x / 2.0 - text_width / 2.0, 10 + 24 * _number_stack)
	var tween := label.create_tween().set_parallel()
	tween.tween_property(label, "global_position:y", label.global_position.y - 40, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


## Met la carte en avant quand elle agit.
func set_active(active: bool) -> void:
	var style := get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.border_color = Color.WHITE if active else data.color


## Élan vers une position (globale) puis retour : animation d'attaque.
func lunge(toward: Vector2, distance: float = 28.0) -> void:
	_reset_lunge()
	var start := _home
	var direction := (toward - get_global_rect().get_center()).normalized()
	var tween := create_tween()
	_lunge_tween = tween
	tween.tween_property(self, "position", start - direction * 6.0, 0.08)
	tween.tween_property(self, "position", start + direction * distance, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", start, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Saut puis retombée lourde (coup écrasant).
func hop() -> void:
	_reset_lunge()
	var tween := create_tween()
	_lunge_tween = tween
	tween.tween_property(self, "position", _home + Vector2(0, -26), 0.14).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position", _home, 0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


## Lévitation courte (lanceur de sort).
func levitate() -> void:
	_reset_lunge()
	var tween := create_tween()
	_lunge_tween = tween
	tween.tween_property(self, "position", _home + Vector2(0, -12), 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", _home, 0.3).set_trans(Tween.TRANS_SINE)


## Tremblement (gros impact reçu).
func shake() -> void:
	_reset_lunge()
	var tween := create_tween()
	_lunge_tween = tween
	for i in 4:
		tween.tween_property(self, "position", _home + Vector2(6 if i % 2 == 0 else -6, 0), 0.04)
	tween.tween_property(self, "position", _home, 0.04)


func _reset_lunge() -> void:
	if _lunge_tween != null and _lunge_tween.is_valid():
		_lunge_tween.kill()
		position = _home
	else:
		_home = position


## Centre de la carte à l'écran (pour viser les effets).
func center() -> Vector2:
	return get_global_rect().get_center()


## Petite animation d'attaque.
func punch() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func take_damage(amount: int) -> void:
	current_hp = maxi(current_hp - amount, 0)
	_dead = current_hp <= 0
	_refresh()
	modulate = Color(1.0, 0.4, 0.4)
	var tween := create_tween()
	var target := Color(0.35, 0.35, 0.35) if _dead else Color.WHITE
	tween.tween_property(self, "modulate", target, 0.4)


func is_dead() -> bool:
	return _dead


# --- Drag & drop -------------------------------------------------------------

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable or slot == null or slot.locked:
		return null

	var preview := CardView.new()
	preview.setup(data, false)
	preview.modulate = Color(1, 1, 1, 0.85)
	var wrapper := Control.new()
	wrapper.add_child(preview)
	preview.position = -CARD_SIZE / 2.0
	set_drag_preview(wrapper)

	modulate = Color(1, 1, 1, 0.35)
	return {"card": self}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and not _dead:
		modulate = Color.WHITE


# Une carte posée dans un slot "bloque" les drops : on les transmet au slot.
func _can_drop_data(at_position: Vector2, drag_data: Variant) -> bool:
	return slot != null and slot._can_drop_data(at_position, drag_data)


func _drop_data(at_position: Vector2, drag_data: Variant) -> void:
	if slot != null:
		slot._drop_data(at_position, drag_data)
