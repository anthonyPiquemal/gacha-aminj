class_name SkillButton
extends Button
## Indicateur rond de compétence, sous une carte du joueur (non cliquable :
## la compétence se lance toute seule dès qu'elle est rechargée).
## - icône dessinée selon le type de compétence (pas de texte) ;
## - en recharge : voile sombre en camembert + nombre d'actions restantes ;
## - prête : contour doré qui pulse + étincelles qui tournent, avec un
##   « pop » au moment où elle se débloque ;
## Le nom et la description sont dans l'infobulle.

const SIZE := 80.0
const GOLD := Color("ffd166")

var skill: CardSkills
var accent: Color = Color.WHITE
var cooldown_left: int = 0
var skill_ready: bool = false
## Vrai pendant le combat (sinon : aperçu sans recharge, non cliquable).
var active: bool = false

var _flash: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	pivot_offset = Vector2(SIZE, SIZE) / 2.0
	var empty := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, empty)
	set_process(false)


func set_state(p_skill: CardSkills, p_accent: Color, p_cooldown_left: int,
		p_ready: bool, p_active: bool) -> void:
	var became_ready := p_ready and not skill_ready and p_active
	skill = p_skill
	accent = p_accent
	cooldown_left = p_cooldown_left
	skill_ready = p_ready
	active = p_active
	disabled = true
	tooltip_text = _tooltip()
	set_process(active and skill_ready)
	if became_ready:
		_play_unlock()
	queue_redraw()


## Bouton vide (carte morte ou slot vide) : garde sa place dans la mise en page.
func clear() -> void:
	skill = null
	disabled = true
	tooltip_text = ""
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 2.0, 0.0)
	queue_redraw()


## « Pop » + flash quand la compétence se débloque.
func _play_unlock() -> void:
	_flash = 1.0
	scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


# --- Dessin ------------------------------------------------------------------

func _draw() -> void:
	if skill == null:
		return
	var center := size / 2.0
	var radius := SIZE / 2.0 - 6.0
	var t := Time.get_ticks_msec() / 1000.0

	# Halo doré pulsant quand prête.
	if active and skill_ready:
		var pulse := 0.5 + 0.5 * sin(t * 5.0)
		draw_circle(center, radius + 5.0 + pulse * 2.0, Color(GOLD, 0.18 + 0.2 * pulse + _flash * 0.5))

	# Fond et icône.
	draw_circle(center, radius, accent.darkened(0.55))
	draw_circle(center, radius - 3.0, accent.darkened(0.35))
	_draw_icon(center, radius * 0.55, Color.WHITE)

	# Recharge : voile en camembert + nombre.
	if active and not skill_ready and skill.cooldown > 0:
		var ratio := clampf(float(cooldown_left) / skill.cooldown, 0.0, 1.0)
		_draw_pie(center, radius, ratio, Color(0, 0, 0, 0.6))
		var font := get_theme_default_font()
		var text := str(cooldown_left)
		var font_size := 26
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var pos := center + Vector2(-text_size.x / 2.0, font_size * 0.35)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color.BLACK)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

	# Contour.
	var ring := Color(1, 1, 1, 0.25)
	if active and skill_ready:
		ring = GOLD.lerp(Color.WHITE, _flash)
	draw_arc(center, radius, 0.0, TAU, 48, ring, 3.0 if skill_ready and active else 2.0, true)

	if active and skill_ready:
		_draw_sparkles(center, radius, t)


func _draw_pie(center: Vector2, radius: float, ratio: float, color: Color) -> void:
	if ratio <= 0.0:
		return
	var points := PackedVector2Array([center])
	var steps := maxi(3, int(40 * ratio))
	for i in steps + 1:
		var angle := -PI / 2.0 + TAU * ratio * float(i) / steps
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)


## Étincelles en étoile à 4 branches qui tournent autour du bouton.
func _draw_sparkles(center: Vector2, radius: float, t: float) -> void:
	for i in 4:
		var angle := t * 1.6 + i * TAU / 4.0
		var twinkle := 0.5 + 0.5 * sin(t * 7.0 + i * 1.7)
		var pos := center + Vector2(cos(angle), sin(angle)) * (radius + 3.0)
		_draw_star(pos, 3.0 + 4.0 * twinkle + _flash * 4.0, Color(Color.WHITE.lerp(GOLD, 0.4), 0.5 + 0.5 * twinkle))


