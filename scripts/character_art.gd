extends RefCounted

# Draws a larger, layered adventurer so the player remains readable against scenery.
static func draw_player(canvas: CanvasItem, pos: Vector2, moving: bool, anim_time: float, damaged: bool, shielded: bool) -> void:
    var bob := sin(anim_time * (11.0 if moving else 2.2)) * (3.5 if moving else 1.5)
    var lean := 2.5 * sin(anim_time * 11.0) if moving else 0.0
    var body_pos := pos + Vector2(0, bob)
    var flicker := int(anim_time * 12.0) % 2 == 0
    var cloak := Color("#d8e7d5") if not damaged or flicker else Color("#f08b91")
    if shielded:
        canvas.draw_circle(pos, 35, Color("#b99aff", 0.08))
        canvas.draw_arc(pos, 35, 0, TAU, 48, Color("#b99aff", 0.82), 3.0)
    canvas.draw_circle(pos + Vector2(0, 5), 24, Color(0.01, 0.02, 0.04, 0.38))
    # Feet and boots.
    var step := sin(anim_time * 11.0) * (6.0 if moving else 0.0)
    canvas.draw_line(body_pos + Vector2(-7, 13), body_pos + Vector2(-10 - step, 24), Color("#263044"), 8.0)
    canvas.draw_line(body_pos + Vector2(7, 13), body_pos + Vector2(10 + step, 24), Color("#263044"), 8.0)
    canvas.draw_line(body_pos + Vector2(-10 - step, 24), body_pos + Vector2(-3 - step, 24), Color("#b68b62"), 5.0)
    canvas.draw_line(body_pos + Vector2(10 + step, 24), body_pos + Vector2(17 + step, 24), Color("#b68b62"), 5.0)
    # Cloak silhouette with dark outline and inner fabric.
    var silhouette := PackedVector2Array([body_pos + Vector2(lean, -20), body_pos + Vector2(19 + lean, -3), body_pos + Vector2(14, 20), body_pos + Vector2(-14, 20), body_pos + Vector2(-19 + lean, -3)])
    canvas.draw_colored_polygon(silhouette, Color("#26364a"))
    var fabric := PackedVector2Array([body_pos + Vector2(lean, -17), body_pos + Vector2(15 + lean, -2), body_pos + Vector2(11, 16), body_pos + Vector2(-11, 16), body_pos + Vector2(-15 + lean, -2)])
    canvas.draw_colored_polygon(fabric, cloak)
    canvas.draw_line(body_pos + Vector2(-8, 1), body_pos + Vector2(-5, 14), Color("#8aa99b"), 2.0)
    canvas.draw_line(body_pos + Vector2(7, 1), body_pos + Vector2(5, 14), Color("#8aa99b"), 2.0)
    # Hood and face.
    canvas.draw_circle(body_pos + Vector2(0, -12), 12, Color("#314b56"))
    canvas.draw_circle(body_pos + Vector2(1, -10), 8, Color("#d9b58c"))
    canvas.draw_arc(body_pos + Vector2(0, -13), 12, PI, TAU, 24, Color("#1e3544"), 5.0)
    canvas.draw_circle(body_pos + Vector2(4, -10), 1.5, Color("#172338"))
    # Lantern with handle and warm glow.
    var lantern := body_pos + Vector2(22, -13)
    canvas.draw_circle(lantern, 18 + sin(anim_time * 4.0) * 2.0, Color("#f5d47a", 0.13))
    canvas.draw_rect(Rect2(lantern + Vector2(-5, -6), Vector2(10, 14)), Color("#9a7044"))
    canvas.draw_rect(Rect2(lantern + Vector2(-3, -4), Vector2(6, 10)), Color("#ffe49a"))
    canvas.draw_arc(lantern + Vector2(0, -6), 5, PI, TAU, 16, Color("#e6c27b"), 2.0)
