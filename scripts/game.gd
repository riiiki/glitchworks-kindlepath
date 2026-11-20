extends Node2D

const EnvironmentArt = preload("res://scripts/environment_art.gd")
const CharacterArt = preload("res://scripts/character_art.gd")
const UIArt = preload("res://scripts/ui_art.gd")

const PLAYER_SPEED := 250.0
const MAX_LANTERN_ENERGY := 100.0
const WORLD_RECT := Rect2(40, 105, 1200, 575)
const SAVE_PATH := "user://lantern_keeper_save.cfg"
const LEVELS := [
	{"name":"THE QUIET GROVE", "subtitle":"The first flame has gone out.", "goal":"Find 3 light motes, then relight the ancient beacon.", "player":Vector2(115,585), "beacon":Vector2(1090,170), "motes":[Vector2(340,520),Vector2(625,335),Vector2(950,530)], "walls":[Rect2(270,120,54,300),Rect2(485,390,260,48),Rect2(820,170,50,240)], "hazards":[Vector2(525,560),Vector2(730,245),Vector2(990,420)], "color":Color("#163b45"), "accent":Color("#65d6b0")},
	{"name":"THE SUNKEN ARCHIVE", "subtitle":"Old memories drift beneath the water.", "goal":"Gather 4 motes and avoid the roaming wisp.", "player":Vector2(110,170), "beacon":Vector2(1100,570), "motes":[Vector2(330,170),Vector2(590,520),Vector2(850,180),Vector2(1050,360)], "walls":[Rect2(205,280,360,45),Rect2(660,120,48,300),Rect2(850,440,250,45)], "hazards":[Vector2(500,160),Vector2(780,565),Vector2(350,610),Vector2(1030,260)], "color":Color("#18334f"), "accent":Color("#71c9ee")},
	{"name":"THE LAST SUMMIT", "subtitle":"Carry the light to the edge of the world.", "goal":"Collect 5 motes and awaken the final beacon.", "player":Vector2(105,570), "beacon":Vector2(1110,160), "motes":[Vector2(300,560),Vector2(470,180),Vector2(690,500),Vector2(900,210),Vector2(1080,510)], "walls":[Rect2(220,340,250,45),Rect2(555,120,48,300),Rect2(730,380,250,45),Rect2(1000,250,48,160)], "hazards":[Vector2(430,600),Vector2(800,300),Vector2(1010,600),Vector2(330,220),Vector2(1110,410)], "color":Color("#302b52"), "accent":Color("#f6c96b")}
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
var touch_vector := Vector2.ZERO
var joystick_touch := -1
var action_touch := -1
var interact_requested := false
var hazard_phase := 0.0
var hazard_invulnerability := 0.0
var message := ""
var message_timer := 0.0
var level_time := 0.0
var total_time := 0.0
var run_score := 0
var last_score := 0
var sound_on := true
var music_on := true
var master_volume := 0.75
var unlocked_level := 0
var best_time := 0.0
var best_score := 0
var lantern_energy := MAX_LANTERN_ENERGY
var checkpoint_pos := Vector2.ZERO
var powerup_timer := 0.0
var shield_timer := 0.0
var speed_timer := 0.0
var powerups: Array[Dictionary] = []
var switch_pos := Vector2.ZERO
var switch_positions: Array[Vector2] = []
var switch_activated: Array[bool] = []
var gate_rect := Rect2()
var gate_open := false
var checkpoint_target := Vector2.ZERO
var checkpoint_reached := false
var secret_mote_pos := Vector2.ZERO
var secret_mote_found := false
var moving_obstacle_pos := Vector2.ZERO
var moving_obstacle_phase := 0.0
var guardian_warning_timer := 0.0
var guardian_vulnerable_timer := 0.0
var guardian_attack_radius := 0.0
var crate_pos := Vector2.ZERO
var crate_active := false
var level_stars := 0
var font: Font
var mouse_pos := Vector2(-100,-100)
var last_cursor: int = -1
var buttons: Dictionary = {}
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var save_config := ConfigFile.new()
var animation_time := 0.0
var player_moving := false
var particles: Array[Dictionary] = []
var ambient_phase := 0.0
var energy_empty_penalty_applied := false
var guardian_health := 0
var guardian_pos := Vector2.ZERO
var guardian_attack_cooldown := 0.0
var guardian_active := false
var guardian_phase := 0.0

func _ready() -> void:
	font = UIArt.font()
	_load_save()
	_create_audio()
	_make_buttons()
	_apply_display_settings()
	_play_level_music(0)
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	queue_redraw()

func _make_buttons() -> void:
	buttons = {
		"start":Rect2(490,304,300,54), "levels":Rect2(490,366,300,54), "tutorial":Rect2(490,428,300,54), "settings":Rect2(490,490,300,54), "credits":Rect2(490,552,300,54),
		"back":Rect2(490,590,300,48), "settings_back":Rect2(490,555,300,48), "next":Rect2(490,420,300,54), "retry":Rect2(490,420,300,54), "story_continue":Rect2(490,485,300,54),
		"resume":Rect2(490,350,300,54), "restart":Rect2(490,416,300,54), "main_menu":Rect2(490,490,300,54),
		"sound":Rect2(1138,14,122,40), "pause":Rect2(1018,14,112,40),
		"music_minus":Rect2(450,284,52,48), "music_plus":Rect2(778,284,52,48),
		"sfx_toggle":Rect2(450,365,380,48), "music_toggle":Rect2(450,425,380,48),
		"fullscreen":Rect2(450,485,380,48), "level_0":Rect2(300,255,200,250), "level_1":Rect2(540,255,200,250), "level_2":Rect2(780,255,200,250)
	}

# Persistent progress and settings ------------------------------------------------
func _load_save() -> void:
	var err := save_config.load(SAVE_PATH)
	if err != OK:
		unlocked_level = 0
		best_time = 0.0
		best_score = 0
		return
	unlocked_level = clampi(int(save_config.get_value("progress","unlocked_level",0)),0,LEVELS.size()-1)
	best_time = float(save_config.get_value("progress","best_time",0.0))
	best_score = int(save_config.get_value("progress","best_score",0))
	master_volume = clampf(float(save_config.get_value("settings","volume",0.75)),0.0,1.0)
	sound_on = bool(save_config.get_value("settings","sound_on",true))
	music_on = bool(save_config.get_value("settings","music_on",true))

func _save_game() -> void:
	save_config.set_value("progress","unlocked_level",unlocked_level)
	save_config.set_value("progress","best_time",best_time)
	save_config.set_value("progress","best_score",best_score)
	save_config.set_value("settings","volume",master_volume)
	save_config.set_value("settings","sound_on",sound_on)
	save_config.set_value("settings","music_on",music_on)
	var err := save_config.save(SAVE_PATH)
	if err != OK:
		push_warning("Could not save Lantern Keeper progress: %s" % error_string(err))

# Procedurally generated original audio: no external asset files are required.
func _create_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "Master"
	add_child(sfx_player)

func _make_tone(frequency: float, duration: float, volume: float = 0.18, wave: int = 0) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(rate)
		var envelope := minf(1.0, t * 35.0) * minf(1.0, (duration - t) * 12.0)
		var sample := sin(TAU * frequency * t)
		if wave == 1:
			sample = sin(TAU * frequency * t) * 0.65 + sin(TAU * frequency * 2.01 * t) * 0.25 + sin(TAU * frequency * 0.5 * t) * 0.1
		var value := int(clampf(sample * volume * envelope, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream

func _make_ambient(root_frequency: float) -> AudioStreamWAV:
	var rate := 22050
	var duration := 6.0
	var count := int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(rate)
		var fade := 0.5 + 0.5 * sin(TAU * t / duration - PI / 2.0)
		var sample := sin(TAU * root_frequency * t) * 0.10 + sin(TAU * root_frequency * 1.5 * t) * 0.045 + sin(TAU * root_frequency * 2.0 * t) * 0.025
		sample *= 0.35 + fade * 0.65
		bytes.encode_s16(i * 2, int(clampf(sample,-1.0,1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

func _play_sfx(kind: String) -> void:
	if not sound_on:
		return
	var freq := 620.0
	var dur := 0.12
	var vol := 0.2
	match kind:
		"collect":
			freq = 880.0; dur = 0.16; vol = 0.22
		"damage":
			freq = 145.0; dur = 0.32; vol = 0.25
		"beacon":
			freq = 520.0; dur = 0.65; vol = 0.24
		"click":
			freq = 420.0; dur = 0.07; vol = 0.12
		"victory":
			freq = 740.0; dur = 0.9; vol = 0.22
	sfx_player.stream = _make_tone(freq,dur,vol,1)
	sfx_player.volume_db = linear_to_db(maxf(0.001,master_volume))
	sfx_player.play()

func _play_level_music(index: int) -> void:
	if not is_instance_valid(music_player):
		return
	var roots := [110.0, 130.81, 98.0]
	music_player.stop()
	music_player.stream = _make_ambient(roots[clampi(index,0,2)])
	music_player.volume_db = linear_to_db(maxf(0.001,master_volume * 0.32))
	music_player.stream_paused = not music_on
	if music_on:
		music_player.play()

func _apply_audio_settings() -> void:
	if is_instance_valid(music_player):
		music_player.volume_db = linear_to_db(maxf(0.001,master_volume * 0.32))
		music_player.stream_paused = not music_on
		if music_on and not music_player.playing:
			music_player.play()
		elif not music_on:
			music_player.stop()
	if is_instance_valid(sfx_player):
		sfx_player.volume_db = linear_to_db(maxf(0.001,master_volume))

func _apply_display_settings() -> void:
	# Windowed mode is the safe default; fullscreen can be toggled in Settings.
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Game flow -----------------------------------------------------------------------
func _start_game(index: int = 0) -> void:
	lives = 3
	total_time = 0.0
	run_score = 0
	_load_level(index)
	state = "playing"
	_say("The lantern remembers the way.",2.2)

func _load_level(index: int) -> void:
	level_index = clampi(index,0,LEVELS.size()-1)
	var data: Dictionary = LEVELS[level_index]
	player_pos = data["player"]
	beacon_pos = data["beacon"]
	motes.clear()
	for value in data["motes"]:
		motes.append(value)
	walls.clear()
	for value in data["walls"]:
		walls.append(value)
	hazards.clear()
	for value in data["hazards"]:
		hazards.append(value)
	total_motes = motes.size()
	collected = 0
	level_time = 0.0
	lantern_energy = MAX_LANTERN_ENERGY
	energy_empty_penalty_applied = false
	guardian_health = 3 if level_index == 2 else 0
	guardian_pos = beacon_pos + Vector2(-105, 55)
	guardian_attack_cooldown = 0.0
	guardian_active = false
	guardian_phase = 0.0
	checkpoint_pos = player_pos
	powerup_timer = 0.0
	shield_timer = 0.0
	speed_timer = 0.0
	# Region-specific puzzle layouts. Grove uses a pressure plate, later regions need two switches.
	var puzzle_sets: Array = [
		[Vector2(620,590)],
		[Vector2(600,210),Vector2(1080,390)],
		[Vector2(650,600),Vector2(930,300)]
	]
	switch_positions.clear()
	for switch_value in puzzle_sets[level_index]:
		switch_positions.append(switch_value)
	switch_pos = switch_positions[0]
	switch_activated.clear()
	for _switch in switch_positions:
		switch_activated.append(false)
	var gate_positions := [Rect2(1010,300,35,150),Rect2(740,500,150,32),Rect2(510,500,35,130)]
	gate_rect = gate_positions[level_index]
	gate_open = false
	crate_active = true
	crate_pos = [Vector2(590,540),Vector2(920,320),Vector2(820,300)][level_index]
	var checkpoints := [Vector2(620,455),Vector2(600,390),Vector2(780,590)]
	checkpoint_target = checkpoints[level_index]
	checkpoint_reached = false
	var secrets := [Vector2(160,460),Vector2(1130,300),Vector2(150,300)]
	secret_mote_pos = secrets[level_index]
	secret_mote_found = false
	moving_obstacle_pos = Vector2(620,560)
	moving_obstacle_phase = 0.0
	guardian_warning_timer = 0.0
	guardian_vulnerable_timer = 0.0
	guardian_attack_radius = 0.0
	powerups.clear()
	powerups.append({"pos": [Vector2(180,300),Vector2(1070,250),Vector2(570,600)][level_index], "kind":"speed"})
	powerups.append({"pos": [Vector2(700,180),Vector2(300,570),Vector2(300,200)][level_index], "kind":"shield"})
	hazard_phase = 0.0
	hazard_invulnerability = 0.0
	touch_vector = Vector2.ZERO
	joystick_touch = -1
	action_touch = -1
	_play_level_music(level_index)

func _complete_level() -> void:
	_spawn_burst(beacon_pos, LEVELS[level_index]["accent"], 48)
	_play_sfx("beacon")
	level_stars = _calculate_stars()
	run_score += collected * 100 + lives * 150 + maxi(0,1000-int(level_time*5.0)) + level_stars * 250
	unlocked_level = mini(LEVELS.size()-1,maxi(unlocked_level,level_index+1))
	_save_game()
	state = "level_complete"

func _calculate_stars() -> int:
	var stars := 1
	if lives >= 2 and lantern_energy >= 25.0:
		stars += 1
	if level_time <= 100.0:
		stars += 1
	return stars

func _finish_game() -> void:
	_spawn_burst(beacon_pos, LEVELS[level_index]["accent"], 64)
	_play_sfx("victory")
	level_stars = _calculate_stars()
	run_score += collected * 100 + lives * 150 + maxi(0,1000-int(level_time*5.0)) + level_stars * 250
	last_score = run_score
	if best_time <= 0.0 or total_time < best_time:
		best_time = total_time
	best_score = maxi(best_score,last_score)
	unlocked_level = LEVELS.size()-1
	_save_game()
	state = "victory"

func _process(delta: float) -> void:
	var want: int = DisplayServer.CURSOR_POINTING_HAND if _hover_any() else DisplayServer.CURSOR_ARROW
	if want != last_cursor:
		last_cursor = want
		DisplayServer.cursor_set_shape(want as DisplayServer.CursorShape)
	if message_timer > 0.0:
		message_timer = maxf(0.0,message_timer-delta)
	if hazard_invulnerability > 0.0:
		hazard_invulnerability = maxf(0.0,hazard_invulnerability-delta)
	animation_time += delta
	ambient_phase += delta
	_update_particles(delta)
	if state == "playing":
		level_time += delta
		lantern_energy = maxf(0.0, lantern_energy - delta * 1.35)
		powerup_timer = maxf(0.0, powerup_timer - delta)
		shield_timer = maxf(0.0, shield_timer - delta)
		speed_timer = maxf(0.0, speed_timer - delta)
		if lantern_energy <= 0.0 and not energy_empty_penalty_applied:
			energy_empty_penalty_applied = true
			_hit_hazard()
		elif lantern_energy > 0.0:
			energy_empty_penalty_applied = false
		total_time += delta
		hazard_phase += delta
		var old_player_pos := player_pos
		_update_player(delta)
		player_moving = player_pos.distance_to(old_player_pos) > 0.5
		_update_hazards(delta)
		_update_guardian(delta)
		if level_index == 1:
			moving_obstacle_phase += delta
			moving_obstacle_pos = Vector2(620.0 + sin(moving_obstacle_phase * 1.25) * 145.0, 560.0)
			if Rect2(player_pos-Vector2(15,15),Vector2(30,30)).intersects(Rect2(moving_obstacle_pos-Vector2(24,24),Vector2(48,48))):
				if hazard_invulnerability <= 0.0:
					_hit_hazard()
		if not secret_mote_found and player_pos.distance_to(secret_mote_pos) < 26.0:
			secret_mote_found = true
			run_score += 300
			_spawn_burst(secret_mote_pos, Color("#f6c96b"), 32)
			_say("Secret memory found! Bonus 300 points.",2.0)
			_play_sfx("collect")
		_check_collectibles()
		_check_powerups()
		if not checkpoint_reached and player_pos.distance_to(checkpoint_target) < 38.0:
			checkpoint_reached = true
			checkpoint_pos = checkpoint_target
			_spawn_burst(checkpoint_target, Color("#8de4f4"), 24)
			_say("Checkpoint activated! Your lantern is anchored here.",2.0)
		if interact_requested:
			_try_beacon()
		interact_requested = false
	queue_redraw()

func _update_player(delta: float) -> void:
	var direction := Input.get_vector("move_left","move_right","move_up","move_down")
	if joystick_touch >= 0:
		direction = touch_vector
	if direction.length() > 1.0:
		direction = direction.normalized()
	var current_speed := PLAYER_SPEED * (1.45 if speed_timer > 0.0 else 1.0)
	var movement := direction * current_speed * delta
	var next_pos := player_pos
	# Resolve each axis independently so the player can slide along walls and closed gates.
	var candidate_x := Vector2(player_pos.x + movement.x, player_pos.y)
	if not _position_blocked(candidate_x, true):
		next_pos.x = candidate_x.x
	var candidate_y := Vector2(next_pos.x, player_pos.y + movement.y)
	if not _position_blocked(candidate_y, true):
		next_pos.y = candidate_y.y
	# Push the crate only when the destination is clear; never push it through a gate or obstacle.
	if crate_active and direction.length() > 0.05:
		var player_rect := Rect2(next_pos-Vector2(15,15),Vector2(30,30))
		var crate_rect := Rect2(crate_pos-Vector2(22,22),Vector2(44,44))
		if player_rect.intersects(crate_rect):
			var push := direction.normalized() * 38.0
			var moved_crate := crate_pos + push
			var blocked := false
			for wall in walls:
				if Rect2(moved_crate-Vector2(22,22),Vector2(44,44)).intersects(wall):
					blocked = true
			if not gate_open and Rect2(moved_crate-Vector2(22,22),Vector2(44,44)).intersects(gate_rect):
				blocked = true
			if level_index == 1 and Rect2(moved_crate-Vector2(22,22),Vector2(44,44)).intersects(Rect2(moving_obstacle_pos-Vector2(24,24),Vector2(48,48))):
				blocked = true
			if not blocked and WORLD_RECT.grow(-22.0).has_point(moved_crate):
				crate_pos = moved_crate
			else:
				next_pos = player_pos
	player_pos = next_pos

func _position_blocked(pos: Vector2, include_dynamic: bool) -> bool:
	var body := Rect2(pos-Vector2(15,15),Vector2(30,30))
	if not WORLD_RECT.grow(-20.0).has_point(pos):
		return true
	for wall in walls:
		if body.intersects(wall):
			return true
	if not gate_open and body.intersects(gate_rect):
		return true
	if include_dynamic and level_index == 1 and body.intersects(Rect2(moving_obstacle_pos-Vector2(24,24),Vector2(48,48))):
		return true
	return false

func _update_hazards(delta: float) -> void:
	for i in range(hazards.size()):
		var base: Vector2 = LEVELS[level_index]["hazards"][i]
		var kind := i % 3
		var patrol_radius := 38.0 + float(level_index) * 7.0
		if kind == 0:
			# Wisps drift in broad, quick loops.
			hazards[i] = base + Vector2(sin(hazard_phase * (1.35 + i * 0.08) + i) * patrol_radius * 1.25, cos(hazard_phase * 1.15 + i) * 34.0)
		elif kind == 1:
			# Stalkers alternate between a short chase and a retreat to their home patrol point.
			var cycle := fposmod(hazard_phase + float(i), 6.0)
			if cycle < 3.4:
				hazards[i] = hazards[i].move_toward(player_pos, delta * (72.0 + float(level_index) * 24.0))
			else:
				hazards[i] = hazards[i].move_toward(base, delta * (88.0 + float(level_index) * 18.0))
		else:
			# Guardians hold a fixed territory and return home if lured too far away.
			var patrol := base + Vector2(sin(hazard_phase * 0.72 + i) * patrol_radius * 0.72, cos(hazard_phase * 0.8 + i) * 19.0)
			hazards[i] = hazards[i].move_toward(patrol, delta * 80.0)
		# Enemies cannot clip through walls, the sealed gate, or the movable crate.
		var enemy_body := Rect2(hazards[i]-Vector2(15,15),Vector2(30,30))
		var enemy_blocked := false
		for wall in walls:
			if enemy_body.intersects(wall):
				enemy_blocked = true
				break
		if not gate_open and enemy_body.intersects(gate_rect):
			enemy_blocked = true
		if crate_active and enemy_body.intersects(Rect2(crate_pos-Vector2(22,22),Vector2(44,44))):
			enemy_blocked = true
		if enemy_blocked:
			hazards[i] = hazards[i].move_toward(base, delta * 120.0)
		if hazard_invulnerability <= 0.0 and shield_timer <= 0.0 and player_pos.distance_to(hazards[i]) < 34.0:
			_hit_hazard()
			break

func _update_guardian(delta: float) -> void:
	if level_index != 2 or collected < total_motes or not gate_open or guardian_health <= 0:
		return
	guardian_active = true
	guardian_phase += delta
	guardian_attack_cooldown = maxf(0.0, guardian_attack_cooldown - delta)
	guardian_vulnerable_timer = maxf(0.0, guardian_vulnerable_timer - delta)
	var orbit := beacon_pos + Vector2(cos(guardian_phase * 0.8) * 72.0, sin(guardian_phase * 1.1) * 46.0)
	guardian_pos = guardian_pos.move_toward(orbit, delta * (95.0 + float(3 - guardian_health) * 18.0))
	if guardian_warning_timer > 0.0:
		guardian_warning_timer = maxf(0.0, guardian_warning_timer - delta)
		if guardian_warning_timer <= 0.0:
			guardian_attack_radius = 118.0 + float(3 - guardian_health) * 18.0
			_spawn_burst(guardian_pos, Color("#c78be8"), 28)
			if player_pos.distance_to(guardian_pos) < guardian_attack_radius and hazard_invulnerability <= 0.0:
				_hit_hazard()
			guardian_vulnerable_timer = 1.25
			guardian_attack_cooldown = 2.8 - float(3 - guardian_health) * 0.25
	elif guardian_attack_cooldown <= 0.0:
		guardian_warning_timer = 0.85
		_say("The Guardian is charging a light pulse! Move away!",1.0)
	if hazard_invulnerability <= 0.0 and shield_timer <= 0.0 and player_pos.distance_to(guardian_pos) < 43.0:
		_hit_hazard()


func _hit_hazard() -> void:
	if hazard_invulnerability > 0.0 or state != "playing":
		return
	if shield_timer > 0.0:
		shield_timer = 0.0
		hazard_invulnerability = 0.8
		_say("Your protective light absorbed the shadow!",1.5)
		return
	lives = maxi(0,lives-1)
	_spawn_burst(player_pos, Color("#ed7c91"), 22)
	hazard_invulnerability = 1.35
	player_pos = checkpoint_pos
	touch_vector = Vector2.ZERO
	_play_sfx("damage")
	_say("A shadow brushed your lantern. Be careful!",2.0)
	if lives <= 0:
		state = "game_over"
		_save_game()

func _check_collectibles() -> void:
	for i in range(motes.size()-1,-1,-1):
		if player_pos.distance_to(motes[i]) < 30.0:
			var collected_position: Vector2 = motes[i]
			_spawn_burst(collected_position, Color("#f4f4d5"), 16)
			motes.remove_at(i)
			collected += 1
			lantern_energy = minf(MAX_LANTERN_ENERGY,lantern_energy+18.0)
			if lantern_energy > 0.0: energy_empty_penalty_applied = false
			_play_sfx("collect")
			_say("Light mote collected!  %d / %d" % [collected,total_motes],1.2)

func _try_beacon() -> void:
	for i in range(switch_positions.size()):
		# The first Grove seal is a crate-operated pressure plate, not a hand switch.
		if level_index == 0 and i == 0:
			continue
		if not switch_activated[i] and player_pos.distance_to(switch_positions[i]) < 62.0:
			switch_activated[i] = true
			_spawn_burst(switch_positions[i], Color("#f4c96b"), 24)
			_play_sfx("beacon")
			var all_active := true
			for active in switch_activated:
				if not active:
					all_active = false
			if all_active:
				gate_open = true
				_say("All seals aligned! The gate is open.",2.0)
			else:
				_say("Seal activated! Find the remaining switch.",1.8)
			return
	# In the Grove, the movable crate can press the plate for an alternate solution.
	if level_index == 0 and not switch_activated[0] and crate_pos.distance_to(switch_positions[0]) < 48.0:
		switch_activated[0] = true
		gate_open = true
		_spawn_burst(switch_positions[0], Color("#f4c96b"), 24)
		_say("Pressure plate engaged by the crate!",1.8)
		return
	if level_index == 2 and collected >= total_motes and gate_open and guardian_health > 0 and player_pos.distance_to(guardian_pos) < 100.0:
		if guardian_vulnerable_timer > 0.0 and guardian_attack_cooldown > 0.0:
			guardian_health -= 1
			guardian_vulnerable_timer = 0.0
			_spawn_burst(guardian_pos, Color("#f4c96b"), 24)
			_play_sfx("beacon")
			_say("Guardian seal broken! %d phase(s) remain." % guardian_health,1.6)
			if guardian_health <= 0:
				guardian_active = false
				_spawn_burst(guardian_pos, Color("#f4d98b"), 60)
				_say("The Summit Guardian is calmed. Reach the final beacon!",2.5)
		else:
			_say("Wait for the Guardian's pulse, then approach during its recovery!",2.0)
		return
	if player_pos.distance_to(beacon_pos) > 78.0:
		_say("Move closer to the beacon.",1.3)
		return
	if collected < total_motes:
		_say("The beacon needs %d more mote(s)." % (total_motes-collected),1.8)
		return
	if not gate_open:
		_say("Activate every golden seal to open the gate.",1.8)
		return
	if level_index == 2 and guardian_health > 0:
		_say("The Summit Guardian still guards the beacon. Break its three seals!",2.0)
		return
	if level_index < LEVELS.size()-1:
		_complete_level()
	else:
		_finish_game()

func _check_powerups() -> void:
	for i in range(powerups.size()-1,-1,-1):
		var item: Dictionary = powerups[i]
		if player_pos.distance_to(item["pos"]) < 30.0:
			if item["kind"] == "speed":
				speed_timer = 7.0
				_say("Swift light! Speed increased for 7 seconds.",1.8)
			else:
				shield_timer = 8.0
				_say("Protective light! Shadows cannot hurt you for 8 seconds.",1.8)
			powerups.remove_at(i)
			_play_sfx("collect")

func _spawn_burst(origin: Vector2, tint: Color, amount: int = 12) -> void:
	for i in range(amount):
		var angle := TAU * float(i) / float(amount) + randf_range(-0.18, 0.18)
		var speed := randf_range(35.0, 125.0)
		particles.append({"pos": origin, "vel": Vector2(cos(angle), sin(angle)) * speed, "life": randf_range(0.35, 0.8), "max_life": 0.8, "color": tint, "size": randf_range(2.0, 5.0)})

func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var particle: Dictionary = particles[i]
		particle["life"] = float(particle["life"]) - delta
		var particle_pos: Vector2 = particle["pos"]
		var particle_velocity: Vector2 = particle["vel"]
		particle["pos"] = particle_pos + particle_velocity * delta
		particle["vel"] = particle_velocity * 0.94
		if float(particle["life"]) <= 0.0:
			particles.remove_at(i)
		else:
			particles[i] = particle

func _say(value: String,duration: float) -> void:
	message = value
	message_timer = duration

# Input ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		mouse_pos = event.position
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			if state == "playing": interact_requested = true
		elif event.keycode == KEY_ESCAPE:
			if state == "playing": state = "paused"
			elif state == "paused": state = "playing"
			elif state == "settings" or state == "levels" or state == "tutorial" or state == "credits": state = "menu"
			elif state == "story": state = "menu"
	if event is InputEventScreenTouch:
		mouse_pos = Vector2(-100,-100)
		if event.pressed:
			if _handle_ui_click(event.position):
				return
			if state == "playing":
				if event.position.x < 390 and event.position.y > 390 and joystick_touch == -1:
					joystick_touch = event.index
					touch_vector = _touch_direction(event.position)
				elif event.position.x > 820 and event.position.y > 470 and action_touch == -1:
					action_touch = event.index
					interact_requested = true
		else:
			if event.index == joystick_touch:
				joystick_touch = -1
				touch_vector = Vector2.ZERO
			if event.index == action_touch:
				action_touch = -1
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch:
			touch_vector = _touch_direction(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not _handle_ui_click(event.position) and state == "playing" and event.position.x > 850 and event.position.y > 500:
			interact_requested = true

func _touch_direction(point: Vector2) -> Vector2:
	var center := Vector2(165,575)
	var v := point-center
	if v.length() < 18.0: return Vector2.ZERO
	return v.normalized()

func _handle_ui_click(point: Vector2) -> bool:
	if state == "menu":
		if buttons.start.has_point(point):
			_play_sfx("click"); state = "story"; return true
		if buttons.levels.has_point(point):
			_play_sfx("click"); state = "levels"; return true
		if buttons.tutorial.has_point(point):
			_play_sfx("click"); state = "tutorial"; return true
		if buttons.settings.has_point(point):
			_play_sfx("click"); state = "settings"; return true
		if buttons.credits.has_point(point):
			_play_sfx("click"); state = "credits"; return true
	elif state == "levels":
		for i in range(3):
			if buttons["level_%d" % i].has_point(point) and i <= unlocked_level:
				_play_sfx("click"); _start_game(i); return true
		if buttons.back.has_point(point): state = "menu"; return true
	elif state == "tutorial" or state == "credits":
		if buttons.back.has_point(point): state = "menu"; _play_sfx("click"); return true
	elif state == "story":
		if buttons.story_continue.has_point(point): _start_game(0); return true
	elif state == "settings":
		if buttons.music_minus.has_point(point):
			master_volume = maxf(0.0,master_volume-0.1); _apply_audio_settings(); _save_game(); return true
		if buttons.music_plus.has_point(point):
			master_volume = minf(1.0,master_volume+0.1); _apply_audio_settings(); _save_game(); return true
		if buttons.sfx_toggle.has_point(point): sound_on = not sound_on; _save_game(); _play_sfx("click"); return true
		if buttons.music_toggle.has_point(point): music_on = not music_on; _apply_audio_settings(); _save_game(); return true
		if buttons.fullscreen.has_point(point):
			var mode := DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
			return true
		if buttons.settings_back.has_point(point): state = "menu"; _play_sfx("click"); return true
	elif state == "playing":
		if buttons.pause.has_point(point): state = "paused"; _play_sfx("click"); return true
		if buttons.sound.has_point(point): sound_on = not sound_on; _save_game(); return true
	elif state == "paused":
		if buttons.resume.has_point(point): state = "playing"; _play_sfx("click"); return true
		if buttons.restart.has_point(point): _start_game(level_index); return true
		if buttons.main_menu.has_point(point): state = "menu"; _save_game(); return true
	elif state == "level_complete":
		if buttons.next.has_point(point):
			_load_level(level_index+1); state = "playing"; _say("A new path opens...",1.5); return true
		if buttons.main_menu.has_point(point): state = "menu"; return true
	elif state == "game_over":
		if buttons.retry.has_point(point): _start_game(level_index); return true
		if buttons.main_menu.has_point(point): state = "menu"; return true
	elif state == "victory":
		if buttons.retry.has_point(point): _start_game(0); return true
		if buttons.main_menu.has_point(point): state = "menu"; return true
		if buttons.credits.has_point(point): state = "credits"; return true
	return false

# Drawing -------------------------------------------------------------------------
func _draw() -> void:
	_draw_background()
	match state:
		"menu": _draw_menu()
		"levels": _draw_levels()
		"settings": _draw_settings()
		"tutorial": _draw_tutorial()
		"story": _draw_story()
		"credits": _draw_credits()
		_:
			_draw_world()
			_draw_hud()
			if state == "paused": _draw_pause()
			elif state == "level_complete": _draw_level_complete()
			elif state == "game_over": _draw_game_over()
			elif state == "victory": _draw_victory()
			if message_timer > 0.0 and state == "playing":
				_draw_toast()

func _hover(key: String) -> bool:
	return buttons.has(key) and Rect2(buttons[key]).has_point(mouse_pos)

func _down(key: String) -> bool:
	return _hover(key) and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _btn(key: String,label: String,primary: bool = false,icon: String = "",size: int = 19) -> void:
	UIArt.button(self,buttons[key],label,_hover(key),_down(key),true,size,primary,icon)

func _visible_button_keys() -> Array:
	match state:
		"menu": return ["start","levels","tutorial","settings","credits"]
		"levels": return ["level_0","level_1","level_2","back"]
		"tutorial", "credits": return ["back"]
		"story": return ["story_continue"]
		"settings": return ["music_minus","music_plus","sfx_toggle","music_toggle","fullscreen","settings_back"]
		"playing": return ["pause","sound"]
		"paused": return ["resume","restart","main_menu"]
		"level_complete": return ["next","main_menu"]
		"game_over": return ["retry","main_menu"]
		"victory": return ["retry","main_menu","credits"]
	return []

func _hover_any() -> bool:
	for key in _visible_button_keys():
		if String(key).begins_with("level_") and int(String(key).substr(6)) > unlocked_level:
			continue
		if _hover(String(key)):
			return true
	return false

func _draw_background() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#090e20"))
	for i in range(90):
		var x := float((i*173)%1280)
		var y := float((i*97)%720)
		var alpha := 0.18+0.12*sin(Time.get_ticks_msec()/900.0+i)
		draw_circle(Vector2(x,y),1.4,Color(0.75,0.84,1.0,alpha))
	draw_circle(Vector2(1080,80),95,Color("#1a2944",0.35))

func _draw_menu() -> void:
	UIArt.glow_title(self,"LANTERN KEEPER",Vector2(640,150),62,UIArt.GOLD,animation_time)
	UIArt.text(self,"A LIGHT IN THE DARK",Vector2(640,186),17,Color("#8db9bd"),1,true)
	UIArt.lantern(self,Vector2(640,250),true,animation_time,2.3)
	_btn("start","BEGIN JOURNEY",true)
	_btn("levels","SELECT LEVEL")
	_btn("tutorial","HOW TO PLAY")
	_btn("settings","SETTINGS")
	_btn("credits","CREDITS")
	UIArt.text(self,"WASD / Arrows: move     E / Space: interact     Esc: pause",Vector2(640,640),14,UIArt.MUTED,1)
	UIArt.text(self,"Regions unlocked %d / 3     Best score %d" % [unlocked_level+1,best_score],Vector2(640,668),14,Color("#c4d0d8"),1)

func _draw_level_preview(i: int,pv: Rect2,available: bool) -> void:
	var data: Dictionary = LEVELS[i]
	var accent: Color = data["accent"]
	var tint: Color = data["color"]
	draw_style_box(UIArt.fill_style(tint if available else Color("#111a29")),pv)
	if not available:
		UIArt.lock_icon(self,pv.position+pv.size*0.5+Vector2(0,-6),Color("#4a5a70"))
		return
	var sc := Vector2(pv.size.x/WORLD_RECT.size.x,pv.size.y/WORLD_RECT.size.y)
	for w in data["walls"]:
		var wr: Rect2 = w
		draw_rect(Rect2(pv.position+(wr.position-WORLD_RECT.position)*sc,wr.size*sc),Color(0.03,0.06,0.12,0.9))
	for m in data["motes"]:
		var mp: Vector2 = m
		draw_circle(pv.position+(mp-WORLD_RECT.position)*sc,2.6,Color("#f4f4d5"))
	var bp: Vector2 = data["beacon"]
	var bs := pv.position+(bp-WORLD_RECT.position)*sc
	draw_circle(bs,8,Color(accent,0.30))
	draw_circle(bs,3.5,accent)
	var pp: Vector2 = data["player"]
	draw_circle(pv.position+(pp-WORLD_RECT.position)*sc,3.5,Color("#8de4f4"))

func _draw_levels() -> void:
	UIArt.glow_title(self,"CHOOSE YOUR REGION",Vector2(640,170),40,UIArt.GOLD,animation_time)
	UIArt.text(self,"Each beacon you restore opens the next region.",Vector2(640,208),15,UIArt.MUTED,1)
	for i in range(3):
		var r: Rect2 = buttons["level_%d" % i]
		var available := i <= unlocked_level
		var hover := available and r.has_point(mouse_pos)
		if hover:
			r.position.y -= 6.0
		UIArt.box(self,r,"card_locked" if not available else ("card_hover" if hover else "card"))
		var accent: Color = LEVELS[i]["accent"]
		var pv := Rect2(r.position+Vector2(14,14),Vector2(r.size.x-28,96))
		_draw_level_preview(i,pv,available)
		var col := accent if available else Color("#5b6a7e")
		UIArt.text(self,"REGION %d" % (i+1),Vector2(r.position.x+16,pv.end.y+28),13,col,0,true,false)
		UIArt.text(self,"READY" if available else "LOCKED",Vector2(r.end.x-16,pv.end.y+28),12,Color("#b9e8d7") if available else Color("#5b6a7e"),2,true,false)
		var nm := String(LEVELS[i]["name"])
		UIArt.text(self,nm,Vector2(r.position.x+16,pv.end.y+56),UIArt.fit_size(nm,r.size.x-32,17,12,true),Color("#f1f5f8") if available else Color("#6b7a8f"),0,true)
		UIArt.wrapped(self,String(LEVELS[i]["subtitle"]),Vector2(r.position.x+16,pv.end.y+80),r.size.x-32,13,UIArt.MUTED if available else Color("#4a586b"),0,3)
	_btn("back","BACK")

func _draw_settings() -> void:
	UIArt.box(self,Rect2(390,110,500,540),"panel")
	UIArt.text(self,"SETTINGS",Vector2(640,180),38,UIArt.GOLD,1,true)
	UIArt.text(self,"AUDIO & DISPLAY",Vector2(640,208),13,Color("#8faec4"),1,true,false)
	UIArt.divider(self,640,226,300)
	UIArt.text(self,"MASTER VOLUME",Vector2(450,268),15,UIArt.TEXT,0,true)
	UIArt.text(self,"%d%%" % int(round(master_volume*100.0)),Vector2(830,268),17,UIArt.GOLD,2,true)
	_btn("music_minus","-",false,"",26)
	UIArt.segment_bar(self,Rect2(518,296,242,24),int(round(master_volume*10.0)),10,UIArt.GOLD_DEEP)
	_btn("music_plus","+",false,"",26)
	UIArt.toggle_row(self,buttons.sfx_toggle,"Sound effects",sound_on,_hover("sfx_toggle"),_down("sfx_toggle"))
	UIArt.toggle_row(self,buttons.music_toggle,"Background music",music_on,_hover("music_toggle"),_down("music_toggle"))
	_btn("fullscreen","TOGGLE FULLSCREEN")
	_btn("settings_back","BACK TO MENU")

func _draw_tutorial() -> void:
	UIArt.box(self,Rect2(250,60,780,600),"panel")
	UIArt.text(self,"HOW TO PLAY",Vector2(640,112),38,UIArt.GOLD,1,true)
	UIArt.text(self,"Restore the light across three regions",Vector2(640,142),14,Color("#8faec4"),1)
	UIArt.divider(self,640,160,360)
	var rows := [
		["Move", "WASD or arrow keys  •  touch joystick on mobile"],
		["Interact", "E or Space: flip switches and light beacons"],
		["Objective", "Collect every light mote, then reach the beacon"],
		["Survive", "Avoid shadow wisps. You have three lantern lives"],
		["Puzzles", "Push crates onto plates, use the gold switch, open the gate"],
		["Power-ups", "Blue = speed  •  Purple = one-hit shield"],
		["Energy", "Your lantern fades over time. Motes refill it"],
		["Enemies", "Wisps drift  •  Stalkers chase  •  Guardians hold paths"],
		["Final region", "Dodge the Guardian's pulse, then press Act while it recovers"]
	]
	var y := 184.0
	for row in rows:
		UIArt.box(self,Rect2(285,y,150,30),"chip")
		UIArt.text(self,String(row[0]),Vector2(360,y+21),14,UIArt.GOLD,1,true,false)
		UIArt.text(self,String(row[1]),Vector2(455,y+21),15,UIArt.TEXT,0)
		y += 44.0
	_btn("back","BACK TO MENU")

func _draw_story() -> void:
	UIArt.box(self,Rect2(270,125,740,470),"panel")
	UIArt.text(self,"WHEN THE LAST LIGHT FELL",Vector2(640,200),UIArt.fit_size("WHEN THE LAST LIGHT FELL",660,36,24,true),UIArt.GOLD,1,true)
	UIArt.divider(self,640,224,360)
	UIArt.wrapped(self,"The old beacons once connected every living place. When their flames faded, the shadows crossed the land.",Vector2(320,268),640,19,UIArt.TEXT,1)
	UIArt.wrapped(self,"You are the Lantern Keeper. Gather the scattered motes, restore the three beacons, and bring dawn back to the world.",Vector2(320,352),640,19,Color("#b9d7df"),1)
	UIArt.text(self,"Every light you recover makes the next path possible.",Vector2(640,446),15,Color("#8faec4"),1)
	_btn("story_continue","BEGIN THE JOURNEY",true)

func _draw_credits() -> void:
	UIArt.box(self,Rect2(330,110,620,550),"panel")
	UIArt.text(self,"CREDITS",Vector2(640,180),42,UIArt.GOLD,1,true)
	UIArt.divider(self,640,204,300)
	UIArt.text(self,"LANTERN KEEPER",Vector2(640,262),26,UIArt.TEXT,1,true)
	UIArt.text(self,"A small adventure about carrying light through the dark.",Vector2(640,304),16,Color("#b9d7df"),1)
	UIArt.text(self,"Design, programming, and game direction",Vector2(640,380),15,Color("#8faec4"),1)
	UIArt.text(self,"Student game project",Vector2(640,412),19,UIArt.GOLD,1,true)
	UIArt.text(self,"Thank you for playing.",Vector2(640,480),19,UIArt.TEXT,1)
	UIArt.lantern(self,Vector2(640,534),true,animation_time,1.4)
	_btn("back","BACK TO MENU")

func _draw_world() -> void:
	var data: Dictionary = LEVELS[level_index]
	EnvironmentArt.draw_environment(self, level_index, WORLD_RECT, data["accent"], ambient_phase)
	for wall in walls:
		draw_rect(wall,Color("#0b172b"))
		draw_rect(Rect2(wall.position,Vector2(wall.size.x,5)),data["accent"].darkened(0.25))
	for mote in motes:
		var mote_pulse := 1.0 + sin(animation_time * 3.0 + mote.x * 0.01) * 0.16
		draw_circle(mote,20 * mote_pulse,Color(data["accent"],0.12)); draw_circle(mote,10 * mote_pulse,data["accent"])
		draw_colored_polygon(PackedVector2Array([mote+Vector2(0,-15),mote+Vector2(9,0),mote+Vector2(0,15),mote+Vector2(-9,0)]),Color("#f4f4d5"))
	# Puzzle gate and region-specific switches / pressure plate.
	if not gate_open:
		draw_rect(gate_rect,Color("#b66d65"))
		draw_rect(gate_rect,Color("#f4c96b"),false,2.0)
	else:
		draw_rect(gate_rect,Color(0.4,0.8,0.65,0.12))
	for switch_index in range(switch_positions.size()):
		var seal_color := Color("#65d6b0") if switch_activated[switch_index] else Color("#f4c96b")
		draw_circle(switch_positions[switch_index],25,Color(seal_color,0.20))
		draw_circle(switch_positions[switch_index],12,seal_color)
		draw_arc(switch_positions[switch_index],31,0,TAU,32,seal_color,2.0)
	# Checkpoint marker is placed at a deliberate route location, not at the beacon.
	draw_circle(checkpoint_target,25,Color("#8de4f4",0.12))
	draw_arc(checkpoint_target,19,0,TAU,32,Color("#8de4f4",0.8),2.0)
	_center_text("CHECKPOINT",checkpoint_target+Vector2(0,-30),13,Color("#a9e9f5"))
	if not secret_mote_found:
		var secret_alpha := 0.18 if player_pos.distance_to(secret_mote_pos) > 110.0 else 0.9
		draw_circle(secret_mote_pos,13,Color("#f6c96b",secret_alpha))
		if secret_alpha > 0.5:
			draw_circle(secret_mote_pos,5,Color("#fff0b0"))
	if level_index == 1:
		draw_rect(Rect2(moving_obstacle_pos-Vector2(24,24),Vector2(48,48)),Color("#4c9db5"))
		draw_rect(Rect2(moving_obstacle_pos-Vector2(18,18),Vector2(36,36)),Color("#8de4f4"),false,2.0)
		draw_circle(moving_obstacle_pos,36,Color("#71c9ee",0.12))
	if crate_active:
		draw_rect(Rect2(crate_pos-Vector2(22,22),Vector2(44,44)),Color("#9b7952"))
		draw_rect(Rect2(crate_pos-Vector2(16,16),Vector2(32,32)),Color("#c9a875"),false,2.0)
	for item in powerups:
		var power_color := Color("#78d9f2") if item["kind"] == "speed" else Color("#b99aff")
		draw_circle(item["pos"],19,Color(power_color,0.22))
		draw_circle(item["pos"],10,power_color)
	for enemy_index in range(hazards.size()):
		var hazard: Vector2 = hazards[enemy_index]
		var enemy_pulse := 1.0 + sin(animation_time * 4.0 + enemy_index) * 0.12
		var enemy_kind := enemy_index % 3
		var enemy_tint := Color("#73c8d6") if enemy_kind == 0 else (Color("#a94e75") if enemy_kind == 1 else Color("#856fbd"))
		draw_circle(hazard,30 * enemy_pulse,Color(enemy_tint,0.13))
		draw_circle(hazard+Vector2(0,7),18,Color(0.01,0.02,0.05,0.30))
		if enemy_kind == 0:
			# Wisp: floating diamond with a trailing glow.
			draw_colored_polygon(PackedVector2Array([hazard+Vector2(0,-22),hazard+Vector2(14,0),hazard+Vector2(0,20),hazard+Vector2(-14,0)]),enemy_tint)
			draw_circle(hazard+Vector2(-4,-2),2.5,Color("#fff0c6")); draw_circle(hazard+Vector2(4,-2),2.5,Color("#fff0c6"))
		elif enemy_kind == 1:
			# Stalker: compact pointed silhouette.
			draw_colored_polygon(PackedVector2Array([hazard+Vector2(0,-22),hazard+Vector2(18,-4),hazard+Vector2(10,17),hazard+Vector2(-10,17),hazard+Vector2(-18,-4)]),enemy_tint)
			draw_circle(hazard+Vector2(-5,-3),3,Color("#ffe4bc")); draw_circle(hazard+Vector2(6,-3),3,Color("#ffe4bc"))
		else:
			# Guardian: heavier armored shadow with a visible crown.
			draw_rect(Rect2(hazard+Vector2(-16,-14),Vector2(32,31)),enemy_tint)
			draw_colored_polygon(PackedVector2Array([hazard+Vector2(-16,-13),hazard+Vector2(-9,-25),hazard+Vector2(-2,-14),hazard+Vector2(5,-25),hazard+Vector2(16,-13)]),enemy_tint.lightened(0.18))
			draw_circle(hazard+Vector2(-6,0),3,Color("#ffe4bc")); draw_circle(hazard+Vector2(6,0),3,Color("#ffe4bc"))
	if guardian_active and guardian_health > 0:
		var boss_pulse := 1.0 + sin(animation_time * 3.0) * 0.08
		draw_circle(guardian_pos,48 * boss_pulse,Color("#b06bce",0.18))
		draw_colored_polygon(PackedVector2Array([guardian_pos+Vector2(0,-38),guardian_pos+Vector2(30,-12),guardian_pos+Vector2(25,25),guardian_pos+Vector2(0,37),guardian_pos+Vector2(-25,25),guardian_pos+Vector2(-30,-12)]),Color("#57436f"))
		draw_colored_polygon(PackedVector2Array([guardian_pos+Vector2(0,-29),guardian_pos+Vector2(18,-8),guardian_pos+Vector2(14,18),guardian_pos+Vector2(0,25),guardian_pos+Vector2(-14,18),guardian_pos+Vector2(-18,-8)]),Color("#a56cba"))
		draw_circle(guardian_pos+Vector2(-8,-4),4,Color("#ffe6a8")); draw_circle(guardian_pos+Vector2(8,-4),4,Color("#ffe6a8"))
		_center_text("GUARDIAN  %d / 3" % guardian_health,guardian_pos+Vector2(0,-56),14,Color("#f5dca2"))
		if guardian_warning_timer > 0.0:
			draw_circle(guardian_pos,118.0 + float(3-guardian_health)*18.0,Color("#dc83e8",0.10))
			draw_arc(guardian_pos,118.0 + float(3-guardian_health)*18.0,0,TAU,64,Color("#ef9df1",0.9),3.0)
			_center_text("MOVE AWAY!",guardian_pos+Vector2(0,72),16,Color("#ffd0f2"))
		elif guardian_vulnerable_timer > 0.0:
			draw_circle(guardian_pos,58,Color("#f4d98b",0.18))
			_center_text("NOW! PRESS ACT",guardian_pos+Vector2(0,74),16,Color("#fff0b0"))
	draw_circle(beacon_pos,64,Color(data["accent"],0.10)); draw_circle(beacon_pos,39,Color(data["accent"],0.18))
	draw_arc(beacon_pos,30,0,TAU,48,data["accent"],4.0)
	draw_rect(Rect2(beacon_pos.x-9,beacon_pos.y-30,18,60),Color("#e7d9a0")); draw_circle(beacon_pos+Vector2(0,-27),10,Color("#fff2b0"))
	draw_circle(beacon_pos, 72 + sin(animation_time * 2.5) * 5.0, Color(data["accent"], 0.045))
	CharacterArt.draw_player(self, player_pos, player_moving, animation_time, hazard_invulnerability > 0.0, shield_timer > 0.0)
	_draw_particles()
	_draw_mobile_controls()

func _draw_particles() -> void:
	for particle in particles:
		var alpha := clampf(float(particle["life"]) / maxf(0.01, float(particle["max_life"])), 0.0, 1.0)
		var tint: Color = particle["color"]
		tint.a = alpha
		draw_circle(particle["pos"], float(particle["size"]) * alpha, tint)

func _draw_mobile_controls() -> void:
	if state != "playing" or not DisplayServer.is_touchscreen_available(): return
	var jc := Vector2(165,575)
	draw_circle(jc,78,Color(0.02,0.04,0.08,0.38))
	draw_arc(jc,78,0,TAU,56,Color(0.75,0.85,0.92,0.45),3.0)
	var knob := jc+touch_vector*38.0
	draw_circle(knob,28,Color(0.96,0.85,0.55,0.38))
	draw_arc(knob,28,0,TAU,32,Color(1.0,0.93,0.7,0.7),2.0)
	var ac := Vector2(1090,590)
	draw_circle(ac,62,Color(0.96,0.85,0.55,0.16))
	draw_arc(ac,62,0,TAU,56,Color(UIArt.GOLD,0.75),3.0)
	UIArt.text(self,"ACT",ac+Vector2(0,7),20,Color("#fff1bd"),1,true)

func _draw_hud() -> void:
	var data: Dictionary = LEVELS[level_index]
	var accent: Color = data["accent"]

	# Top band: everything below y=105 belongs to the playfield.
	draw_rect(Rect2(0,0,1280,105),Color(0.02,0.035,0.075,0.97))
	draw_rect(Rect2(0,101,1280,2),Color(accent,0.12))
	draw_rect(Rect2(0,103,1280,2),Color(accent,0.60))

	# Left card: motes, lives, energy.
	UIArt.box(self,Rect2(18,9,300,88),"panel")
	UIArt.mote(self,Vector2(42,30),7.0)
	UIArt.text(self,"LIGHT MOTES",Vector2(58,35),12,UIArt.MUTED,0,true,false)
	UIArt.text(self,"%d / %d" % [collected,total_motes],Vector2(300,39),22,UIArt.GOLD,2,true)
	for i in range(maxi(3,lives)):
		UIArt.lantern(self,Vector2(42.0+float(i)*26.0,56),i < lives,animation_time,0.8)
	UIArt.text(self,"LIVES",Vector2(120,61),11,UIArt.MUTED,0,true,false)
	var low := lantern_energy <= 30.0
	var pulse := 0.5+0.5*sin(animation_time*8.0)
	var ecol := UIArt.DANGER.lerp(Color("#ffc2bb"),pulse) if low else Color("#f4c96b")
	UIArt.mote(self,Vector2(42,81),5.0,ecol)
	UIArt.bar(self,Rect2(58,73,190,16),lantern_energy/MAX_LANTERN_ENERGY,ecol)
	UIArt.text(self,"%d%%" % int(lantern_energy),Vector2(300,86),13,ecol,2,true,false)

	# Center: region title, goal, flavour.
	var goal := String(data["goal"])
	UIArt.text(self,String(data["name"]),Vector2(640,40),24,Color("#f1f5f8"),1,true)
	UIArt.text(self,goal,Vector2(640,66),UIArt.fit_size(goal,660,15,11),Color("#d3e0e8"),1)
	UIArt.text(self,String(data["subtitle"]),Vector2(640,89),12,UIArt.MUTED,1,false,false)

	# Right: actions + run status.
	_btn("pause","PAUSE",false,"pause",17)
	_btn("sound","SOUND",false,"sound_on" if sound_on else "sound_off",17)
	UIArt.box(self,Rect2(1018,60,242,38),"toast")
	UIArt.text(self,"REGION %d / 3" % (level_index+1),Vector2(1034,79),12,Color("#b8d2df"),0,true,false)
	UIArt.text(self,"TIME %s" % _format_time(total_time),Vector2(1244,79),12,UIArt.GOLD,2,true,false)
	UIArt.bar(self,Rect2(1032,85,210,8),float(collected)/maxf(1.0,float(total_motes)),UIArt.MINT)
	if guardian_active and guardian_health > 0:
		UIArt.box(self,Rect2(1018,116,242,32),"toast")
		UIArt.text(self,"GUARDIAN",Vector2(1034,137),13,Color("#e2b8ef"),0,true,false)
		for i in range(3):
			UIArt.mote(self,Vector2(1190.0+float(i)*22.0,132),6.0,Color("#e2b8ef") if i < guardian_health else Color("#3a2c48"))
	elif shield_timer > 0.0 or speed_timer > 0.0:
		UIArt.box(self,Rect2(1018,116,242,32),"toast")
		var effect_text := "SHIELD %.0fs" % shield_timer if shield_timer > 0.0 else "SPEED %.0fs" % speed_timer
		UIArt.text(self,effect_text,Vector2(1034,137),14,Color("#c7d8ff"),0,true,false)

	# Low-energy warning pulses around the playfield.
	if low and state == "playing":
		draw_rect(WORLD_RECT.grow(-3.0),Color(UIArt.DANGER,0.10+0.08*sin(animation_time*6.0)),false,6.0)

func _draw_toast() -> void:
	var accent: Color = LEVELS[level_index]["accent"]
	var size := UIArt.fit_size(message,780,17,12,true)
	var w := minf(860.0,UIArt.text_width(message,size,true)+70.0)
	var r := Rect2(640.0-w*0.5,118,w,40)
	UIArt.box(self,r,"toast")
	draw_rect(Rect2(r.position+Vector2(12,9),Vector2(4,22)),accent)
	UIArt.text(self,message,Vector2(640.0+6.0,r.position.y+26.0),size,Color("#f2f4e9"),1,true)

func _draw_overlay_card(card: Rect2,title: String,subtitle: String,chips: Array,title_col: Color = UIArt.GOLD) -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.01,0.02,0.045,0.80))
	UIArt.box(self,card,"panel")
	var cx := card.position.x+card.size.x*0.5
	UIArt.text(self,title,Vector2(cx,card.position.y+72.0),UIArt.fit_size(title,card.size.x-60.0,40,24,true),title_col,1,true)
	UIArt.divider(self,cx,card.position.y+94.0,300)
	UIArt.text(self,subtitle,Vector2(cx,card.position.y+128.0),UIArt.fit_size(subtitle,card.size.x-60.0,18,13),UIArt.TEXT,1)
	var n := chips.size()
	var cw := 150.0
	var gap := 12.0
	var x0 := cx-(float(n)*cw+float(n-1)*gap)*0.5
	for i in range(n):
		var c: Array = chips[i]
		UIArt.chip(self,Rect2(x0+float(i)*(cw+gap),card.position.y+142.0,cw,44),String(c[0]),String(c[1]))

func _draw_stars(cx: float,y: float,count: int) -> void:
	for i in range(3):
		UIArt.star(self,Vector2(cx+float(i-1)*58.0,y),20.0,i < count,animation_time)

func _draw_pause() -> void:
	_draw_overlay_card(Rect2(340,150,600,420),"PAUSED","Your lantern is safe.",[["JOURNEY TIME",_format_time(total_time)]])
	_btn("resume","RESUME",true)
	_btn("restart","RESTART REGION")
	_btn("main_menu","MAIN MENU")

func _draw_level_complete() -> void:
	_draw_overlay_card(Rect2(340,150,600,420),"BEACON RESTORED","The darkness retreats. A new region awakens.",[["TIME",_format_time(level_time)],["SCORE",str(run_score)],["MOTES","%d / %d" % [collected,total_motes]]])
	_draw_stars(640.0,374.0,level_stars)
	_btn("next","NEXT REGION",true)
	_btn("main_menu","MAIN MENU")

func _draw_game_over() -> void:
	var tips := ["Motes refill your lantern energy.","Watch a wisp's pattern before you cross its path.","Blue orbs speed you up. Purple ones shield one hit."]
	_draw_overlay_card(Rect2(340,150,600,420),"LIGHT FADING","The shadows overwhelmed your lantern.",[["TIME",_format_time(total_time)],["SCORE",str(run_score)]],Color("#f2a99f"))
	UIArt.text(self,"TIP: %s" % tips[level_index % tips.size()],Vector2(640,378),14,UIArt.MUTED,1)
	_btn("retry","RETRY REGION",true)
	_btn("main_menu","MAIN MENU")

func _draw_victory() -> void:
	_draw_overlay_card(Rect2(340,150,600,490),"THE WORLD REMEMBERS","You restored the last light. The night is no longer endless.",[["TIME",_format_time(total_time)],["SCORE",str(last_score)],["BEST SCORE",str(best_score)]])
	_draw_stars(640.0,370.0,level_stars)
	UIArt.text(self,"Best time %s" % _format_time(best_time),Vector2(640,408),13,Color("#b9e8d7"),1)
	_btn("retry","PLAY AGAIN",true)
	_btn("main_menu","MAIN MENU")
	_btn("credits","VIEW CREDITS")

func _draw_panel(rect: Rect2,_color: Color = Color.WHITE) -> void:
	UIArt.box(self,rect,"panel")

func _center_text(value: String,pos: Vector2,size: int,color: Color) -> void:
	UIArt.text(self,value,pos,size,color,1)

func _left_text(value: String,pos: Vector2,size: int,color: Color) -> void:
	UIArt.text(self,value,pos,size,color,0)

func _format_time(seconds: float) -> String:
	var whole := maxi(0,int(seconds))
	return "%02d:%02d" % [floori(float(whole)/60.0),whole%60]
