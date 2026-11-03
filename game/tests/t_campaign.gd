extends SceneTree
# B1+B2 bot: plays the five-night campaign start to finish at 1x like a fair
# player, carrying state night to night the way Campaign.advance does (without the
# scene reload). Args: hit chance, parry chance, first night (1-5), last night.
# Prints each night's sections, the morning (points, talents taken), the card
# pick, upgrades bought, the B2 enemy counters and the end of every night.
var m; var f := 0; var p_hit := 0.75; var p_parry := 0.75; var last_night := 5
var plan := {}; var parry_plan := {}; var rng := RandomNumberGenerator.new()
var tough := false
var last_section := -1; var picked := false; var talked := false
func _init():
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: p_hit = float(args[0])
	if args.size() > 1: p_parry = float(args[1])
	var first := 1
	if args.size() > 2: first = int(args[2])
	if args.size() > 3: last_night = int(args[3])
	if args.size() > 4: tough = args[4] == "tough"
	rng.seed = 11
	M7Run.quick = false
	Campaign.begin(first - 1)
	_make()
func _make():
	m = NightRun.new(); root.add_child(m)
	f = 0; last_section = -1; picked = false; talked = false; plan = {}; parry_plan = {}
func best_cell(range_: float) -> Vector2i:
	var route = m.grid.route(); var best := Vector2i(-1, -1); var best_n := -1
	for x in m.GRID_SIZE.x:
		for y in m.GRID_SIZE.y:
			var c := Vector2i(x, y)
			if m.terrain.has(c) or m.structures.has(c) or c == m.SPAWN or c == m.GOAL or route.has(c) or not m.in_reach(c): continue
			var n := 0
			for r in route:
				if Vector2(r).distance_to(Vector2(c)) <= range_: n += 1
			if n > best_n: best_n = n; best = c
	return best
func spend():
	var types := []
	for t in ["kick", "bass", "slow", "poison", "lightning", "light"]:
		if m.unlocked.has(t): types.append(t)
	var i := 0
	while i < 30:
		var type: String = types[m.structures.size() % types.size()]
		if type == "light" and m.towers_of("light") >= 2: type = "kick"
		if m.gold < m.builds[type]["cost"]: break
		var c := best_cell(m.builds[type]["range"])
		if c.x < 0 or not m.try_place(c, type): break
		i += 1
	if m.structures.size() >= 5:
		for t in types:
			if t != "light" and m.type_rank[t] < 2 and m.towers_of(t) >= 2 and m.gold >= m.type_upgrade_cost(t) + 20:
				if m.upgrade_type(t, 1 + (m.towers_of(t) % 2)):
					print("  UPGRADE %s -> %s" % [m.tower_name(t), m.rank_label(t)])
func talents():
	# Towers first (Counter Attack, then up the left), like a tower player.
	var order := ["counter_attack", "well_constructed", "extended_reach", "pickup", "unlock_poison", "perfect_solo", "unlock_lightning", "improved_poison", "unlock_light", "improved_light", "improved_lightning", "thorny_walls"]
	var took := []
	for id in order:
		if m.points <= 0: break
		if m.take_night_talent(id): took.append(id)
	print("MORNING night %d at bar %.1f of %d  health %d (repaired %d)  level %d points left %d took %s" % [Campaign.night_number(), m.song_bar(), m.night["bars"], m.health, m.repaired, m.level, m.points, took])
var wait := 0
func _process(_d):
	if m == null:
		wait -= 1
		if wait <= 0: _make()
		return
	f += 1
	if f == 2:
		if tough: m.health = 99
		var n: Dictionary = m.night
		print("=== NIGHT %d %s song '%s' bars %d song %.1f bars gold %d health %d level %d talents %s cards %s problems %s" % [Campaign.night_number(), n["name"], m.songs[m.song_index]["name"], n["bars"], m.song_seconds / m.clock.bar_length(), m.gold, m.health, m.level, m.night_owned, m.card_picks, n["problems"]])
		print("  unlocked %s counter %s" % [m.unlocked, m.gstats.get("counter", false)])
		m.start_wave()
		spend()
	if f < 3: return
	if m.section != last_section:
		last_section = m.section
		var s: Dictionary = m.current_section()
		print("SECTION %-10s bar %.2f health %d gold %d towers %d creeps %d" % [s.get("name", "?"), m.song_bar(), m.health, m.gold, m.structures.size(), m.creeps.size()])
		spend()
	if m.night_phase == "summary" and not talked and f % 30 == 0:
		talked = true
		talents()
		m.begin_card()
		if not m.drafting: print("NO CARD (last night)")
	if m.drafting and f % 30 == 0 and not picked:
		picked = true
		print("CARD offered %s" % [m.draft_cards.map(func(c): return "%s (%s)" % [c["name"], c["night_rarity"]])])
		m._pick(0)
	if m.boss_alive() and f % 600 == 0:
		print("  BOSS %s bar %.1f path left %.1f hp %.0f%% breaks %d" % [m.boss_name(), m.song_bar(), m.boss_path_left(), 100.0 * m.boss["hp"] / m.boss["max_hp"], m.m5_stats["breaks"]])
	if f % 200 == 0: spend()
	var pt: float = m.press_time()
	for n in m.notes:
		if n["state"] != "open" or not (n["tower"] is Vector2i): continue
		if not n.has("_bot"):
			n["_bot"] = (0.0 if rng.randf() < 0.45 else (0.05 if rng.randf() < 0.5 else -0.05)) if rng.randf() < p_hit else 99.0
		if n["_bot"] < 50.0 and pt >= n["time"] + n["_bot"]:
			m._play(m.KEYS[n["type"]]); break
	if not m._counter_open.is_empty() and m._counter_open.has("at") and absf(m.press_time() - m._counter_open["at"]) < 0.012:
		if not m._counter_open.has("_bot"): m._counter_open["_bot"] = rng.randf() < p_parry
		if m._counter_open["_bot"]: m._parry()
	for cand in m._parry_candidates():
		var key = cand.get("ref", cand)
		if not key.has("_bot"): key["_bot"] = rng.randf() < p_parry
		if key["_bot"] and absf(pt - cand["time"]) < 0.012: m._parry(); break
	if not m.suppressed.is_empty() and f % 60 == 0: m._press_restore()
	if m.state != "playing" or m.beat_time() - m.song_start > 600.0:
		var t: Dictionary = m._totals()
		print("END night %d bar %.1f of %d state %s health %d notes %d/%d parries %d/%d breaks %d" % [Campaign.night_number(), m.song_bar(), m.night["bars"], m.state, m.health, t["hits"], t["notes"], t["parried"], t["throws"], m.m5_stats["breaks"]])
		for l in m.run_lines(): if l.begins_with("Talents") or l.begins_with("Cards") or l.begins_with("Upgrades") or l.begins_with("Enemies") or l.begins_with("Campaign"): print("  " + l)
		if m.state == "won" and not Campaign.is_last() and Campaign.night_number() < last_night:
			Campaign.history.append(m.night_summary())
			Campaign.carry = Campaign.capture(m)
			Campaign.index += 1
			Campaign.start_of_night = Campaign.carry.duplicate(true)
			LevelRun.level_path = Campaign.NIGHTS[Campaign.index]
			m.queue_free()
			m = null
			wait = 3
			return
		quit()
