extends Node3D
## Demo 1 title screen (M10): the keep and a few towers in 3D behind the menu, a
## song from audio/ playing quietly. Play (20 waves), Quick run (10), How to play,
## Settings, Credits, Quit. D opens the developer menu with the Demo 0 milestones.

const GAME_NAME := "Goobr TD"  # Working title until Jared names it (Demo 1 plan, question 9).
const HOW_TO_PLAY := """[b]Hold the keep.[/b] Skeletons walk from the mine on the left to the Conductor's keep on the right. Every one that gets in costs health. Build walls and towers to make them walk a long maze, and keep the towers in the fight.

[b]Build.[/b] Click a button on the command card (bottom right), press its number, or press [b]B[/b] then its letter (W wall, C Cannon, S Splash, F Frost, V Poison, L Lightning, G Light). Click the board to place. Right click sells for 75%. Walls are limited.

[b]Notes (Q and E).[/b] A few times a bar a tower gets a disc with Q or E over it and a ring closing in. Press that key as the ring lands and the tower fires a shot across the whole board at the creep nearest the keep. A Perfect is a crit. A miss only costs the bonus.

[b]Parry (Space).[/b] Elites throw at your towers, Archers shoot at the keep and bosses fire bolts down your maze. A red ring closes and four pips count the bar down. Press Space as it lands: the attack goes back at them. Miss and the tower locks for a few seconds (or the keep loses a shield). Press Space again straight after a landed parry for a counter-attack.

[b]The bar.[/b] Beat 1 is for parries, beats 2 to 4 for notes; the strip under the top bar lights the beat you are on.

[b]Restore (F).[/b] Relights every locked tower with a free salvo. You get a charge back each wave.

[b]Getting stronger.[/b] Upgrades are per tower type: select a tower and press U (at rung 3 pick a fork with U or I). Kills give XP; each level is a talent point (Tab opens the tree). After bosses and a few other waves you draft one card.

[b]Bosses[/b] come every fifth wave. Parry their bolts to fill the posture bar; a posture break staggers them and opens a Crescendo: hit the notes for big damage.

P pauses. Esc twice leaves the run. F11 toggles full screen."""

var cam: Camera3D
var t := 0.0
var music: AudioStreamPlayer
var overlay: PanelContainer
var overlay_title: Label
var overlay_body: Container
var calib_label: Label


func _ready() -> void:
	Prefs.ensure()
	get_tree().paused = false
	_build_backdrop()
	_build_menu()
	_start_music()


