extends RefCounted
## Shared UI kit for Lantern Keeper. Everything is drawn onto a CanvasItem `c`
## (the main game node) so the project stays code-drawn and asset-free.
##
## Provides: palette, cached rounded StyleBoxes, fonts, text helpers with shadow,
## buttons with hover/pressed states, panels, bars, toggles and vector icons
## (stars, lanterns, motes, pause, speaker, lock) that never depend on font glyphs.

const GOLD := Color("#f4d98b")
const GOLD_DEEP := Color("#d9b96f")
const INK := Color("#0b1326")
const PANEL := Color(0.043, 0.075, 0.14, 0.95)
const TEXT := Color("#e6edf3")
const MUTED := Color("#93a9bd")
const MINT := Color("#65d6b0")
const DANGER := Color("#ed7c79")
const BORDER := Color(0.75, 0.85, 0.95, 0.22)

static var _font: Font
static var _bold: Font
static var _styles := {}


# ------------------------------------------------------------------ fonts
static func font(bold: bool = false) -> Font:
	if _font == null:
		var names := PackedStringArray(["Trebuchet MS", "Segoe UI", "Roboto", "Noto Sans", "DejaVu Sans", "Verdana", "Arial"])
		var regular := SystemFont.new()
		regular.font_names = names
		_font = regular
		var heavy := SystemFont.new()
		heavy.font_names = names
		heavy.font_weight = 700
		_bold = heavy
	return _bold if bold else _font


# ------------------------------------------------------------------ styles
static func style(kind: String) -> StyleBoxFlat:
	if _styles.has(kind):
		return _styles[kind]
	var s := StyleBoxFlat.new()
	s.anti_aliasing = true
	match kind:
		"panel":
			_fill(s, PANEL, BORDER, 18, 2)
			_shadow(s, 18)
		"card":
			_fill(s, Color("#16253d"), Color("#3d5878"), 16, 2)
			_shadow(s, 12)
		"card_hover":
			_fill(s, Color("#1d3250"), MINT, 16, 3)
			_shadow(s, 18)
		"card_locked":
			_fill(s, Color("#0f1727"), Color("#2c3a4f"), 16, 2)
		"btn":
			_fill(s, Color("#1b2a44"), GOLD_DEEP, 14, 2)
			_shadow(s, 6)
		"btn_hover":
			_fill(s, Color("#2a3f63"), GOLD, 14, 3)
			_shadow(s, 12)
		"btn_press":
			_fill(s, Color("#4a3d22"), GOLD, 14, 3)
		"btn_primary":
			_fill(s, Color("#3a3220"), GOLD, 14, 3)
			_shadow(s, 10)
		"btn_primary_hover":
			_fill(s, Color("#574a28"), Color("#fff1bd"), 14, 3)
			_shadow(s, 16)
		"btn_off":
			_fill(s, Color("#101827"), Color("#2c3a4f"), 14, 2)
		"chip":
			_fill(s, Color("#1b2c47"), Color("#3d5878"), 10, 2)
		"toast":
			_fill(s, Color(0.03, 0.06, 0.12, 0.94), BORDER, 14, 2)
			_shadow(s, 10)
		"bar_bg":
			_fill(s, Color("#1a2a40"), Color(1, 1, 1, 0.14), 9, 1)
		"pill_on":
			_fill(s, Color("#2f8f73"), MINT, 14, 2)
		"pill_off":
			_fill(s, Color("#2a3446"), Color("#56657a"), 14, 2)
	_styles[kind] = s
	return s


static func fill_style(col: Color) -> StyleBoxFlat:
	var key := "fill_" + col.to_html()
	if _styles.has(key):
		return _styles[key]
	var s := StyleBoxFlat.new()
	s.anti_aliasing = true
	s.bg_color = col
	s.set_corner_radius_all(9)
	_styles[key] = s
	return s


static func _fill(s: StyleBoxFlat, bg: Color, border: Color, radius: int, bw: int) -> void:
	s.bg_color = bg
	s.border_color = border
	s.set_corner_radius_all(radius)
	s.set_border_width_all(bw)


static func _shadow(s: StyleBoxFlat, size: int) -> void:
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = size
	s.shadow_offset = Vector2(0, 4)


static func box(c: CanvasItem, rect: Rect2, kind: String) -> void:
	c.draw_style_box(style(kind), rect)


# ------------------------------------------------------------------ text
static func text(c: CanvasItem, s: String, pos: Vector2, size: int, col: Color, align: int = 0, bold: bool = false, shadow: bool = true) -> void:
	## align: 0 left, 1 center, 2 right. `pos` is the baseline anchor.
	var f := font(bold)
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var p := pos
	if align == 1:
		p.x -= w * 0.5
	elif align == 2:
		p.x -= w
	if shadow:
		c.draw_string(f, p + Vector2(1, 2), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.55))
	c.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static func text_width(s: String, size: int, bold: bool = false) -> float:
	return font(bold).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func fit_size(s: String, max_w: float, size: int, min_size: int = 11, bold: bool = false) -> int:
	var sz := size
	while sz > min_size and text_width(s, sz, bold) > max_w:
		sz -= 1
	return sz


