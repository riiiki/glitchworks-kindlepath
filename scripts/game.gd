extends Node2D

const EnvironmentArt = preload("res://scripts/environment_art.gd")
const CharacterArt = preload("res://scripts/character_art.gd")

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
var gate_rect := Rect2()
var gate_open := false
var crate_pos := Vector2.ZERO
var crate_active := false
var level_stars := 0
var font: Font
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
	font = ThemeDB.fallback_font
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
		"start":Rect2(490,330,300,54), "levels":Rect2(490,395,300,50), "tutorial":Rect2(490,455,300,50), "settings":Rect2(490,515,300,50),
		"back":Rect2(490,590,300,48), "next":Rect2(490,420,300,54), "retry":Rect2(490,420,300,54),
		"resume":Rect2(490,350,300,54), "restart":Rect2(490,416,300,54), "main_menu":Rect2(490,490,300,54),
		"sound":Rect2(1135,18,125,42), "pause":Rect2(1018,18,108,42),
		"music_minus":Rect2(610,300,52,48), "music_plus":Rect2(780,300,52,48),
		"sfx_toggle":Rect2(450,365,380,48), "music_toggle":Rect2(450,425,380,48),
		"fullscreen":Rect2(450,485,380,48), "level_0":Rect2(330,300,190,110), "level_1":Rect2(545,300,190,110), "level_2":Rect2(760,300,190,110)
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
	# A small environmental puzzle in every region: activate the switch to open its gate.
	var puzzle_positions := [Vector2(620,590),Vector2(600,210),Vector2(650,600)]
	var gate_positions := [Rect2(1010,300,35,150),Rect2(740,500,150,32),Rect2(510,500,35,130)]
	switch_pos = puzzle_positions[level_index]
	gate_rect = gate_positions[level_index]
	gate_open = false
	crate_active = true
	crate_pos = [Vector2(390,300),Vector2(920,320),Vector2(820,300)][level_index]
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
		_check_collectibles()
		_check_powerups()
		if player_pos.distance_to(LEVELS[level_index]["beacon"]) < 300.0 and checkpoint_pos == LEVELS[level_index]["player"]:
			checkpoint_pos = player_pos
			_say("Checkpoint reached! Your lantern is anchored here.",2.0)
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
	var next_pos := player_pos + direction * current_speed * delta
	next_pos.x = clampf(next_pos.x,WORLD_RECT.position.x+20.0,WORLD_RECT.end.x-20.0)
	next_pos.y = clampf(next_pos.y,WORLD_RECT.position.y+20.0,WORLD_RECT.end.y-20.0)
	var player_rect := Rect2(next_pos-Vector2(15,15),Vector2(30,30))
	for wall in walls:
		if player_rect.intersects(wall):
			var x_only := Rect2(Vector2(next_pos.x-15,player_pos.y-15),Vector2(30,30))
			var y_only := Rect2(Vector2(player_pos.x-15,next_pos.y-15),Vector2(30,30))
			if not y_only.intersects(wall):
				next_pos.x = player_pos.x
			elif not x_only.intersects(wall):
				next_pos.y = player_pos.y
			else:
				next_pos = player_pos
	if crate_active:
		var crate_rect := Rect2(crate_pos-Vector2(22,22),Vector2(44,44))
		if Rect2(next_pos-Vector2(15,15),Vector2(30,30)).intersects(crate_rect):
			var push := (next_pos-player_pos).normalized()*34.0
			var moved_crate := crate_pos+push
			var crate_blocked := false
			for wall in walls:
				if Rect2(moved_crate-Vector2(22,22),Vector2(44,44)).intersects(wall):
					crate_blocked = true
					break
			if not crate_blocked and WORLD_RECT.has_point(moved_crate):
				crate_pos = moved_crate
			else:
				next_pos = player_pos
	if not gate_open and Rect2(next_pos-Vector2(15,15),Vector2(30,30)).intersects(gate_rect):
		next_pos = player_pos
	player_pos = next_pos

