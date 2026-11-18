extends Node2D

const PLAYER_SPEED := 250.0
const WORLD_RECT := Rect2(40, 105, 1200, 575)
const LEVELS := [
    {
        "name": "THE QUIET GROVE",
        "subtitle": "The first flame has gone out.",
        "goal": "Find 3 light motes, then relight the ancient beacon.",
        "player": Vector2(115, 585),
        "beacon": Vector2(1090, 170),
        "motes": [Vector2(340, 520), Vector2(625, 335), Vector2(950, 530)],
        "walls": [Rect2(270, 120, 54, 300), Rect2(485, 390, 260, 48), Rect2(820, 170, 50, 240)],
        "hazards": [Vector2(525, 560)],
        "color": Color("#163b45"),
        "accent": Color("#65d6b0")
    },
    {
        "name": "THE SUNKEN ARCHIVE",
        "subtitle": "Old memories drift beneath the water.",
        "goal": "Gather 4 motes and avoid the roaming wisp.",
        "player": Vector2(110, 170),
        "beacon": Vector2(1100, 570),
        "motes": [Vector2(330, 170), Vector2(590, 520), Vector2(850, 180), Vector2(1050, 360)],
        "walls": [Rect2(205, 280, 360, 45), Rect2(660, 120, 48, 300), Rect2(850, 440, 250, 45)],
        "hazards": [Vector2(500, 160), Vector2(780, 565)],
        "color": Color("#18334f"),
        "accent": Color("#71c9ee")
    },
    {
        "name": "THE LAST SUMMIT",
        "subtitle": "Carry the light to the edge of the world.",
        "goal": "Collect 5 motes and awaken the final beacon.",
        "player": Vector2(105, 570),
        "beacon": Vector2(1110, 160),
        "motes": [Vector2(300, 560), Vector2(470, 180), Vector2(690, 500), Vector2(900, 210), Vector2(1080, 510)],
        "walls": [Rect2(220, 340, 250, 45), Rect2(555, 120, 48, 300), Rect2(730, 380, 250, 45), Rect2(1000, 250, 48, 160)],
        "hazards": [Vector2(430, 600), Vector2(800, 300), Vector2(1010, 600)],
        "color": Color("#302b52"),
        "accent": Color("#f6c96b")
    }
]

var level_index := 0
var player_pos := Vector2.ZERO
var beacon_pos := Vector2.ZERO
var motes: Array[Vector2] = []
var walls: Array[Rect2] = []
var hazards: Array[Vector2] = []
var collected := 0
var total_motes := 0
var lives := 3
var state := "menu"
var move_vector := Vector2.ZERO
var touch_vector := Vector2.ZERO
var touch_active := false
var interact_requested := false
var hazard_phase := 0.0
var message := ""
var message_timer := 0.0
var best_time := 0.0
var level_time := 0.0
var total_time := 0.0
var sound_on := true
var buttons := {}
var font: Font

func _ready() -> void:
    font = ThemeDB.fallback_font
    set_process(true)
    set_process_input(true)
    _make_ui_buttons()

func _make_ui_buttons() -> void:
    buttons = {
        "start": Rect2(490, 405, 300, 68),
        "next": Rect2(490, 470, 300, 64),
        "retry": Rect2(490, 550, 300, 54),
        "menu": Rect2(25, 25, 110, 42),
        "sound": Rect2(1140, 25, 110, 42)
    }

func _start_game() -> void:
    level_index = 0
    lives = 3
    total_time = 0.0
    _load_level(0)
    state = "playing"
    _say("The lantern remembers the way.", 2.2)

func _load_level(index: int) -> void:
    level_index = index
    var data: Dictionary = LEVELS[level_index]
    player_pos = data.player
    beacon_pos = data.beacon
    motes.assign(data.motes)
    total_motes = motes.size()
    collected = 0
    walls.assign(data.walls)
    hazards.assign(data.hazards)
    level_time = 0.0
    hazard_phase = 0.0

func _process(delta: float) -> void:
    if message_timer > 0.0:
        message_timer -= delta
    if state == "playing":
        level_time += delta
        total_time += delta
        hazard_phase += delta
        _update_player(delta)
        _update_hazards(delta)
        _check_collectibles()
        if interact_requested:
            _try_beacon()
        interact_requested = false
    queue_redraw()

