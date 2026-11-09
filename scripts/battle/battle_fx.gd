class_name BattleFx
extends Control
## Calque d'effets visuels du combat (au-dessus de tout, ne capte pas la souris).
## Chaque effet est un petit nœud dessiné qui s'anime puis se supprime.
## Les positions sont globales (centre des cartes).

const GOLD := Color("ffd166")
const GREEN := Color("6fdc8c")
const PURPLE := Color("b57bff")


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20


## Entaille diagonale sur la cible. `size_factor` > 1 pour une compétence.
func slash(at: Vector2, color: Color = Color.WHITE, size_factor: float = 1.0, flip: bool = false) -> void:
	var fx := _FxNode.new(func(node: Control) -> void:
		var r := 34.0 * size_factor
		var a := Vector2(-r, -r) if not flip else Vector2(r, -r)
		var b := -a
		var t: float = node.get_meta("t", 0.0)
		var end := a.lerp(b, minf(t * 2.0, 1.0))
		node.draw_line(a, end, Color(color, 1.0 - t), 6.0 * size_factor, true)
		node.draw_line(a, end, Color(Color.WHITE, 1.0 - t), 2.0 * size_factor, true))
	_spawn(fx, at, 0.35)


## Onde de choc circulaire qui grandit (attaque de zone, compétence lancée).
func shockwave(at: Vector2, color: Color, max_radius: float = 90.0) -> void:
	var fx := _FxNode.new(func(node: Control) -> void:
		var t: float = node.get_meta("t", 0.0)
		node.draw_arc(Vector2.ZERO, 10.0 + max_radius * t, 0.0, TAU, 48, Color(color, 1.0 - t), 6.0 * (1.0 - t) + 1.0, true))
	_spawn(fx, at, 0.45)


## Explosion en étoile (impact d'une attaque de zone).
func burst(at: Vector2, color: Color) -> void:
	var fx := _FxNode.new(func(node: Control) -> void:
		var t: float = node.get_meta("t", 0.0)
		var points := PackedVector2Array()
		var r := 20.0 + 25.0 * t
		for i in 16:
			var angle := i * TAU / 16.0 + t
			points.append(Vector2(cos(angle), sin(angle)) * (r if i % 2 == 0 else r * 0.45))
		node.draw_colored_polygon(points, Color(color, 1.0 - t)))
	_spawn(fx, at, 0.4)


## Durée de vol des projectiles (le coup est affiché à l'arrivée).
const TRAVEL := 0.28


## Projectile simple (boule colorée) qui éclate à l'arrivée.
func projectile(from: Vector2, to: Vector2, color: Color, radius: float = 5.0) -> void:
	_fly(from, to, func(node: Control) -> void:
		node.draw_circle(Vector2.ZERO, radius * 1.8, Color(color, 0.4))
		node.draw_circle(Vector2.ZERO, radius, color),
		func() -> void: burst(to, color))


## Orbe magique scintillante + éclat en étoile.
func magic_orb(from: Vector2, to: Vector2, color: Color, size_factor: float = 1.0) -> void:
	var orb := _fly(from, to, func(node: Control) -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var r := 7.0 * size_factor
		node.draw_circle(Vector2.ZERO, r * 2.0, Color(color, 0.25))
		node.draw_circle(Vector2.ZERO, r, color.lightened(0.4))
		for i in 4:
			var angle := t * 9.0 + i * TAU / 4.0
			_star(node, Vector2(cos(angle), sin(angle)) * r * 2.2, 4.0 * size_factor, Color.WHITE),
		func() -> void: star_burst(to, color, size_factor))
	orb.set_process(true)


## Boule de feu (grosse, avec traînée) + explosion orange.
func fireball(from: Vector2, to: Vector2, size_factor: float = 1.0) -> void:
	var direction := (to - from).normalized()
	_fly(from, to, func(node: Control) -> void:
		var r := 11.0 * size_factor
		for i in 4:
			node.draw_circle(-direction * i * r * 0.7, r * (1.0 - i * 0.2), Color(Color("ff6b1a"), 0.7 - i * 0.15))
		node.draw_circle(Vector2.ZERO, r * 0.55, Color("ffe08a")),
		func() -> void:
			burst(to, Color("ff9f43"))
			shockwave(to, Color("ff6b1a"), 50.0 * size_factor))


## Flèche tirée en ligne droite + petite entaille à l'impact.
func arrow_shot(from: Vector2, to: Vector2, size_factor: float = 1.0) -> void:
	var angle := (to - from).angle()
	var arrow := _fly(from, to, func(node: Control) -> void:
		var l := 26.0 * size_factor
		node.draw_line(Vector2(-l, 0), Vector2(l * 0.6, 0), Color("e0c097"), 3.0, true)
		node.draw_colored_polygon(PackedVector2Array([
			Vector2(l, 0), Vector2(l * 0.5, -6), Vector2(l * 0.5, 6)]), Color("dfe6e9"))
		node.draw_line(Vector2(-l, 0), Vector2(-l - 6, -6), Color("27ae60"), 2.5, true)
		node.draw_line(Vector2(-l, 0), Vector2(-l - 6, 6), Color("27ae60"), 2.5, true),
		func() -> void: slash(to, Color("dfe6e9"), 0.6))
	arrow.rotation = angle