func _update_hazards(delta: float) -> void:
	for i in range(hazards.size()):
		var base: Vector2 = LEVELS[level_index]["hazards"][i]
		var kind := i % 3
		var patrol_radius := 38.0 + float(level_index) * 7.0
		if kind == 0:
			# Wisps drift in broad, quick loops.
			hazards[i] = base + Vector2(sin(hazard_phase * (1.35 + i * 0.08) + i) * patrol_radius * 1.25, cos(hazard_phase * 1.15 + i) * 34.0)
		elif kind == 1 and fposmod(hazard_phase, 5.5) > 2.1 - float(level_index) * 0.25:
			# Stalkers briefly pursue the player, with a visible pause between pursuits.
			hazards[i] = hazards[i].move_toward(player_pos, delta * (62.0 + float(level_index) * 22.0))
		else:
			# Guardians hold territory and patrol a smaller area.
			hazards[i] = base + Vector2(sin(hazard_phase * 0.72 + i) * patrol_radius * 0.72, cos(hazard_phase * 0.8 + i) * 19.0)
		if hazard_invulnerability <= 0.0 and shield_timer <= 0.0 and player_pos.distance_to(hazards[i]) < 34.0:
			_hit_hazard()
			break

func _update_guardian(delta: float) -> void:
	if level_index != 2 or collected < total_motes or not gate_open or guardian_health <= 0:
		return
	guardian_active = true
	guardian_phase += delta
	guardian_attack_cooldown = maxf(0.0, guardian_attack_cooldown - delta)
	var orbit := beacon_pos + Vector2(cos(guardian_phase * 0.8) * 72.0, sin(guardian_phase * 1.1) * 46.0)
	guardian_pos = guardian_pos.move_toward(orbit, delta * 95.0)
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
	if player_pos.distance_to(switch_pos) < 62.0 and not gate_open:
		gate_open = true
		_spawn_burst(switch_pos, Color("#f4c96b"), 24)
		_play_sfx("beacon")
		_say("Switch activated! The sealed path is open.",2.0)
		return
	if level_index == 2 and collected >= total_motes and gate_open and guardian_health > 0 and player_pos.distance_to(guardian_pos) < 92.0:
		if guardian_attack_cooldown <= 0.0:
			guardian_health -= 1
			guardian_attack_cooldown = 0.85
			_spawn_burst(guardian_pos, Color("#f4c96b"), 18)
			_play_sfx("beacon")
			_say("Guardian weakened! %d light seal(s) remain." % guardian_health,1.5)
			if guardian_health <= 0:
				_spawn_burst(guardian_pos, Color("#f4d98b"), 55)
				_say("The summit guardian has been calmed. Reach the beacon!",2.5)
		return
	if player_pos.distance_to(beacon_pos) > 78.0:
		_say("Move closer to the beacon.",1.3)
		return
	if collected < total_motes:
		_say("The beacon needs %d more mote(s)." % (total_motes-collected),1.8)
		return
	if not gate_open:
		_say("Find the ancient switch and open the sealed path.",1.8)
		return
	if level_index == 2 and guardian_health > 0:
		_say("The summit guardian blocks the final beacon. Move close and press ACT!",2.0)
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
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE:
			if state == "playing": interact_requested = true
		elif event.keycode == KEY_ESCAPE:
			if state == "playing": state = "paused"
			elif state == "paused": state = "playing"
			elif state == "settings" or state == "levels" or state == "tutorial": state = "menu"
	if event is InputEventScreenTouch:
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
			_play_sfx("click"); _start_game(0); return true
		if buttons.levels.has_point(point):
			_play_sfx("click"); state = "levels"; return true
		if buttons.tutorial.has_point(point):
			_play_sfx("click"); state = "tutorial"; return true
		if buttons.settings.has_point(point):
			_play_sfx("click"); state = "settings"; return true
	elif state == "levels":
		for i in range(3):
			if buttons["level_%d" % i].has_point(point) and i <= unlocked_level:
				_play_sfx("click"); _start_game(i); return true
		if buttons.back.has_point(point): state = "menu"; return true
	elif state == "tutorial":
		if buttons.back.has_point(point): state = "menu"; _play_sfx("click"); return true
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
		if buttons.back.has_point(point): state = "menu"; return true
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
	return false

# Drawing -------------------------------------------------------------------------
func _draw() -> void:
	_draw_background()
	match state:
		"menu": _draw_menu()
		"levels": _draw_levels()
		"settings": _draw_settings()
		"tutorial": _draw_tutorial()
		_:
			_draw_world()
			_draw_hud()
			if state == "paused": _draw_pause()
			elif state == "level_complete": _draw_level_complete()
			elif state == "game_over": _draw_game_over()
			elif state == "victory": _draw_victory()
			if message_timer > 0.0 and state == "playing":
				_draw_panel(Rect2(330,92,620,44),Color(0.02,0.04,0.08,0.88))
				_center_text(message,Vector2(640,121),17,Color("#f2f4e9"))