static func wrapped(c: CanvasItem, s: String, pos: Vector2, width: float, size: int, col: Color, align: int = 1, max_lines: int = -1) -> void:
	## Centered (or left) wrapped paragraph; `pos.x` is the left edge of the box.
	var a := HORIZONTAL_ALIGNMENT_CENTER if align == 1 else HORIZONTAL_ALIGNMENT_LEFT
	var f := font(false)
	c.draw_multiline_string(f, pos + Vector2(1, 2), s, a, width, size, max_lines, Color(0, 0, 0, 0.5))
	c.draw_multiline_string(f, pos, s, a, width, size, max_lines, col)


static func glow_title(c: CanvasItem, s: String, pos: Vector2, size: int, col: Color, t: float) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 1.6)
	# a faint warm underline-glow instead of a big disc
	var w := text_width(s, size, true)
	c.draw_line(pos + Vector2(-w * 0.5, 14), pos + Vector2(w * 0.5, 14), Color(col.r, col.g, col.b, 0.05 + 0.05 * pulse), 3.0)
	text(c, s, pos + Vector2(0, 3), size, Color(0, 0, 0, 0.5), 1, true, false)
	text(c, s, pos, size, col, 1, true, false)


static func divider(c: CanvasItem, cx: float, y: float, width: float, col: Color = GOLD_DEEP) -> void:
	c.draw_line(Vector2(cx - width * 0.5, y), Vector2(cx - 14, y), Color(col.r, col.g, col.b, 0.5), 2.0)
	c.draw_line(Vector2(cx + 14, y), Vector2(cx + width * 0.5, y), Color(col.r, col.g, col.b, 0.5), 2.0)
	c.draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 6), Vector2(cx + 6, y), Vector2(cx, y + 6), Vector2(cx - 6, y)]), col)


# ------------------------------------------------------------------ widgets
static func button(c: CanvasItem, rect: Rect2, label: String, hover: bool, down: bool, enabled: bool = true, size: int = 19, primary: bool = false, icon: String = "") -> void:
	var kind := "btn"
	if not enabled:
		kind = "btn_off"
	elif down:
		kind = "btn_press"
	elif primary:
		kind = "btn_primary_hover" if hover else "btn_primary"
	elif hover:
		kind = "btn_hover"
	var r := rect
	if hover and enabled and not down:
		r = Rect2(rect.position + Vector2(0, -2), rect.size)
	elif down:
		r = Rect2(rect.position + Vector2(0, 2), rect.size)
	box(c, r, kind)
	# soft top highlight
	if enabled:
		c.draw_line(r.position + Vector2(16, 4), Vector2(r.end.x - 16, r.position.y + 4), Color(1, 1, 1, 0.10), 2.0)
	var col := Color("#fff1bd") if (hover or primary) else Color("#f7e8bc")
	if not enabled:
		col = Color("#5b6a7e")
	var base := r.position.y + r.size.y * 0.5 + size * 0.36
	var cx := r.position.x + r.size.x * 0.5
	var tw := text_width(label, size, true)
	if icon != "":
		var gap := 30.0
		var start := cx - (tw + gap) * 0.5
		draw_icon(c, icon, Vector2(start + 10, r.position.y + r.size.y * 0.5), col)
		text(c, label, Vector2(start + gap, base), size, col, 0, true)
	else:
		text(c, label, Vector2(cx, base), size, col, 1, true)
	if hover and enabled:
		# little flame markers on both sides of a hovered button
		var my := r.position.y + r.size.y * 0.5
		_diamond(c, Vector2(r.position.x + 12, my), 4.0, GOLD)
		_diamond(c, Vector2(r.end.x - 12, my), 4.0, GOLD)


static func toggle_row(c: CanvasItem, rect: Rect2, label: String, on: bool, hover: bool, down: bool) -> void:
	button(c, rect, "", hover, down, true)
	var r := rect
	text(c, label, Vector2(rect.position.x + 24, r.position.y + r.size.y * 0.5 + 7), 18, Color("#f7e8bc"), 0, true)
	var pill := Rect2(rect.end.x - 104, rect.position.y + (rect.size.y - 28) * 0.5, 80, 28)
	box(c, pill, "pill_on" if on else "pill_off")
	var kx := pill.end.x - 16.0 if on else pill.position.x + 16.0
	c.draw_circle(Vector2(kx, pill.position.y + 14), 10.0, Color("#fff1bd") if on else Color("#9fb0c4"))
	text(c, "ON" if on else "OFF", Vector2(pill.position.x + (22 if on else 56), pill.position.y + 20), 12, Color("#e9fff6") if on else Color("#c5d1de"), 1, true, false)


static func bar(c: CanvasItem, rect: Rect2, ratio: float, col: Color) -> void:
	box(c, rect, "bar_bg")
	var w := maxf(0.0, (rect.size.x - 4.0) * clampf(ratio, 0.0, 1.0))
	if w > 1.0:
		c.draw_style_box(fill_style(col), Rect2(rect.position + Vector2(2, 2), Vector2(w, rect.size.y - 4.0)))
		c.draw_line(rect.position + Vector2(8, 4), rect.position + Vector2(maxf(8.0, w - 4.0), 4), Color(1, 1, 1, 0.28), 2.0)