## Trois griffures parallèles.
func claws(at: Vector2, color: Color, size_factor: float = 1.0) -> void:
	var fx := _FxNode.new(func(node: Control) -> void:
		var t: float = node.get_meta("t", 0.0)
		var r := 30.0 * size_factor
		for i in 3:
			var offset := Vector2((i - 1) * 14.0 * size_factor, 0)
			var a := offset + Vector2(-r * 0.5, -r)
			var b := offset + Vector2(r * 0.5, r)
			node.draw_line(a, a.lerp(b, minf(t * 2.5, 1.0)), Color(color, 1.0 - t), 4.0 * size_factor, true))
	_spawn(fx, at, 0.4)


## Éclat en étoile (impact magique).
func star_burst(at: Vector2, color: Color, size_factor: float = 1.0) -> void:
	var fx := _FxNode.new(func(node: Control) -> void:
		var t: float = node.get_meta("t", 0.0)
		_star(node, Vector2.ZERO, (14.0 + 30.0 * t) * size_factor, Color(color.lightened(0.3), 1.0 - t))
		for i in 6:
			var angle := i * TAU / 6.0
			_star(node, Vector2(cos(angle), sin(angle)) * 40.0 * t * size_factor, 5.0, Color(Color.WHITE, 1.0 - t)))
	_spawn(fx, at, 0.45)


func _star(node: Control, pos: Vector2, s: float, color: Color) -> void:
	var w := s * 0.28
	node.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(0, -s), pos + Vector2(w, -w), pos + Vector2(s, 0), pos + Vector2(w, w),
		pos + Vector2(0, s), pos + Vector2(-w, w), pos + Vector2(-s, 0), pos + Vector2(-w, -w),
	]), color)


## Fait voler un nœud dessiné de `from` à `to`, puis appelle `on_arrive`.
func _fly(from: Vector2, to: Vector2, draw_fn: Callable, on_arrive: Callable) -> Control:
	var fx := _FxNode.new(draw_fn)
	add_child(fx)
	fx.position = from - global_position
	var tween := fx.create_tween()
	tween.tween_property(fx, "position", to - global_position, TRAVEL).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(on_arrive)
	tween.tween_callback(fx.queue_free)
	return fx


## Flèches qui montent (bonus) ou descendent (malus).
func arrows(at: Vector2, color: Color, up: bool = true) -> void:
	for i in 3:
		var fx := _FxNode.new(func(node: Control) -> void:
			var t: float = node.get_meta("t", 0.0)
			var s := 9.0
			var d := -1.0 if up else 1.0
			node.draw_colored_polygon(PackedVector2Array([
				Vector2(0, s * d), Vector2(s, 0), Vector2(-s, 0),
			]), Color(color, 1.0 - t))
			node.draw_rect(Rect2(-3, 0 if up else -s, 6, s), Color(color, 1.0 - t)))
		var start := at + Vector2((i - 1) * 26.0, 20.0 if up else -20.0)
		_spawn(fx, start, 0.6, Vector2(0, -40.0 if up else 40.0), i * 0.08)


## Petites croix vertes qui montent (soin).
func heal(at: Vector2) -> void:
	for i in 4:
		var fx := _FxNode.new(func(node: Control) -> void:
			var t: float = node.get_meta("t", 0.0)
			var c := Color(GREEN, 1.0 - t)
			node.draw_rect(Rect2(-2.5, -8, 5, 16), c)
			node.draw_rect(Rect2(-8, -2.5, 16, 5), c))
		var start := at + Vector2(randf_range(-35, 35), randf_range(0, 30))
		_spawn(fx, start, 0.7, Vector2(0, -45), i * 0.1)


func _spawn(fx: Control, at: Vector2, duration: float, move: Vector2 = Vector2.ZERO, delay: float = 0.0) -> void:
	add_child(fx)
	fx.position = at - global_position
	fx.visible = delay <= 0.0
	var tween := fx.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
		tween.tween_callback(func() -> void: fx.visible = true)
	tween.set_parallel()
	tween.tween_method(_set_progress.bind(fx), 0.0, 1.0, duration)
	if move != Vector2.ZERO:
		tween.tween_property(fx, "position", fx.position + move, duration)
	tween.chain().tween_callback(fx.queue_free)


func _set_progress(t: float, fx: Control) -> void:
	fx.set_meta("t", t)
	fx.queue_redraw()


## Nœud dont le dessin est une fonction (reçoit le nœud en paramètre).
class _FxNode extends Control:
	var _draw_fn: Callable

	func _init(draw_fn: Callable) -> void:
		_draw_fn = draw_fn
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		_draw_fn.call(self)