func _update_player(delta: float) -> void:
    var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var direction := keyboard
    if touch_active:
        direction = touch_vector
    if direction.length() > 1.0:
        direction = direction.normalized()
    var next_pos := player_pos + direction * PLAYER_SPEED * delta
    next_pos.x = clamp(next_pos.x, WORLD_RECT.position.x + 20, WORLD_RECT.end.x - 20)
    next_pos.y = clamp(next_pos.y, WORLD_RECT.position.y + 20, WORLD_RECT.end.y - 20)
    var player_rect := Rect2(next_pos - Vector2(15, 15), Vector2(30, 30))
    for wall in walls:
        if player_rect.intersects(wall):
            if not Rect2(Vector2(player_pos.x - 15, next_pos.y - 15), Vector2(30, 30)).intersects(wall):
                next_pos.y = player_pos.y
            elif not Rect2(Vector2(next_pos.x - 15, player_pos.y - 15), Vector2(30, 30)).intersects(wall):
                next_pos.x = player_pos.x
            else:
                next_pos = player_pos
    player_pos = next_pos

func _update_hazards(_delta: float) -> void:
    for i in range(hazards.size()):
        var base: Vector2 = LEVELS[level_index].hazards[i]
        hazards[i] = base + Vector2(sin(hazard_phase * (0.8 + i * 0.12) + i) * 38.0, cos(hazard_phase * 0.9 + i) * 22.0)
        if player_pos.distance_to(hazards[i]) < 30.0:
            _hit_hazard()

func _hit_hazard() -> void:
    lives -= 1
    player_pos = LEVELS[level_index].player
    _say("A shadow brushed your lantern. Be careful!", 2.0)
    if lives <= 0:
        state = "game_over"

func _check_collectibles() -> void:
    for i in range(motes.size() - 1, -1, -1):
        if player_pos.distance_to(motes[i]) < 30.0:
            motes.remove_at(i)
            collected += 1
            _say("Light mote collected!  " + str(collected) + "/" + str(total_motes), 1.2)

func _try_beacon() -> void:
    if player_pos.distance_to(beacon_pos) > 78.0:
        _say("Move closer to the beacon.", 1.3)
        return
    if collected < total_motes:
        _say("The beacon needs more light: " + str(total_motes - collected) + " mote(s) remaining.", 1.8)
        return
    if level_index < LEVELS.size() - 1:
        state = "level_complete"
    else:
        state = "victory"

func _say(text_value: String, duration: float) -> void:
    message = text_value
    message_timer = duration

func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_E or event.keycode == KEY_SPACE:
            interact_requested = true
        if event.keycode == KEY_ESCAPE:
            if state == "playing":
                state = "paused"
            elif state == "paused":
                state = "playing"
    if event is InputEventScreenTouch:
        if event.pressed:
            if _handle_ui_click(event.position):
                return
            if event.position.x < 360 and event.position.y > 390 and state == "playing":
                touch_active = true
                touch_vector = _touch_direction(event.position)
            elif state == "playing" and event.position.x > 850 and event.position.y > 500:
                interact_requested = true
        else:
            touch_active = false
            touch_vector = Vector2.ZERO
    if event is InputEventScreenDrag and touch_active:
        touch_vector = _touch_direction(event.position)
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        _handle_ui_click(event.position)
        if state == "playing" and event.position.x > 850 and event.position.y > 500:
            interact_requested = true

func _touch_direction(point: Vector2) -> Vector2:
    var center := Vector2(165, 575)
    var v := point - center
    if v.length() < 18.0:
        return Vector2.ZERO
    return v.normalized()

func _handle_ui_click(point: Vector2) -> bool:
    if state == "menu" and buttons.start.has_point(point):
        _start_game()
        return true
    if state == "level_complete" and buttons.next.has_point(point):
        _load_level(level_index + 1)
        state = "playing"
        _say("A new path opens...", 1.5)
        return true
    if (state == "game_over" or state == "victory") and buttons.retry.has_point(point):
        _start_game()
        return true
    if state == "paused" and buttons.start.has_point(point):
        state = "playing"
        return true
    if state == "playing" and buttons.menu.has_point(point):
        state = "paused"
        return true
    if buttons.sound.has_point(point):
        sound_on = not sound_on
        return true
    return false

