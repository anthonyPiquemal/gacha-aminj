class_name CardView
extends PanelContainer
## Représentation visuelle d'une carte.
## Si `draggable` est vrai, elle peut être glissée vers un CardSlot.

const CARD_SIZE := Vector2(100, 136)

var data: CardData
var current_hp: int = 0
var draggable: bool = false
var slot: CardSlot = null

var _hp_label: Label
var _dead: bool = false


func setup(p_data: CardData, p_draggable: bool) -> void:
	data = p_data
	current_hp = data.health
	draggable = p_draggable

	custom_minimum_size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0
	if draggable:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.17, 0.23)
	style.set_border_width_all(3)
	style.border_color = data.color
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	var name_label := Label.new()
	name_label.text = data.card_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
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

	var atk_label := Label.new()
	atk_label.text = "ATQ %d" % data.attack
	atk_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atk_label.add_theme_font_size_override("font_size", 13)
	atk_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_child(atk_label)

	_hp_label = Label.new()
	_hp_label.add_theme_font_size_override("font_size", 13)
	_hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_child(_hp_label)
	_refresh()


func _refresh() -> void:
	_hp_label.text = "PV %d" % current_hp


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