func _build_backdrop() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -35, 0)
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.62, 0.8)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.84, 0.95)
	e.ambient_light_energy = 0.45
	e.fog_enabled = true
	e.fog_light_color = Color(0.55, 0.68, 0.82)
	e.fog_density = 0.012
	env.environment = e
	add_child(env)
	var ground := PlaneMesh.new()
	ground.size = Vector2(120, 120)
	var gm := MeshInstance3D.new()
	gm.mesh = ground
	gm.material_override = View3D.flat(Color(0.36, 0.54, 0.3))
	add_child(gm)
	var road := PlaneMesh.new()
	road.size = Vector2(1.2, 30)
	var rm := MeshInstance3D.new()
	rm.mesh = road
	rm.material_override = View3D.flat(View3D.DIRT)
	rm.position = Vector3(0, 0.01, 8)
	add_child(rm)
	var castle := Art.make(Art.CASTLE, 4.0)
	if castle != null:
		add_child(castle)
	var mage_ps := Art.scene(Art.CONDUCTOR)
	if mage_ps != null:
		var mage: Node3D = mage_ps.instantiate()
		mage.scale = Vector3.ONE * (1.6 / maxf(Art.aabb(mage).size.y, 0.01))
		mage.position = Vector3(0, 0, 2.6)
		add_child(mage)
		var ap: AnimationPlayer = mage.find_child("AnimationPlayer", true, false)
		if ap != null and ap.has_animation("Spellcasting"):
			ap.get_animation("Spellcasting").loop_mode = Animation.LOOP_LINEAR
			ap.play("Spellcasting")
	var spots := [[Vector3(-3.2, 0, 4.5), "kick"], [Vector3(3.4, 0, 4.0), "bass"], [Vector3(-3.6, 0, 9.0), "slow"], [Vector3(3.2, 0, 9.5), "lightning"], [Vector3(-2.8, 0, 14.0), "poison"], [Vector3(3.0, 0, 14.5), "light"]]
	for s in spots:
		var spec: Dictionary = Art.TOWERS[s[1]]
		var tower := Art.make(spec["model"], 1.4)
		if tower != null:
			tower.position = s[0]
			tower.rotation.y = randf() * TAU
			add_child(tower)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 40:
		var p := Vector3(rng.randf_range(-22, 22), 0, rng.randf_range(-14, 26))
		if absf(p.x) < 5.5 and p.z > -4.0:
			continue
		var m := Art.make(Art.DECOR[rng.randi() % Art.DECOR.size()], rng.randf_range(2.0, 3.5))
		if m != null:
			m.position = p
			m.rotation.y = rng.randf() * TAU
			add_child(m)
	for i in 6:
		var kind: String = ["grunt", "runner", "grunt", "brute", "shade", "grunt"][i]
		var sk := Art.character(kind)
		if sk == null:
			continue
		sk.position = Vector3(rng.randf_range(-0.3, 0.3), 0, 12.0 + i * 2.2)
		sk.rotation.y = PI
		sk.scale *= 1.3
		sk.set_meta("speed", 0.7 + rng.randf() * 0.3)
		sk.add_to_group("walkers")
		add_child(sk)
		var ap: AnimationPlayer = sk.find_child("AnimationPlayer", true, false)
		if ap != null:
			ap.play(Art.CREEPS[kind]["walk"])
	cam = Camera3D.new()
	cam.fov = 40
	add_child(cam)


func _process(delta: float) -> void:
	t += delta
	var ang := 0.55 + sin(t * 0.08) * 0.25
	cam.position = Vector3(sin(ang) * 15.0, 7.5, cos(ang) * 15.0 + 6.0)
	cam.look_at(Vector3(0, 1.2, 5.5), Vector3.UP)
	for sk in get_tree().get_nodes_in_group("walkers"):
		sk.position.z -= delta * float(sk.get_meta("speed"))
		if sk.position.z < 3.2:
			sk.position.z = 24.0


func _build_menu() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.theme = UiTheme.get_theme()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL_SOFT, UiTheme.EDGE, 2, 8, 22.0))
	side.position = Vector2(48, 60)
	root.add_child(side)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	side.add_child(v)
	v.add_child(UiTheme.heading(GAME_NAME, 56))
	var sub := Label.new()
	sub.text = "Rhythm tower defense.  Demo 1, private build."
	sub.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	v.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(1, 10)
	v.add_child(gap)
	for item in [["Play: the full run (20 waves)", _play.bind(false)], ["Quick run (10 waves)", _play.bind(true)], ["How to play", _show_help], ["Settings", _show_settings], ["Credits", _show_credits], ["Quit", func(): get_tree().quit()]]:
		var b := Button.new()
		b.text = item[0]
		b.custom_minimum_size = Vector2(320, 46)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(item[1])
		v.add_child(b)
	var foot := Label.new()
	foot.text = "D  developer menu (the Demo 0 milestones)"
	foot.add_theme_font_size_override("font_size", 11)
	foot.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	v.add_child(foot)
	# One overlay panel for How to play, Settings and Credits.
	overlay = PanelContainer.new()
	overlay.visible = false
	overlay.position = Vector2(440, 50)
	overlay.custom_minimum_size = Vector2(780, 600)
	root.add_child(overlay)
	var ov := VBoxContainer.new()
	ov.add_theme_constant_override("separation", 10)
	overlay.add_child(ov)
	var head := HBoxContainer.new()
	ov.add_child(head)
	overlay_title = UiTheme.heading("", 28)
	overlay_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(overlay_title)
	var close := Button.new()
	close.text = "Close  (Esc)"
	close.pressed.connect(func(): overlay.visible = false)
	head.add_child(close)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(750, 530)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ov.add_child(scroll)
	overlay_body = VBoxContainer.new()
	overlay_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay_body.add_theme_constant_override("separation", 12)
	scroll.add_child(overlay_body)