func _draw() -> void:
    _draw_background()
    if state == "menu":
        _draw_menu()
        return
    _draw_world()
    _draw_hud()
    if state == "paused":
        _draw_overlay("PAUSED", "Take a breath. Your lantern is safe.", "Tap RESUME or press ESC")
        _draw_button(buttons.start, "RESUME")
    elif state == "level_complete":
        _draw_overlay("BEACON RESTORED", "The darkness retreats. A new region awakens.", "Level " + str(level_index + 1) + " complete")
        _draw_button(buttons.next, "NEXT REGION")
    elif state == "game_over":
        _draw_overlay("LIGHT FADING", "The shadows overwhelmed your lantern.", "You can try the journey again.")
        _draw_button(buttons.retry, "TRY AGAIN")
    elif state == "victory":
        _draw_overlay("THE WORLD REMEMBERS", "You restored the last light. The night is no longer endless.", "Journey time: " + _format_time(total_time))
        _draw_button(buttons.retry, "PLAY AGAIN")
    if message_timer > 0.0 and state == "playing":
        _draw_panel(Rect2(330, 92, 620, 44), Color(0.02, 0.04, 0.08, 0.88))
        _center_text(message, Vector2(640, 121), 17, Color("#f2f4e9"))

func _draw_background() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#090e20"))
    for i in range(90):
        var x := float((i * 173) % 1280)
        var y := float((i * 97) % 720)
        var alpha := 0.18 + 0.12 * sin(Time.get_ticks_msec() / 900.0 + i)
        draw_circle(Vector2(x, y), 1.4, Color(0.75, 0.84, 1.0, alpha))
    var glow := Color("#1a2944")
    draw_circle(Vector2(1080, 80), 95, Color(glow, 0.35))

func _draw_menu() -> void:
    _center_text("LANTERN KEEPER", Vector2(640, 205), 58, Color("#f4d98b"))
    _center_text("A LIGHT IN THE DARK", Vector2(640, 250), 18, Color("#8db9bd"))
    draw_circle(Vector2(640, 345), 58, Color("#f4c96b", 0.12))
    draw_circle(Vector2(640, 345), 35, Color("#f4c96b", 0.24))
    draw_colored_polygon(PackedVector2Array([Vector2(628, 360), Vector2(652, 360), Vector2(646, 320), Vector2(634, 320)]), Color("#f4d98b"))
    _draw_button(buttons.start, "BEGIN JOURNEY")
    _center_text("WASD / ARROW KEYS to move  •  E / SPACE to awaken beacons", Vector2(640, 520), 16, Color("#a7b7c9"))
    _center_text("Touch: hold the left side to move, tap the right action area to interact", Vector2(640, 552), 14, Color("#778ca8"))
    _center_text("Collect every light mote. Avoid wandering shadows. Reach each beacon.", Vector2(640, 605), 16, Color("#c4d0d8"))

