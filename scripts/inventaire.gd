extends Control
## Scène « Inventaire » : présente la collection du joueur dans une grille
## de 4 colonnes × 5 lignes, avec une pagination pour parcourir les pages
## et une fiche détaillée de la carte sélectionnée.
##
## Navigation : boutons de pagination, molette sur la grille,
## touches Page préc. / Page suiv., Échap pour revenir au menu.

const COLUMNS := 4
const ROWS := 5
const SLOTS_PER_PAGE := COLUMNS * ROWS
## Nombre de pages affichées même si la collection est petite
## (capacité de départ : MIN_PAGES × SLOTS_PER_PAGE emplacements).
const MIN_PAGES := 5
## Nombre maximal de boutons de numéro de page visibles à la fois.
const MAX_PAGE_BUTTONS := 5

const MAIN_MENU_SCENE := "res://scenes/Main-menu.tscn"
const BACKGROUND_COLOR := Color("1b1e2b")
const PANEL_COLOR := Color(1, 1, 1, 0.05)
const ACCENT_COLOR := Color(0.35, 0.45, 0.75)

var current_page: int = 0

var _cards: Array[CharacterCardData] = []
var _slots: Array[InventorySlot] = []
var _slot_group := ButtonGroup.new()

var _grid: GridContainer
var _count_label: Label
var _page_label: Label
var _first_button: Button
var _prev_button: Button
var _next_button: Button
var _last_button: Button
var _page_numbers: HBoxContainer

var _detail_card: CardFace
var _detail_name: Label
var _detail_rarity: Label
var _detail_description: Label
var _detail_stats: GridContainer
var _detail_skills: VBoxContainer
var _detail_content: Control
var _detail_empty: Label


func _ready() -> void:
	_slot_group.allow_unpress = false
	_build_ui()
	PlayerCollection.collection_changed.connect(_on_collection_changed)
	_on_collection_changed()
	_select_first_card()


func page_count() -> int:
	var needed := ceili(float(_cards.size()) / SLOTS_PER_PAGE)
	return maxi(MIN_PAGES, needed)


func go_to_page(page: int) -> void:
	page = clampi(page, 0, page_count() - 1)
	var changed := page != current_page
	current_page = page
	_refresh_page()
	if changed:
		_show_detail(null)
		_grid.modulate.a = 0.0
		create_tween().tween_property(_grid, "modulate:a", 1.0, 0.15)


# --- Construction de l'interface ---------------------------------------------

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
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

	root.add_child(_build_header())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	body.add_child(_build_grid())
	body.add_child(_build_detail_panel())

	root.add_child(_build_pagination())


func _build_header() -> Control:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)

	var back := Button.new()
	back.text = "← Retour"
	back.custom_minimum_size = Vector2(120, 36)
	back.add_theme_font_size_override("font_size", 18)
	back.pressed.connect(_go_back)
	header.add_child(back)

	var title := _make_label("Inventaire", 28)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_count_label = _make_label("", 18)
	_count_label.custom_minimum_size = Vector2(120, 0)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_count_label)
	return header


func _build_grid() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(ACCENT_COLOR))
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	panel.gui_input.connect(_on_grid_input)

	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	panel.add_child(_grid)

	for i in SLOTS_PER_PAGE:
		var slot := InventorySlot.new()
		slot.button_group = _slot_group
		slot.card_selected.connect(_show_detail)
		slot.gui_input.connect(_on_grid_input)
		_grid.add_child(slot)
		_slots.append(slot)
	return panel


func _build_detail_panel() -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(1, 1, 1, 0.15)))

	_detail_empty = _make_label("Sélectionne une carte\npour voir ses détails.", 18)
	_detail_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_empty.modulate = Color(1, 1, 1, 0.5)
	panel.add_child(_detail_empty)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)
	_detail_content = row

	var ratio := AspectRatioContainer.new()
	ratio.ratio = CardFace.ASPECT
	ratio.custom_minimum_size = Vector2(250, 0)
	ratio.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(ratio)

	_detail_card = CardFace.new()
	ratio.add_child(_detail_card)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(scroll)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 10)
	scroll.add_child(info)

	_detail_name = _make_label("", 26)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_detail_name)

	_detail_rarity = _make_label("", 16)
	_detail_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_detail_rarity)

	_detail_description = _make_label("", 15)
	_detail_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description.modulate = Color(1, 1, 1, 0.75)
	info.add_child(_detail_description)

	info.add_child(HSeparator.new())

	_detail_stats = GridContainer.new()
	_detail_stats.columns = 4
	_detail_stats.add_theme_constant_override("h_separation", 10)
	_detail_stats.add_theme_constant_override("v_separation", 6)
	info.add_child(_detail_stats)

	info.add_child(HSeparator.new())

	_detail_skills = VBoxContainer.new()
	_detail_skills.add_theme_constant_override("separation", 8)
	info.add_child(_detail_skills)
	return panel


