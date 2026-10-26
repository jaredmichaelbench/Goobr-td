extends SceneTree
# M7 full run at 1x: perfect notes and parries, builds every unlocked type, upgrades types,
# spends talent points, picks the rarest card. Arg "quick" = the 10-wave run.
var m; var f := 0; var last_wave := 0; var picked := []; var area_order := ["towers", "defence", "rhythm", "economy", "walls"]
func _init():
	var args := OS.get_cmdline_user_args()
	M7Run.quick = args.size() > 0 and args[0] == "quick"
	m = load("res://m7_run.tscn").instantiate(); root.add_child(m)
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
	if m.wave % 2 == 0 and m.structures.size() >= 6: upgrade_types()
	var types := []
	for t in ["kick", "bass", "slow", "poison", "lightning", "light"]:
		if m.unlocked.has(t): types.append(t)
	var i := 0
	while i < 30:
		var type: String = types[m.structures.size() % types.size()]
		if type == "light" and m.towers_of("light") >= 2: type = "kick"
		if m.gold < m.builds[type]["cost"] + 60: break
		var c := best_cell(m.builds[type]["range"])
		if c.x < 0 or not m.try_place(c, type): break
		i += 1
	upgrade_types()
func upgrade_types():
	var types := []
	for t in ["kick", "bass", "slow", "poison", "lightning", "light"]:
		if m.unlocked.has(t): types.append(t)
	var guard := 0
	if m.structures.size() < 6: return
	while m.gold > 120 and guard < 10:
		guard += 1
		var best := ""; var best_n := 0
		for t in types:
			if m.towers_of(t) > best_n and m.type_rank[t] < 5: best = t; best_n = m.towers_of(t)
		if best == "": break
		var rank: int = m.type_rank[best]
		if not m.upgrade_type(best, 1 if rank == 2 else 0): break
func talents():
	while m.points > 0:
		var took := false
		for area in area_order:
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
		m.auto_send = true; spend()
	if m.drafting and f % 30 == 0:
		var idx := 0
		for i in m.draft_cards.size():
			if CardPool.rarity_index(m.draft_cards[i]["rarity"]) > CardPool.rarity_index(m.draft_cards[idx]["rarity"]) and not m.draft_cards[i].has("cond"): idx = i
		picked.append(m.draft_cards[idx]["id"]); m._pick(idx); spend()
	if m.wave != last_wave:
		print("WAVE %d start   t=%.0f health %d gold %d towers %d level %d points %d unlocked %s ranks %s owned %d" % [m.wave, m.beat_time(), m.health, m.gold, m.structures.size(), m.level, m.points, m.unlocked.slice(4), m.type_rank, m.owned.size()])
		last_wave = m.wave; spend()
	if f % 90 == 0: talents()
	if f % 300 == 0: spend()
	for n in m.notes:
		if n["state"] == "open" and n["tower"] is Vector2i and absf(m.press_time() - n["time"]) < 0.015:
			m._play(m.KEYS[n["type"]]); break
	if not m._counter_open.is_empty(): m._parry()
	for cand in m._parry_candidates():
		if absf(m.press_time() - cand["time"]) < 0.012: m._parry(); break
	if not m.suppressed.is_empty() and f % 60 == 0: m._press_restore()
	if m.state != "playing" or f > 200000:
		print("END state %s wave %d health %d picks %s" % [m.state, m.wave, m.health, picked])
		for l in m.run_lines(): print("END ", l)
		print("END m7 %s kills %s" % [m.m7_stats, m.kills])
		quit()
	return false