func _draw_background() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#090e20"))
	for i in range(90):
		var x := float((i*173)%1280)
		var y := float((i*97)%720)
		var alpha := 0.18+0.12*sin(Time.get_ticks_msec()/900.0+i)
		draw_circle(Vector2(x,y),1.4,Color(0.75,0.84,1.0,alpha))
	draw_circle(Vector2(1080,80),95,Color("#1a2944",0.35))

func _draw_menu() -> void:
	_center_text("LANTERN KEEPER",Vector2(640,205),58,Color("#f4d98b"))
	_center_text("A LIGHT IN THE DARK",Vector2(640,250),18,Color("#8db9bd"))
	draw_circle(Vector2(640,310),48,Color("#f4c96b",0.12))
	draw_circle(Vector2(640,310),28,Color("#f4c96b",0.24))
	_draw_button(buttons.start,"BEGIN JOURNEY")
	_draw_button(buttons.levels,"SELECT LEVEL")
	_draw_button(buttons.tutorial,"HOW TO PLAY")
	_draw_button(buttons.settings,"SETTINGS")
	_center_text("WASD / ARROWS MOVE   •   E / SPACE INTERACT   •   ESC PAUSE",Vector2(640,625),14,Color("#a7b7c9"))
	_center_text("Unlocked: %d / 3     Best score: %d" % [unlocked_level+1,best_score],Vector2(640,655),14,Color("#c4d0d8"))

func _draw_levels() -> void:
	_center_text("CHOOSE YOUR REGION",Vector2(640,205),38,Color("#f4d98b"))
	for i in range(3):
		var r: Rect2 = buttons["level_%d" % i]
		var available := i <= unlocked_level
		draw_rect(r,Color("#29445a") if available else Color("#171f31"))
		draw_rect(r,Color("#65d6b0",0.8) if available else Color("#536071",0.5),false,2.0)
		_center_text("REGION %d" % (i+1),Vector2(r.position.x+r.size.x/2,r.position.y+38),18,Color("#f4d98b") if available else Color("#718096"))
		_center_text("UNLOCKED" if available else "LOCKED",Vector2(r.position.x+r.size.x/2,r.position.y+72),14,Color("#b9e8d7") if available else Color("#718096"))
		_center_text(LEVELS[i]["name"],Vector2(r.position.x+r.size.x/2,r.position.y+95),11,Color("#d3e0e8"))
	_draw_button(buttons.back,"BACK")

func _draw_settings() -> void:
	_draw_panel(Rect2(390,135,500,500),Color("#111d32"))
	_center_text("SETTINGS",Vector2(640,205),40,Color("#f4d98b"))
	_center_text("AUDIO & DISPLAY",Vector2(640,239),13,Color("#8faec4"))
	_center_text("MASTER VOLUME",Vector2(640,285),17,Color("#d3e0e8"))
	_draw_button(buttons.music_minus,"−")
	_draw_panel(Rect2(665,300,110,48),Color("#203650"))
	_center_text("%d%%" % int(master_volume*100),Vector2(720,331),18,Color("#f4d98b"))
	_draw_button(buttons.music_plus,"+")
	_draw_button(buttons.sfx_toggle,"SOUND EFFECTS     %s" % ("ON" if sound_on else "OFF"))
	_draw_button(buttons.music_toggle,"BACKGROUND MUSIC     %s" % ("ON" if music_on else "OFF"))
	_draw_button(buttons.fullscreen,"TOGGLE FULLSCREEN")
	_draw_button(buttons.back,"BACK TO MENU")

