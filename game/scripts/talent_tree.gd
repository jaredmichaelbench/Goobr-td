class_name TalentTree
## The per-run talent tree (D-0038, D-0039). Five areas, each a grid of three
## columns and four rows plus a capstone. A node needs one owned node in the
## row above it (same column or a neighbour); row 0 nodes are free to start
## from. LINKS add cross-area ways in, so a build can reach a neighbour area's
## early nodes without starting there. Counter-attack is the Defence area's
## early capstone and has links from three areas.
##
## Effects are stat bumps on the game's gstats dictionary, or flags. Numbers
## are placeholders for the M7 session; tune here, no code.

const AREAS: Array[String] = ["rhythm", "towers", "economy", "walls", "defence"]
const AREA_NAMES := {"rhythm": "Rhythm", "towers": "Towers", "economy": "Economy", "walls": "Walls", "defence": "Defence"}
const AREA_COLORS := {"rhythm": Color(1.0, 0.6, 0.35), "towers": Color(0.9, 0.8, 0.5), "economy": Color(1.0, 0.9, 0.3), "walls": Color(0.6, 0.65, 0.75), "defence": Color(0.5, 0.8, 1.0)}
const ROWS := 4
const COLS := 3

## [row][col] = [name, effects] per area. Row 0 is the top (the start).
const GRID := {
	"rhythm": [
		[["Pulse", {"note_rate": 1}], ["Accent", {"perfect_mult": 0.15}], ["Tempo", {"damage_mult": 0.04}]],
		[["Echo", {"echo": 0.25}], ["Sustain", {"veil_crack": 1.0}], ["Cadence", {"note_rate": 1}]],
		[["Resonance", {"crossfire": 0.15}], ["Encore", {"parry_notes": 1}], ["Crescendo", {"crescendo": 2.0}]],
		[["Fortissimo", {"perfect_mult": 0.3}], ["Reprise", {"echo": 0.25}], ["Rubato", {"note_window_ms": 15.0}]],
	],
	"towers": [
		[["Sharpen", {"damage_mult": 0.06}], ["Reach", {"range_all": 0.2}], ["Keen", {"crit_chance": 0.05}]],
		[["Cannonry", {"range_kick": 0.5, "damage_kick": 0.15}], ["Workshop", {"upgrade_discount": 0.1}], ["Brutal", {"crit_mult": 0.25}]],
		[["Heavy shot", {"damage_mult": 0.08}], ["Frostwork", {"damage_slow": 0.3, "range_slow": 0.4}], ["Splashworks", {"damage_bass": 0.2, "splash_bonus": 0.3}]],
		[["Overcharge", {"crit_chance": 0.08}], ["Foundry", {"upgrade_discount": 0.15}], ["Executioner", {"crit_mult": 0.5}]],
	],
	"economy": [
		[["Tithe", {"gold_mult": 0.08}], ["Scholar", {"xp_mult": 0.1}], ["Lucky coin", {"luck": 1}]],
		[["Bounty hunter", {"kill_gold": 1}], ["Interest", {"interest": 0.02}], ["Fortune", {"luck": 1}]],
		[["Trade", {"gold_mult": 0.1}], ["Tomes", {"xp_mult": 0.15}], ["Hoard", {"wave_bonus_mult": 0.25}]],
		[["Mogul", {"gold_mult": 0.12}], ["Sage", {"xp_mult": 0.2}], ["Charmed", {"luck": 2}]],
	],
	"walls": [
		[["Masonry", {"wall_cap": 2}], ["Mortar", {"wall_cheap": 1}], ["Buttress", {"wall_cap": 2}]],
		[["Tar", {"wall_slow": 0.15}], ["Spikes", {"wall_thorns": 2.0}], ["Bulwark", {"wall_cap": 3}]],
		[["Quagmire", {"wall_slow": 0.15}], ["Barbs", {"wall_thorns": 3.0}], ["Keep", {"shield_cap": 1}]],
		[["Mire", {"wall_slow": 0.2}], ["Palisade", {"wall_thorns": 4.0}], ["Citadel", {"wall_cap": 4}]],
	],
	"defence": [
		[["Guard", {"parry_mult": 0.15}], ["Poise", {"parry_window_ms": 10.0}], ["Ward", {"shield_cap": 1}]],
		[["Riposte", {"parry_mult": 0.2}], ["Reflex", {"parry_window_ms": 10.0}], ["Battery", {"restore_charges": 1}]],
		[["Sweep", {"parry_splash": 1.0}], ["COUNTER-ATTACK", {"counter": true}], ["Aegis", {"shield_cap": 1}]],
		[["Cleave", {"parry_splash": 1.0}], ["Second wind", {"counter_mult": 0.5}], ["Bastion", {"restore_charges": 1, "shield_cap": 1}]],
	],
}

## Capstones: one per area, needs any row 3 node of that area (6 points in
## through the shortest path with its links, 5 straight down).
const CAPSTONES := {
	"rhythm": ["Fermata", "A Perfect parry freezes every creep for a beat", {"fermata": true}],
	"towers": ["Arsenal", "Every tower type unlocks now", {"arsenal": true}],
	"economy": ["Bounty", "Bosses pay triple gold and XP", {"bounty": true}],
	"walls": ["Rampart", "Walls slow hard and bite: x2 wall slow and thorns", {"rampart": true}],
	"defence": ["Riposte", "Counter-attacks hit twice and build double posture", {"counter": true, "counter_mult": 1.0, "riposte": true}],
}