func _draw_star(pos: Vector2, s: float, color: Color) -> void:
	var w := s * 0.28
	draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -s), pos + Vector2(w, -w), pos + Vector2(s, 0), pos + Vector2(w, w),
		pos + Vector2(0, s), pos + Vector2(-w, w), pos + Vector2(-s, 0), pos + Vector2(-w, -w),
	]), color)


## Icône selon le type de compétence.
func _draw_icon(c: Vector2, r: float, color: Color) -> void:
	if skill is SkillAttack:
		var attack := skill as SkillAttack
		if attack.target_all:
			_draw_burst(c, r, color)
		elif attack.hits > 1:
			_draw_sword(c, r, color, -1.0)
			_draw_sword(c, r, color, 1.0)
		else:
			_draw_sword(c, r, color, 1.0)
	elif skill is SkillSupport:
		var support := skill as SkillSupport
		if support.stat == SkillSupport.Stat.HEALTH:
			if support.is_debuff():
				_draw_drop(c, r, Color("b4ff7a"))
			else:
				_draw_cross(c, r, Color("6fdc8c"))
		else:
			_draw_arrow(c, r, GOLD if not support.is_debuff() else Color("ff7b7b"), support.is_debuff())
		if support.target_all:
			draw_arc(c, r * 1.25, 0.0, TAU, 32, Color(color, 0.35), 1.5, true)
	else:
		draw_circle(c, r * 0.4, color)


## Épée en diagonale ; dir = 1 (pointe en haut à droite) ou -1 (en haut à gauche).
func _draw_sword(c: Vector2, r: float, color: Color, dir: float) -> void:
	var tip := c + Vector2(r * dir, -r)
	var hilt := c + Vector2(-r * 0.45 * dir, r * 0.45)
	var pommel := c + Vector2(-r * 0.8 * dir, r * 0.8)
	draw_line(hilt, tip, color, 4.0, true)
	var axis := (tip - hilt).normalized()
	var normal := Vector2(-axis.y, axis.x)
	draw_line(hilt + normal * r * 0.35, hilt - normal * r * 0.35, color, 3.5, true)
	draw_line(hilt, pommel, color.darkened(0.2), 3.0, true)


## Explosion (attaque de zone).
func _draw_burst(c: Vector2, r: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 16:
		var angle := -PI / 2.0 + i * TAU / 16.0
		var dist := r if i % 2 == 0 else r * 0.45
		points.append(c + Vector2(cos(angle), sin(angle)) * dist)
	draw_colored_polygon(points, Color("ff9f43"))
	draw_circle(c, r * 0.3, color)


func _draw_arrow(c: Vector2, r: float, color: Color, down: bool) -> void:
	var s := -1.0 if down else 1.0
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -r * s), c + Vector2(r * 0.8, -r * 0.1 * s), c + Vector2(r * 0.3, -r * 0.1 * s),
		c + Vector2(r * 0.3, r * s), c + Vector2(-r * 0.3, r * s), c + Vector2(-r * 0.3, -r * 0.1 * s),
		c + Vector2(-r * 0.8, -r * 0.1 * s),
	]), color)


func _draw_cross(c: Vector2, r: float, color: Color) -> void:
	var w := r * 0.32
	draw_rect(Rect2(c.x - w, c.y - r, w * 2.0, r * 2.0), color)
	draw_rect(Rect2(c.x - r, c.y - w, r * 2.0, w * 2.0), color)


func _draw_drop(c: Vector2, r: float, color: Color) -> void:
	draw_circle(c + Vector2(0, r * 0.3), r * 0.6, color)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r * 0.55, r * 0.15), c + Vector2(-r * 0.55, r * 0.15),
	]), color)


func _tooltip() -> String:
	if skill == null:
		return ""
	var text := skill.skill_name
	if not active:
		return "%s — recharge %d action(s)" % [text, skill.cooldown]
	if skill_ready:
		return "%s — prête ! Elle part à la prochaine action" % text
	return "%s — encore %d action(s)" % [text, cooldown_left]