func _build_pagination() -> Control:
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 6)

	_first_button = _make_page_button("«", func() -> void: go_to_page(0))
	_first_button.tooltip_text = "Première page"
	bar.add_child(_first_button)
	_prev_button = _make_page_button("‹", func() -> void: go_to_page(current_page - 1))
	_prev_button.tooltip_text = "Page précédente"
	bar.add_child(_prev_button)

	_page_numbers = HBoxContainer.new()
	_page_numbers.add_theme_constant_override("separation", 6)
	bar.add_child(_page_numbers)

	_next_button = _make_page_button("›", func() -> void: go_to_page(current_page + 1))
	_next_button.tooltip_text = "Page suivante"
	bar.add_child(_next_button)
	_last_button = _make_page_button("»", func() -> void: go_to_page(page_count() - 1))
	_last_button.tooltip_text = "Dernière page"
	bar.add_child(_last_button)

	_page_label = _make_label("", 16)
	_page_label.custom_minimum_size = Vector2(110, 0)
	bar.add_child(_page_label)
	return bar


# --- Mise à jour -------------------------------------------------------------

func _on_collection_changed() -> void:
	_cards = PlayerCollection.get_cards()
	_count_label.text = "%d carte%s" % [_cards.size(), "" if _cards.size() <= 1 else "s"]
	current_page = clampi(current_page, 0, page_count() - 1)
	_refresh_page()


func _refresh_page() -> void:
	var start := current_page * SLOTS_PER_PAGE
	for i in SLOTS_PER_PAGE:
		var index := start + i
		_slots[i].set_card(_cards[index] if index < _cards.size() else null)
	_refresh_pagination()


func _refresh_pagination() -> void:
	var total := page_count()
	_page_label.text = "Page %d / %d" % [current_page + 1, total]
	_first_button.disabled = current_page == 0
	_prev_button.disabled = current_page == 0
	_next_button.disabled = current_page >= total - 1
	_last_button.disabled = current_page >= total - 1

	# Fenêtre de numéros centrée sur la page courante.
	for child in _page_numbers.get_children():
		child.queue_free()
	var visible_count := mini(MAX_PAGE_BUTTONS, total)
	var first := clampi(current_page - int(visible_count / 2.0), 0, total - visible_count)
	for page in range(first, first + visible_count):
		var button := _make_page_button(str(page + 1), go_to_page.bind(page))
		if page == current_page:
			button.disabled = true
			var style := _make_panel_style(ACCENT_COLOR)
			style.bg_color = ACCENT_COLOR
			style.set_content_margin_all(4)
			button.add_theme_stylebox_override("disabled", style)
			button.add_theme_color_override("font_disabled_color", Color.WHITE)
		_page_numbers.add_child(button)


func _select_first_card() -> void:
	if _slots[0].data != null:
		_slots[0].button_pressed = true
	else:
		_show_detail(null)


func _show_detail(data: CharacterCardData) -> void:
	_detail_empty.visible = data == null
	_detail_content.visible = data != null
	if data == null:
		var pressed := _slot_group.get_pressed_button()
		if pressed != null:
			pressed.set_pressed_no_signal(false)
		return

	_detail_card.set_card(data, false)
	_detail_name.text = data.display_name
	_detail_rarity.text = data.rarity_name()
	_detail_rarity.add_theme_color_override("font_color", data.rarity_color())
	_detail_description.text = data.description
	_detail_description.visible = not data.description.is_empty()

	for child in _detail_stats.get_children():
		child.queue_free()
	_add_stat_line(&"hp", "PV", data.hp)
	_add_stat_line(&"power", "Puissance", data.power)
	_add_stat_line(&"speed", "Vitesse", data.speed)
	_add_stat_line(&"defense", "Défense", data.defense)

	for child in _detail_skills.get_children():
		child.queue_free()
	_add_skill(data.skill_1_name, data.skill_1_description, data.skill_1_action, data.skill_1_cooldown)
	_add_skill(data.skill_2_name, data.skill_2_description, data.skill_2_action, data.skill_2_cooldown)


func _add_stat_line(stat: StringName, label_text: String, value: int) -> void:
	var icon := TextureRect.new()
	icon.texture = CardArt.icon(stat)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(28, 28)
	_detail_stats.add_child(icon)

	var label := _make_label("%s : %d" % [label_text, value], 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_stats.add_child(label)


func _add_skill(skill_name: String, description: String, action: int, cooldown: int) -> void:
	var action_names := ["Frappe", "Soin", "Renfort", "Immobilisation"]
	var header := "%s  ·  %s" % [skill_name, action_names[action]]
	if cooldown > 0:
		header += "  ·  recharge %d tour%s" % [cooldown, "" if cooldown == 1 else "s"]
	var title := _make_label(header, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_skills.add_child(title)

	if not description.is_empty():
		var text := _make_label(description, 14)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.modulate = Color(1, 1, 1, 0.7)
		_detail_skills.add_child(text)


# --- Entrées -----------------------------------------------------------------

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			go_to_page(current_page - 1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			go_to_page(current_page + 1)
			accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_page_up"):
		go_to_page(current_page - 1)
	elif event.is_action_pressed("ui_page_down"):
		go_to_page(current_page + 1)
	elif event.is_action_pressed("ui_cancel"):
		_go_back()
	else:
		return
	get_viewport().set_input_as_handled()


func _go_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# --- Utilitaires -------------------------------------------------------------

func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _make_page_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(36, 34)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(on_pressed)
	return button


func _make_panel_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	return style