## Cross-area ways in: node -> extra prerequisites that also open it.
const LINKS := {
	"defence_2_1": ["rhythm_1_2", "walls_1_2", "towers_1_2"],  # Counter-attack: an early capstone most starts can reach.
	"towers_2_0": ["rhythm_1_2"],
	"economy_2_0": ["towers_1_2"],
	"walls_2_0": ["economy_1_2"],
	"rhythm_2_2": ["towers_1_0"],
	"economy_2_2": ["walls_1_0"],
}

static var _nodes := {}


## id -> {area, row, col, name, text, effects, needs: Array[String]}; capstones have row = ROWS.
static func nodes() -> Dictionary:
	if not _nodes.is_empty():
		return _nodes
	for area in AREAS:
		for r in ROWS:
			for c in COLS:
				var entry: Array = GRID[area][r][c]
				var id := "%s_%d_%d" % [area, r, c]
				var needs: Array[String] = []
				if r > 0:
					for dc in [-1, 0, 1]:
						if c + dc >= 0 and c + dc < COLS:
							needs.append("%s_%d_%d" % [area, r - 1, c + dc])
				for extra in LINKS.get(id, []):
					needs.append(extra)
				_nodes[id] = {"area": area, "row": r, "col": c, "name": entry[0], "text": describe(entry[1]), "effects": entry[1], "needs": needs}
		var cap: Array = CAPSTONES[area]
		var cap_needs: Array[String] = []
		for c in COLS:
			cap_needs.append("%s_%d_%d" % [area, ROWS - 1, c])
		_nodes[area + "_cap"] = {"area": area, "row": ROWS, "col": 1, "name": cap[0], "text": cap[1], "effects": cap[2], "needs": cap_needs, "capstone": true}
	return _nodes


## Can this node be taken with these owned ids? Roots are always open.
static func available(id: String, owned: Array) -> bool:
	var n: Dictionary = nodes()[id]
	if owned.has(id):
		return false
	if n["needs"].is_empty():
		return true
	for need in n["needs"]:
		if owned.has(need):
			return true
	return false


## One line for a node's effects.
static func describe(effects: Dictionary) -> String:
	var parts: Array[String] = []
	for k in effects:
		var v = effects[k]
		match k:
			"note_rate": parts.append("+%d note per phrase" % v)
			"perfect_mult": parts.append("Perfects +%d%%" % int(v * 100))
			"damage_mult": parts.append("+%d%% damage" % int(v * 100))
			"echo": parts.append("hit notes echo for %d%%" % int(v * 100))
			"veil_crack": parts.append("veils stay cracked +%d beat" % int(v))
			"crossfire": parts.append("crossfire +%d%% per tower" % int(v * 100))
			"parry_notes": parts.append("a parry adds a note")
			"crescendo": parts.append("Crescendo +%d s" % int(v))
			"note_window_ms": parts.append("note window +%d ms" % int(v))
			"range_all": parts.append("+%.1f range, all towers" % v)
			"crit_chance": parts.append("+%d%% crit chance" % int(v * 100))
			"crit_mult": parts.append("+%d%% crit damage" % int(v * 100))
			"upgrade_discount": parts.append("type upgrades %d%% cheaper" % int(v * 100))
			"splash_bonus": parts.append("+%.1f splash radius" % v)
			"gold_mult": parts.append("+%d%% gold" % int(v * 100))
			"xp_mult": parts.append("+%d%% XP" % int(v * 100))
			"luck": parts.append("+%d luck" % v)
			"kill_gold": parts.append("+%d gold per kill" % v)
			"interest": parts.append("%d%% interest on unspent gold each wave" % int(v * 100))
			"wave_bonus_mult": parts.append("wave bonus +%d%%" % int(v * 100))
			"wall_cap": parts.append("+%d walls" % v)
			"wall_cheap": parts.append("walls %dg cheaper" % v)
			"wall_slow": parts.append("walls slow passing creeps %d%%" % int(v * 100))
			"wall_thorns": parts.append("walls deal %d a second to creeps beside them" % int(v))
			"shield_cap": parts.append("+%d shield" % v)
			"parry_mult": parts.append("parry return +%d%%" % int(v * 100))
			"parry_window_ms": parts.append("parry window +%d ms" % int(v))
			"restore_charges": parts.append("+%d Restore charge" % v)
			"parry_splash": parts.append("parries also hit creeps within %d tile of the target" % int(v))
			"counter": parts.append("unlocks the counter-attack")
			"counter_mult": parts.append("counters +%d%%" % int(v * 100))
			_:
				if k.begins_with("range_"):
					parts.append("+%.1f range for %s" % [v, k.substr(6)])
				elif k.begins_with("damage_"):
					parts.append("+%d%% damage for %s" % [int(v * 100), k.substr(7)])
				else:
					parts.append(k)
	return ", ".join(parts)