func _draw_tutorial() -> void:
	_draw_panel(Rect2(300,105,680,550),Color("#111d32"))
	_center_text("HOW TO PLAY",Vector2(640,165),40,Color("#f4d98b"))
	_center_text("RESTORE THE LIGHT ACROSS THREE REGIONS",Vector2(640,195),14,Color("#8faec4"))
	var rows := [
		["MOVE", "WASD / ARROW KEYS   •   TOUCH JOYSTICK ON MOBILE"],
		["INTERACT", "E / SPACE   •   ACTIVATE SWITCHES AND BEACONS"],
		["OBJECTIVE", "COLLECT EVERY LIGHT MOTE, THEN REACH THE BEACON"],
		["SURVIVE", "AVOID SHADOW WISPS   •   YOU HAVE THREE LANTERN LIVES"],
		["PUZZLES", "PUSH CRATES, ACTIVATE THE GOLD SWITCH, OPEN THE GATE"],
		["POWER-UPS", "BLUE = SPEED   •   PURPLE = ONE-HIT SHIELD"],
		["ENERGY", "COLLECT MOTES TO RESTORE LANTERN ENERGY"],
		["ENEMIES", "WISPS DRIFT • STALKERS CHASE • GUARDIANS GUARD PATHS"],
		["FINAL REGION", "AFTER MOTES + SWITCH, APPROACH THE SUMMIT GUARDIAN AND PRESS ACT 3 TIMES"]
	]
	var y := 245.0
	for row in rows:
		_left_text(row[0],Vector2(365,y),15,Color("#f4d98b"))
		_left_text(row[1],Vector2(485,y),13,Color("#d3e0e8"))
		draw_line(Vector2(360,y+13),Vector2(920,y+13),Color(0.7,0.8,0.9,0.12),1.0)
		y += 48.0
	_draw_button(buttons.back,"BACK TO MENU")

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
	# Puzzle gate and switch
	if not gate_open:
		draw_rect(gate_rect,Color("#b66d65"))
		draw_rect(gate_rect,Color("#f4c96b"),false,2.0)
	else:
		draw_rect(gate_rect,Color(0.4,0.8,0.65,0.12))
	draw_circle(switch_pos,23,Color("#f4c96b",0.22))
	draw_circle(switch_pos,11,Color("#f4c96b"))
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
		_center_text("GUARDIAN  " + "◆".repeat(guardian_health),guardian_pos+Vector2(0,-52),12,Color("#f5dca2"))
	draw_circle(beacon_pos,64,Color(data["accent"],0.10)); draw_circle(beacon_pos,39,Color(data["accent"],0.18))
	draw_arc(beacon_pos,30,0,TAU,48,data["accent"],4.0)
	draw_rect(Rect2(beacon_pos.x-9,beacon_pos.y-30,18,60),Color("#e7d9a0")); draw_circle(beacon_pos+Vector2(0,-27),10,Color("#fff2b0"))
	draw_circle(beacon_pos, 72 + sin(animation_time * 2.5) * 5.0, Color(data["accent"], 0.045))
	CharacterArt.draw_player(self, player_pos, player_moving, animation_time, hazard_invulnerability > 0.0, shield_timer > 0.0)
	_draw_particles()
	_draw_mobile_controls()
	# The world title stays in the dedicated top strip, clear of the map and HUD.
	_center_text(data["name"],Vector2(640,68),21,Color("#e8edf1"))
	_center_text(data["subtitle"],Vector2(640,94),12,Color("#a8bacb"))

func _draw_particles() -> void:
	for particle in particles:
		var alpha := clampf(float(particle["life"]) / maxf(0.01, float(particle["max_life"])), 0.0, 1.0)
		var tint: Color = particle["color"]
		tint.a = alpha
		draw_circle(particle["pos"], float(particle["size"]) * alpha, tint)

func _draw_mobile_controls() -> void:
	if state != "playing" or not DisplayServer.is_touchscreen_available(): return
	draw_circle(Vector2(165,575),72,Color(0.02,0.04,0.08,0.30))
	draw_arc(Vector2(165,575),72,0,TAU,48,Color(0.75,0.85,0.92,0.35),2.0)
	draw_circle(Vector2(165,575)+touch_vector*34,23,Color(0.75,0.85,0.92,0.30))
	draw_circle(Vector2(1090,590),55,Color("#f4d98b",0.16))
	draw_arc(Vector2(1090,590),55,0,TAU,48,Color("#f4d98b",0.55),2.0)
	_center_text("ACT",Vector2(1090,596),16,Color("#fff1bd"))

