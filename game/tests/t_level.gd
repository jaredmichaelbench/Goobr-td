extends SceneTree
# L3 bot: plays the Night Life level (LevelRun) at 1x like a fair player. Args: hit
# chance, parry chance. Prints the parsed level, each section as it starts (with the
# song bar it started on, which should be whole), each push cleared, the music calm
# and low-pass in the lulls, and the end: card, results title.
var m; var f := 0; var p_hit := 0.7; var p_parry := 0.7
var plan := {}; var parry_plan := {}; var rng := RandomNumberGenerator.new()
var last_section := -1; var picked := false; var calm_seen := 0.0; var cut_seen := 20000.0
func _init():
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: p_hit = float(args[0])
	if args.size() > 1: p_parry = float(args[1])
	if args.size() > 2: LevelRun.level_path = args[2]
	rng.seed = 11
	M7Run.quick = false
	LevelRun.active = true
	m = LevelRun.new(); root.add_child(m)
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
	if m.structures.size() >= 6 and m.gold > 120:
		for t in types:
			if m.type_rank[t] < 5 and m.towers_of(t) > 1: m.upgrade_type(t, 1 if m.type_rank[t] == 2 else 0)
func talents():
	while m.points > 0:
		var took := false
		for area in ["towers", "rhythm", "defence", "economy", "walls"]:
			var ids := []
			for id in TalentTree.nodes():
				if TalentTree.nodes()[id]["areas"].has(area) and TalentTree.available(id, m.owned): ids.append(id)
			ids.sort()
			if not ids.is_empty():
				took = m.take_talent(ids[0]); break
		if not took: break
func _process(_d):
	f += 1
	if f == 2:
		var n: Dictionary = m.night
		print("LEVEL %s song '%s' (%s) count %d bars %d song %.1f bars problems %s" % [n["name"], n["song"], m.songs[m.song_index]["name"], n["count"], n["bars"], m.song_seconds / m.clock.bar_length(), n["problems"]])
		for s in n["sections"]:
			print("  %-10s %-6s bar %3d +%2d tier %d boss %s spawns %.0f beats (%.1f bars)" % [s["name"], s["kind"], s["start"] + 1, s["bars"], s["tier"], s["boss"], m.spawn_beats(s), m.spawn_beats(s) / 4.0])
		print("BUILD before start allowed: %s" % m.try_place(Vector2i(5, 5), "kick"))
		m.start_wave()
		print("START song_start %.2f  bar %.2f" % [m.song_start, m.song_bar()])
		spend()
	if f < 3: return
	if m.section != last_section:
		last_section = m.section
		var s: Dictionary = m.current_section()
		print("SECTION %-10s at song bar %.3f  t %.1f  health %d gold %d towers %d creeps %d level %d" % [s["name"], m.song_bar(), m.beat_time() - m.song_start, m.health, m.gold, m.structures.size(), m.creeps.size(), m.level])
		calm_seen = 0.0; cut_seen = 20000.0
		spend()
	if m.current_section().get("kind", "") == "lull":
		if calm_seen >= 0.0: calm_seen = maxf(calm_seen, m.calm()); cut_seen = minf(cut_seen, m._lowpass.cutoff_hz if m._lowpass else 20000.0)
		if m.song_bar() > m.current_section()["start"] + m.current_section()["bars"] - 0.05 and calm_seen >= 0.0:
			print("  LULL calm max %.2f cutoff min %.0f Hz, now calm %.2f" % [calm_seen, cut_seen, m.calm()]); calm_seen = -1.0
	if m.night_phase == "summary" and f % 60 == 0:
		talents()
		print("SUMMARY level %d points left %d  %s" % [m.level, m.points, m.miss_line()])
		m.begin_card()
	if m.boss_alive() and f % 120 == 0:
		print("  BOSS bar %.1f path left %.1f speed %.2f at keep %s health %d hp %.0f%%" % [m.song_bar(), m.boss_path_left(), m.boss["speed"], m.boss.get("at_goal", false), m.health, 100.0 * m.boss["hp"] / m.boss["max_hp"]])
	if m.drafting and f % 30 == 0 and not picked:
		picked = true
		print("CARD offered %s" % [m.draft_cards.map(func(c): return c["name"])])
		m._pick(0)
	if f % 200 == 0: spend()
	var pt: float = m.press_time()
	for n in m.notes:
		if n["state"] != "open" or not (n["tower"] is Vector2i): continue
		if not plan.has(n):
			plan[n] = (0.0 if rng.randf() < 0.45 else (0.05 if rng.randf() < 0.5 else -0.05)) if rng.randf() < p_hit else null
		if plan[n] != null and pt >= n["time"] + plan[n]:
			m._play(m.KEYS[n["type"]]); break
	if not m._counter_open.is_empty() and rng.randf() < 0.08: m._parry()
	for cand in m._parry_candidates():
		var key = cand.get("ref", cand)
		if not parry_plan.has(key): parry_plan[key] = rng.randf() < p_parry
		if parry_plan[key] and absf(pt - cand["time"]) < 0.012: m._parry(); break
	if not m.suppressed.is_empty() and f % 60 == 0: m._press_restore()
	if m.state != "playing" or m.beat_time() - m.song_start > 400.0:
		print("END state %s at song %.1f s (song is %.1f s) health %d notes %d/%d nailed %d/%d boss breaks %d" % [m.state, m.beat_time() - m.song_start, m.song_seconds, m.health, m.stat_total("hits"), m.stat_total("notes"), m.phrase_stats["nailed"], m.phrase_stats["calls"], m.m5_stats["breaks"]])
		for l in m.run_lines().slice(0, 6): print("  " + l)
		quit()