func _play(quick: bool) -> void:
	M7Run.quick = quick
	get_tree().change_scene_to_file("res://run3d.tscn")


func _open(title: String) -> void:
	overlay_title.text = title
	for c in overlay_body.get_children():
		c.queue_free()
	overlay.visible = true


func _rich(text: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.text = text
	r.add_theme_font_size_override("normal_font_size", 15)
	r.add_theme_font_size_override("bold_font_size", 15)
	r.add_theme_color_override("default_color", UiTheme.TEXT)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r


func _show_help() -> void:
	_open("How to play")
	overlay_body.add_child(_rich(HOW_TO_PLAY))


func _show_credits() -> void:
	_open("Credits")
	var text := """[b]Design and playtesting:[/b] Jared Bench.
[b]Built with[/b] Claude (Anthropic) and the Godot Engine.

[b]3D models:[/b] KayKit Medieval Hexagon Pack, Skeletons Character Pack and Adventurers Character Pack by Kay Lousberg (www.kaylousberg.com), CC0.
[b]Font:[/b] Lilita One by Juan Montoreano, SIL Open Font License 1.1.
[b]Music:[/b] SynthWave music pack by VOiD1 Gaming (void1gaming.com), used under licence.
[b]Sound effects:[/b] HALFTONE sound effects by VOiD1 Gaming, used under licence; synth voices made in code.

[b]Godot Engine[/b]
This game uses Godot Engine, available under the following license:

""" + Engine.get_license_text()
	overlay_body.add_child(_rich(text))


func _show_settings() -> void:
	_open("Settings")
	for s in [["Master volume", "master"], ["Music volume", "music"], ["Sound effects volume", "sfx"]]:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = s[0]
		l.custom_minimum_size = Vector2(240, 0)
		row.add_child(l)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Prefs.get_value(s[1])
		slider.custom_minimum_size = Vector2(320, 24)
		var key: String = s[1]
		slider.value_changed.connect(func(v): Prefs.set_value(key, v))
		row.add_child(slider)
		overlay_body.add_child(row)
	for s in [["Full screen (F11)", "fullscreen"], ["Synth note sounds (off: the sound pack's)", "synth_notes"], ["Key hints in the bottom panel", "key_hints"]]:
		var c := CheckBox.new()
		c.text = s[0]
		c.button_pressed = Prefs.get_value(s[1])
		var key: String = s[1]
		c.toggled.connect(func(on): Prefs.set_value(key, on))
		overlay_body.add_child(c)
	# Calibration is fixed for the demo (Timing.FIXED_CALIBRATION); the setting
	# comes back only when the constant is turned off.
	if not Timing.FIXED_CALIBRATION:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		calib_label = Label.new()
		calib_label.text = "Timing calibration: %+.0f ms" % Timing.load_calibration_ms()
		calib_label.custom_minimum_size = Vector2(240, 0)
		row.add_child(calib_label)
		var cal := Button.new()
		cal.text = "Calibrate (beat test)"
		cal.pressed.connect(func(): get_tree().change_scene_to_file("res://m1_beat_test.tscn"))
		row.add_child(cal)
		overlay_body.add_child(row)


func _start_music() -> void:
	var songs := AudioFiles.list_wavs("res://audio")
	if songs.is_empty():
		return
	var stream := AudioFiles.load_wav("res://audio/" + songs[randi() % songs.size()])
	if stream == null:
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	music = AudioStreamPlayer.new()
	music.stream = stream
	music.bus = "Music"
	music.volume_db = -30.0
	add_child(music)
	music.play()
	create_tween().tween_property(music, "volume_db", -8.0, 2.5)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE and overlay.visible:
		overlay.visible = false
	elif event.keycode == KEY_D:
		get_tree().change_scene_to_file("res://dev_menu.tscn")