static func segment_bar(c: CanvasItem, rect: Rect2, filled: int, total: int, col: Color) -> void:
	var gap := 6.0
	var w := (rect.size.x - gap * float(total - 1)) / float(total)
	for i in total:
		var r := Rect2(rect.position + Vector2((w + gap) * float(i), 0), Vector2(w, rect.size.y))
		if i < filled:
			c.draw_style_box(fill_style(col), r)
		else:
			c.draw_style_box(style("bar_bg"), r)


static func chip(c: CanvasItem, rect: Rect2, label: String, value: String, value_col: Color = GOLD) -> void:
	box(c, rect, "chip")
	text(c, label, Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 17), 11, MUTED, 1, true, false)
	text(c, value, Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y - 10), 18, value_col, 1, true)


# ------------------------------------------------------------------ icons
static func _diamond(c: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.7, 0), p + Vector2(0, r), p + Vector2(-r * 0.7, 0)]), col)


static func star(c: CanvasItem, p: Vector2, r: float, filled: bool, t: float = 0.0) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI * 0.5 + TAU * float(i) / 10.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(p + Vector2(cos(a), sin(a)) * rr)
	if filled:
		c.draw_colored_polygon(pts, GOLD)
		var ring := pts.duplicate()
		ring.append(pts[0])
		c.draw_polyline(ring, Color("#fff4c8"), 2.0)
	else:
		c.draw_colored_polygon(pts, Color("#1b2840"))
		var ring2 := pts.duplicate()
		ring2.append(pts[0])
		c.draw_polyline(ring2, Color("#3f526b"), 2.0)


static func lantern(c: CanvasItem, p: Vector2, lit: bool, t: float = 0.0, scale: float = 1.0) -> void:
	var s := scale
	var body := Color("#2b3552") if lit else Color("#1a2234")
	var edge := GOLD_DEEP if lit else Color("#3f4c63")
	if lit:
		c.draw_circle(p, 20.0 * s + sin(t * 4.0) * 1.2, Color(1.0, 0.75, 0.35, 0.06))
		c.draw_circle(p, 13.0 * s, Color(1.0, 0.8, 0.4, 0.10))
	c.draw_arc(p + Vector2(0, -10 * s), 5.5 * s, PI, TAU, 10, edge, 2.0)
	c.draw_rect(Rect2(p + Vector2(-6 * s, -9 * s), Vector2(12 * s, 3 * s)), edge)
	c.draw_rect(Rect2(p + Vector2(-7 * s, -6 * s), Vector2(14 * s, 14 * s)), body)
	c.draw_rect(Rect2(p + Vector2(-7 * s, -6 * s), Vector2(14 * s, 14 * s)), edge, false, 1.5)
	c.draw_rect(Rect2(p + Vector2(-6 * s, 8 * s), Vector2(12 * s, 3 * s)), edge)
	if lit:
		_diamond(c, p + Vector2(0, 1 * s), 5.0 * s, Color("#ffe9a0"))


static func mote(c: CanvasItem, p: Vector2, r: float, col: Color = Color("#f4f4d5")) -> void:
	c.draw_circle(p, r * 1.7, Color(col.r, col.g, col.b, 0.14))
	_diamond(c, p, r, col)


static func lock_icon(c: CanvasItem, p: Vector2, col: Color) -> void:
	c.draw_arc(p + Vector2(0, -6), 9.0, PI, TAU, 14, col, 3.0)
	c.draw_line(p + Vector2(-9, -6), p + Vector2(-9, 0), col, 3.0)
	c.draw_line(p + Vector2(9, -6), p + Vector2(9, 0), col, 3.0)
	c.draw_style_box(fill_style(col), Rect2(p + Vector2(-13, -2), Vector2(26, 20)))
	c.draw_circle(p + Vector2(0, 8), 3.0, Color("#0f1727"))


static func draw_icon(c: CanvasItem, kind: String, p: Vector2, col: Color) -> void:
	match kind:
		"pause":
			c.draw_rect(Rect2(p + Vector2(-7, -8), Vector2(5, 16)), col)
			c.draw_rect(Rect2(p + Vector2(2, -8), Vector2(5, 16)), col)
		"sound_on", "sound_off":
			c.draw_colored_polygon(PackedVector2Array([p + Vector2(-9, -4), p + Vector2(-4, -4), p + Vector2(2, -9), p + Vector2(2, 9), p + Vector2(-4, 4), p + Vector2(-9, 4)]), col)
			if kind == "sound_on":
				c.draw_arc(p + Vector2(2, 0), 6.0, -0.9, 0.9, 8, col, 2.0)
				c.draw_arc(p + Vector2(2, 0), 11.0, -0.9, 0.9, 10, col, 2.0)
			else:
				c.draw_line(p + Vector2(6, -6), p + Vector2(14, 6), DANGER, 2.5)
				c.draw_line(p + Vector2(14, -6), p + Vector2(6, 6), DANGER, 2.5)
