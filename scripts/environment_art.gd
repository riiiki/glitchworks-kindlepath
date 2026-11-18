extends RefCounted

# Reusable procedural environment renderer. All coordinates use the 1280x720 game canvas.
static func draw_environment(canvas: CanvasItem, level_index: int, world: Rect2, accent: Color, phase: float) -> void:
    var palettes := [
        {"ground": Color("#183d3c"), "path": Color("#8a8060"), "tree": Color("#102b2c"), "leaf": Color("#286052"), "stone": Color("#536d68")},
        {"ground": Color("#1b3850"), "path": Color("#527080"), "tree": Color("#142b42"), "leaf": Color("#286078"), "stone": Color("#617d91")},
        {"ground": Color("#373452"), "path": Color("#82745f"), "tree": Color("#24243d"), "leaf": Color("#51496d"), "stone": Color("#77718b")}
    ]
    var p: Dictionary = palettes[clampi(level_index, 0, 2)]
    canvas.draw_rect(world, p.ground)
    # Subtle ground texture and a winding path connecting the start and beacon.
    for i in range(26):
        var x := 62.0 + float((i * 97) % 1140)
        var y := 125.0 + float((i * 137) % 520)
        canvas.draw_circle(Vector2(x, y), 2.0 + float(i % 3), Color(0.82, 0.88, 0.84, 0.055))
    var path_points := PackedVector2Array([Vector2(95, 600), Vector2(250, 545), Vector2(420, 575), Vector2(575, 430), Vector2(760, 420), Vector2(900, 290), Vector2(1090, 170)])
    if level_index == 1:
        path_points = PackedVector2Array([Vector2(110, 170), Vector2(280, 220), Vector2(430, 360), Vector2(590, 520), Vector2(780, 470), Vector2(950, 420), Vector2(1100, 570)])
    elif level_index == 2:
        path_points = PackedVector2Array([Vector2(105, 570), Vector2(270, 520), Vector2(440, 370), Vector2(610, 410), Vector2(780, 300), Vector2(930, 240), Vector2(1110, 160)])
    for i in range(path_points.size() - 1):
        canvas.draw_line(path_points[i], path_points[i + 1], Color(p.path, 0.25), 42.0, true)
        canvas.draw_line(path_points[i], path_points[i + 1], Color(p.path, 0.12), 30.0, true)
    # Deterministic tree clusters at the edges and in safe clearings.
    var trees := [Vector2(105,150), Vector2(175,250), Vector2(120,440), Vector2(355,150), Vector2(430,640), Vector2(700,150), Vector2(790,630), Vector2(1010,130), Vector2(1170,300), Vector2(1160,625), Vector2(300,650), Vector2(900,650)]
    for i in range(trees.size()):
        var pos: Vector2 = trees[i] + Vector2(sin(phase * 0.45 + i) * 2.0, 0)
        var radius := 20.0 + float(i % 4) * 4.0
        canvas.draw_rect(Rect2(pos + Vector2(-5, 7), Vector2(10, 24)), Color("#493d35"))
        canvas.draw_circle(pos, radius + 7.0, Color(p.tree, 0.85))
        canvas.draw_circle(pos + Vector2(-5, -5), radius * 0.72, p.leaf)
        canvas.draw_circle(pos + Vector2(8, 4), radius * 0.58, p.leaf.lightened(0.12))
        canvas.draw_circle(pos + Vector2(-7, -9), 4.0, Color(accent, 0.18))
    # Rocks, grass tufts, and small flowers.
    for i in range(24):
        var pos := Vector2(75.0 + float((i * 181) % 1120), 125.0 + float((i * 113) % 530))
        if i % 3 == 0:
            canvas.draw_colored_polygon(PackedVector2Array([pos + Vector2(-12, 7), pos + Vector2(-5, -7), pos + Vector2(9, -10), pos + Vector2(15, 5), pos + Vector2(3, 11)]), p.stone.darkened(0.12))
            canvas.draw_line(pos + Vector2(-5, -4), pos + Vector2(7, -6), Color(1, 1, 1, 0.16), 2.0)
        else:
            canvas.draw_line(pos, pos + Vector2(-5, -10), Color("#8bb58b", 0.48), 2.0)
            canvas.draw_line(pos, pos + Vector2(4, -12), Color("#8bb58b", 0.42), 2.0)
            if i % 4 == 0:
                canvas.draw_circle(pos + Vector2(0, -12), 3.0, accent.lightened(0.15))
    # Broken ruin pillars and arch fragments, placed away from core navigation.
    var ruins := [Vector2(300, 245), Vector2(965, 520), Vector2(610, 145)]
    if level_index == 1:
        ruins = [Vector2(300, 520), Vector2(720, 220), Vector2(1000, 210)]
    elif level_index == 2:
        ruins = [Vector2(320, 190), Vector2(650, 610), Vector2(1000, 450)]
    for i in range(ruins.size()):
        var r: Vector2 = ruins[i]
        canvas.draw_rect(Rect2(r + Vector2(-18, -24), Vector2(36, 48)), p.stone.darkened(0.18))
        canvas.draw_rect(Rect2(r + Vector2(-23, -29), Vector2(46, 9)), p.stone.lightened(0.14))
        canvas.draw_rect(Rect2(r + Vector2(-13, -16), Vector2(5, 31)), Color(1, 1, 1, 0.12))
        if i == 0:
            canvas.draw_arc(r + Vector2(0, -28), 30, PI, TAU, 24, p.stone, 7.0)