func _draw_world() -> void:
    var data: Dictionary = LEVELS[level_index]
    draw_rect(WORLD_RECT, data.color)
    for i in range(18):
        var xx := 70 + i * 66
        draw_line(Vector2(xx, 110), Vector2(xx - 40, 680), Color(1, 1, 1, 0.035), 1.0)
    for wall in walls:
        draw_rect(wall, Color("#0b172b"))
        draw_rect(Rect2(wall.position, Vector2(wall.size.x, 5)), data.accent.darkened(0.25))
    for mote in motes:
        draw_circle(mote, 20, Color(data.accent, 0.12))
        draw_circle(mote, 10, data.accent)
        draw_colored_polygon(PackedVector2Array([mote + Vector2(0, -15), mote + Vector2(9, 0), mote + Vector2(0, 15), mote + Vector2(-9, 0)]), Color("#f4f4d5"))
    for hazard in hazards:
        draw_circle(hazard, 24, Color("#e56d82", 0.16))
        draw_colored_polygon(PackedVector2Array([hazard + Vector2(0, -19), hazard + Vector2(17, -2), hazard + Vector2(8, 18), hazard + Vector2(-12, 18), hazard + Vector2(-18, -2)]), Color("#a94e75"))
        draw_circle(hazard + Vector2(-5, -2), 3, Color("#ffe4bc"))
        draw_circle(hazard + Vector2(6, -2), 3, Color("#ffe4bc"))
    draw_circle(beacon_pos, 64, Color(data.accent, 0.10))
    draw_circle(beacon_pos, 39, Color(data.accent, 0.18))
    draw_arc(beacon_pos, 30, 0, TAU, 48, data.accent, 4.0)
    draw_rect(Rect2(beacon_pos.x - 9, beacon_pos.y - 30, 18, 60), Color("#e7d9a0"))
    draw_circle(beacon_pos + Vector2(0, -27), 10, Color("#fff2b0"))
    # Player lantern glow and geometric character
    draw_circle(player_pos, 88, Color("#f5d47a", 0.075))
    draw_circle(player_pos, 48, Color("#f5d47a", 0.10))
    draw_colored_polygon(PackedVector2Array([player_pos + Vector2(0, -22), player_pos + Vector2(17, -4), player_pos + Vector2(12, 19), player_pos + Vector2(-12, 19), player_pos + Vector2(-17, -4)]), Color("#e8e4d8"))
    draw_circle(player_pos + Vector2(0, -7), 5, Color("#172338"))
    draw_circle(player_pos + Vector2(16, -15), 7, Color("#f5d47a"))
    _draw_mobile_controls()
    _center_text(data.name, Vector2(640, 83), 22, Color("#e8edf1"))
    _center_text(data.subtitle, Vector2(640, 108), 13, Color("#a8bacb"))

func _draw_mobile_controls() -> void:
    if state != "playing":
        return
    draw_circle(Vector2(165, 575), 72, Color(0.02, 0.04, 0.08, 0.30))
    draw_arc(Vector2(165, 575), 72, 0, TAU, 48, Color(0.75, 0.85, 0.92, 0.35), 2.0)
    draw_circle(Vector2(165, 575) + touch_vector * 34, 23, Color(0.75, 0.85, 0.92, 0.30))
    draw_circle(Vector2(1090, 590), 55, Color("#f4d98b", 0.16))
    draw_arc(Vector2(1090, 590), 55, 0, TAU, 48, Color("#f4d98b", 0.55), 2.0)
    _center_text("ACT", Vector2(1090, 596), 16, Color("#fff1bd"))

func _draw_hud() -> void:
    _draw_panel(Rect2(20, 20, 255, 64), Color(0.02, 0.04, 0.08, 0.86))
    _left_text("LIGHT MOTES  " + str(collected) + " / " + str(total_motes), Vector2(38, 47), 17, Color("#f5df9a"))
    _left_text("LANTERN  " + "✦".repeat(max(lives, 0)), Vector2(38, 70), 14, Color("#d5e4ed"))
    _draw_button(buttons.menu, "PAUSE")
    _draw_button(buttons.sound, "SOUND " + ("ON" if sound_on else "OFF"))
    _left_text(LEVELS[level_index].goal, Vector2(295, 51), 14, Color("#c6d3df"))

func _draw_overlay(title: String, subtitle: String, footer: String) -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color(0.015, 0.025, 0.055, 0.78))
    _center_text(title, Vector2(640, 285), 42, Color("#f4d98b"))
    _center_text(subtitle, Vector2(640, 335), 18, Color("#d3e0e8"))
    _center_text(footer, Vector2(640, 375), 16, Color("#9db3c8"))

func _draw_button(rect: Rect2, label: String) -> void:
    draw_rect(rect, Color("#d9b96f"))
    draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6)), Color("#27354b"))
    _center_text(label, rect.position + rect.size / 2 + Vector2(0, 6), 18, Color("#f7e8bc"))

func _draw_panel(rect: Rect2, color: Color) -> void:
    draw_rect(rect, color)
    draw_rect(rect, Color(0.75, 0.85, 0.95, 0.22), false, 1.0)

func _center_text(value: String, pos: Vector2, size: int, color: Color) -> void:
    draw_string(font, pos - Vector2(font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2, 0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _left_text(value: String, pos: Vector2, size: int, color: Color) -> void:
    draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _format_time(seconds: float) -> String:
    var whole := int(seconds)
    var minutes := floori(float(whole) / 60.0)
    return "%02d:%02d" % [minutes, whole % 60]