func _draw_hud() -> void:
	# Left status card: all health and energy information stays inside its panel.
	_draw_panel(Rect2(20,12,255,88),Color(0.02,0.04,0.08,0.94))
	_left_text("LIGHT MOTES  %d / %d" % [collected,total_motes],Vector2(38,37),16,Color("#f5df9a"))
	_left_text("LANTERN  %s" % "✦".repeat(lives),Vector2(38,61),13,Color("#d5e4ed"))
	_left_text("ENERGY %d%%" % int(lantern_energy),Vector2(38,81),11,Color("#f4d98b"))
	draw_rect(Rect2(38,87,190,6),Color("#25364b"))
	var energy_color := Color("#f4c96b") if lantern_energy > 30.0 else Color("#ed7c79")
	draw_rect(Rect2(38,87,190.0*lantern_energy/MAX_LANTERN_ENERGY,6),energy_color)
	draw_rect(Rect2(38,87,190,6),Color(1,1,1,0.18),false,1.0)

	# Center title/goal strip avoids the left status and right action buttons.
	_center_text(LEVELS[level_index]["goal"],Vector2(640,37),13,Color("#c6d3df"))

	# Top-right actions and compact run status are separated vertically.
	_draw_button(buttons.pause,"PAUSE")
	_draw_button(buttons.sound,"SOUND %s" % ("ON" if sound_on else "OFF"))
	_draw_panel(Rect2(1018,66,242,34),Color(0.02,0.04,0.08,0.90))
	_left_text("REGION %d / 3" % (level_index + 1),Vector2(1030,88),11,Color("#b8d2df"))
	_left_text("TIME %s" % _format_time(total_time),Vector2(1150,88),11,Color("#f5df9a"))
	draw_rect(Rect2(1030,92,214,4),Color("#25364b"))
	draw_rect(Rect2(1030,92,214.0 * float(collected) / maxf(1.0,float(total_motes)),4),Color("#65d6b0"))
	if guardian_active and guardian_health > 0:
		_left_text("GUARDIAN SEALS %d / 3" % guardian_health,Vector2(1030,108),11,Color("#e2b8ef"))
	elif shield_timer > 0.0:
		_left_text("SHIELD %.0fs" % shield_timer,Vector2(1030,108),11,Color("#c7a8ff"))
	elif speed_timer > 0.0:
		_left_text("SPEED %.0fs" % speed_timer,Vector2(1030,108),11,Color("#8de4f4"))

func _draw_pause() -> void:
	_draw_overlay("PAUSED","Your lantern is safe.","Journey time: %s" % _format_time(total_time))
	_draw_button(buttons.resume,"RESUME")
	_draw_button(buttons.restart,"RESTART REGION")
	_draw_button(buttons.main_menu,"MAIN MENU")

func _draw_level_complete() -> void:
	_draw_overlay("BEACON RESTORED","The darkness retreats. A new region awakens.","Region time: %s     Score: %d     Stars: %s" % [_format_time(level_time),run_score,"★".repeat(level_stars)])
	_draw_button(buttons.next,"NEXT REGION")
	_draw_button(buttons.main_menu,"MAIN MENU")

func _draw_game_over() -> void:
	_draw_overlay("LIGHT FADING","The shadows overwhelmed your lantern.","Time: %s     Score: %d" % [_format_time(total_time),run_score])
	_draw_button(buttons.retry,"RETRY REGION")
	_draw_button(buttons.main_menu,"MAIN MENU")

func _draw_victory() -> void:
	_draw_overlay("THE WORLD REMEMBERS","You restored the last light. The night is no longer endless.","Time: %s     Score: %d     Stars: %s" % [_format_time(total_time),last_score,"★".repeat(level_stars)])
	_center_text("BEST TIME: %s     BEST SCORE: %d" % [_format_time(best_time),best_score],Vector2(640,410),17,Color("#b9e8d7"))
	_draw_button(buttons.retry,"PLAY AGAIN")
	_draw_button(buttons.main_menu,"MAIN MENU")

func _draw_overlay(title: String,subtitle: String,footer: String) -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.015,0.025,0.055,0.82))
	_center_text(title,Vector2(640,265),42,Color("#f4d98b"))
	_center_text(subtitle,Vector2(640,315),18,Color("#d3e0e8"))
	_center_text(footer,Vector2(640,345),16,Color("#9db3c8"))

func _draw_button(rect: Rect2,label: String) -> void:
	draw_rect(rect,Color("#d9b96f"))
	draw_rect(Rect2(rect.position+Vector2(3,3),rect.size-Vector2(6,6)),Color("#27354b"))
	_center_text(label,rect.position+rect.size/2+Vector2(0,6),18,Color("#f7e8bc"))

func _draw_panel(rect: Rect2,color: Color) -> void:
	draw_rect(rect,color)
	draw_rect(rect,Color(0.75,0.85,0.95,0.22),false,1.0)

func _center_text(value: String,pos: Vector2,size: int,color: Color) -> void:
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	draw_string(font,pos-Vector2(width/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _left_text(value: String,pos: Vector2,size: int,color: Color) -> void:
	draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _format_time(seconds: float) -> String:
	var whole := maxi(0,int(seconds))
	return "%02d:%02d" % [floori(float(whole)/60.0),whole%60]
