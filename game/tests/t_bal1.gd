extends SceneTree
# Demo 1 balance bot (D-0046): plays the 20-wave RunSim at 1x like a fair player.
# Args: hit chance (0..1), parry chance, label. Lands a share of notes (most Good,
# some Perfect), parries a share of throws, taps a counter after half the parries,
# builds every unlocked type, upgrades types, spends talents, takes the rarest card.
# Prints one line per wave: fight time, health, notes, calls nailed.
var m; var f := 0; var last_wave := 0; var p_hit := 0.6; var p_parry := 0.65; var label := ""
var plan := {}  # note -> press offset in seconds, or null for a deliberate miss
var parry_plan := {}
var wave_t0 := 0.0; var run_t0 := -1.0; var base := {}
var rng := RandomNumberGenerator.new()
func _init():
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: p_hit = float(args[0])
	if args.size() > 1: p_parry = float(args[1])
	if args.size() > 2: label = args[2]
	if args.size() > 3 and args[3] == "legacy": RunSim.legacy = true
	rng.seed = 7
	M7Run.quick = false
	m = RunSim.new(); root.add_child(m)
func best_cell(range_: float) -> Vector2i:
	var route = m.grid.route(); var best := Vector2i(-1, -1); var best_n := -1
	for x in m.GRID_SIZE.x:
		for y in m.GRID_SIZE.y:
			var c := Vector2i(x, y)
			if m.terrain.has(c) or m.structures.has(c) or c == m.SPAWN or c == m.GOAL or route.has(c): continue
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
		if m.gold < m.builds[type]["cost"] + (0 if m.wave <= 3 else 40): break
		var c := best_cell(m.builds[type]["range"])
		if c.x < 0 or not m.try_place(c, type): break
		i += 1
	upgrade_types()
func upgrade_types():
	if m.structures.size() < 6: return
	var guard := 0
	while m.gold > 120 and guard < 10:
		guard += 1
		var best := ""; var best_n := 0
		for t in ["kick", "bass", "slow", "poison", "lightning", "light"]:
			if m.unlocked.has(t) and m.towers_of(t) > best_n and m.type_rank[t] < 5: best = t; best_n = m.towers_of(t)
		if best == "": break
		if not m.upgrade_type(best, 1 if m.type_rank[best] == 2 else 0): break
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
func totals() -> Dictionary:
	return {"hits": m.stat_total("hits"), "notes": m.stat_total("notes"), "nailed": m.phrase_stats["nailed"], "calls": m.phrase_stats["calls"] + m.phrase_stats["staggers"], "health": m.health}
func _process(_d):
	f += 1
	if f == 2:
		m.auto_send = true; spend()
	if run_t0 < 0.0 and m.wave_active: run_t0 = m.beat_time()
	if m.drafting and f % 30 == 0:
		var idx := 0
		for i in m.draft_cards.size():
			if CardPool.rarity_index(m.draft_cards[i]["rarity"]) > CardPool.rarity_index(m.draft_cards[idx]["rarity"]) and not m.draft_cards[i].has("cond"): idx = i
		m._pick(idx); spend()
	if m.wave_active and m.wave != last_wave:
		last_wave = m.wave; wave_t0 = m.beat_time(); base = totals(); spend()
	if not m.wave_active and not base.is_empty():
		var t := totals()
		print("%s W%d fight %4.0fs health %2d (-%d) notes %d/%d calls %d/%d towers %d level %d boss %s" % [label, last_wave, m.beat_time() - wave_t0, t["health"], base["health"] - t["health"], t["hits"] - base["hits"], t["notes"] - base["notes"], t["nailed"] - base["nailed"], t["calls"] - base["calls"], m.structures.size(), m.level, m.boss_waves.has(last_wave)])
		base = {}
	if f % 90 == 0: talents()
	if f % 300 == 0: spend()
	var pt: float = m.press_time()
	for n in m.notes:
		if n["state"] != "open" or not (n["tower"] is Vector2i): continue
		if not plan.has(n):
			if rng.randf() < p_hit:
				plan[n] = 0.0 if rng.randf() < 0.45 else (0.055 if rng.randf() < 0.5 else -0.055)
			else:
				plan[n] = null
		if plan[n] != null and pt >= n["time"] + plan[n]:
			m._play(m.KEYS[n["type"]]); break
	if not m._counter_open.is_empty() and rng.randf() < 0.08: m._parry()
	for cand in m._parry_candidates():
		var key = cand.get("ref", cand)
		if not parry_plan.has(key): parry_plan[key] = rng.randf() < p_parry
		if parry_plan[key] and absf(pt - cand["time"]) < 0.012: m._parry(); break
	if not m.suppressed.is_empty() and f % 60 == 0: m._press_restore()
	if m.state != "playing" or m.wave > 20:
		print("%s END state %s wave %d health %d time %.0fs nailed %d/%d staggers %d" % [label, m.state, m.wave, m.health, m.beat_time() - run_t0, m.phrase_stats["nailed"], m.phrase_stats["calls"], m.phrase_stats["staggers"]])
		quit()
