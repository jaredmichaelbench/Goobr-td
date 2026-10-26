class_name TalentTree
## The per-run talent tree, second shape (D-0040, WoW-style). Five areas in a
## ring (each borders two neighbours). Each area has three rows and a capstone:
## row 1 is three ranked nodes (0/3, the generic percentages, no repeats);
## row 2 is one node of its own plus one SHARED node with each neighbour (the
## same node sits in both areas, so paths cross: Counterpoint is Rhythm's and
## Defence's); row 3 is two stronger nodes. Rows gate on points spent in the
## area (a shared node counts for both): row 2 needs 4, row 3 needs 8, the
## capstone 12. First point at level 2.
##
## Effects are stat bumps on the game's gstats dictionary, applied once per
## rank. Numbers are placeholders for the test session; tune here, no code.

const AREAS: Array[String] = ["rhythm", "towers", "economy", "walls", "defence"]
const AREA_NAMES := {"rhythm": "Rhythm", "towers": "Towers", "economy": "Economy", "walls": "Walls", "defence": "Defence"}
const AREA_COLORS := {"rhythm": Color(1.0, 0.6, 0.35), "towers": Color(0.9, 0.8, 0.5), "economy": Color(1.0, 0.9, 0.3), "walls": Color(0.6, 0.65, 0.75), "defence": Color(0.5, 0.8, 1.0)}
const GATES := [0, 4, 8, 12]  # Points in the area needed for row 1, 2, 3 and the capstone.
const ROWS := 3

## Row 1: [name, effects per rank], three per area, 0/3 each.
const ROW1 := {
	"rhythm": [["Pulse", {"note_rate": 1}, 2], ["Accent", {"perfect_mult": 0.1}, 3], ["Tempo", {"damage_mult": 0.04}, 3]],
	"towers": [["Sharpen", {"damage_mult": 0.05}, 3], ["Reach", {"range_all": 0.15}, 3], ["Keen", {"crit_chance": 0.04}, 3]],
	"economy": [["Tithe", {"gold_mult": 0.06}, 3], ["Scholar", {"xp_mult": 0.08}, 3], ["Lucky coin", {"luck": 1}, 3]],
	"walls": [["Masonry", {"wall_cap": 2}, 3], ["Tar", {"wall_slow": 0.08}, 3], ["Spikes", {"wall_thorns": 1.0}, 3]],
	"defence": [["Guard", {"parry_mult": 0.1}, 3], ["Poise", {"parry_window_ms": 6.0}, 3], ["Ward", {"shield_cap": 1}, 2]],
}
## Row 2, the area's own node (one rank).
const ROW2 := {
	"rhythm": ["Echo", {"echo": 0.35}],
	"towers": ["Workshop", {"upgrade_discount": 0.15}],
	"economy": ["Interest", {"interest": 0.03}],
	"walls": ["Bulwark", {"wall_cap": 4}],
	"defence": ["Battery", {"restore_charges": 1}],
}
## Row 2, shared between an area and the next one in the ring (one rank).
const SHARED := {
	"rhythm|towers": ["Resonance", {"crossfire": 0.2}],
	"towers|economy": ["Trade routes", {"gold_mult": 0.1, "upgrade_discount": 0.05}],
	"economy|walls": ["Toll road", {"kill_gold": 1, "wall_cheap": 1}],
	"walls|defence": ["Keep", {"shield_cap": 1, "restore_charges": 1}],
	"defence|rhythm": ["Counterpoint", {"counter_window_ms": 60.0}],
}
## Row 3: two per area (one rank).
const ROW3 := {
	"rhythm": [["Encore", {"parry_notes": 1}], ["Rubato", {"note_window_ms": 20.0}]],
	"towers": [["Overcharge", {"crit_mult": 0.5}], ["Heavy shot", {"damage_mult": 0.15}]],
	"economy": [["Hoard", {"wave_bonus_mult": 0.5}], ["Sage", {"xp_mult": 0.3}]],
	"walls": [["Quagmire", {"wall_slow": 0.25}], ["Palisade", {"wall_thorns": 4.0}]],
	"defence": [["Sweep", {"parry_splash": 2.0}], ["Second wind", {"counter_mult": 0.5}]],
}
## Capstones: one per area, 12 points in.
const CAPSTONES := {
	"rhythm": ["Fermata", "A Perfect parry freezes every creep for a beat", {"fermata": true}],
	"towers": ["Arsenal", "Every tower type unlocks now", {"arsenal": true}],
	"economy": ["Bounty", "Bosses pay triple gold and XP", {"bounty": true}],
	"walls": ["Rampart", "Walls slow hard and bite: x2 wall slow and thorns", {"rampart": true}],
	"defence": ["Riposte", "Counter-attacks hit twice and build double posture", {"counter": true, "counter_mult": 1.0, "riposte": true}],
}

static var _nodes := {}
static var _layout := {}


static func _id(name: String) -> String:
	return name.to_lower().replace(" ", "_").replace("-", "_")


## id -> {name, text, effects, areas: Array[String], row (1..3, 4 = capstone), max}.
static func nodes() -> Dictionary:
	if not _nodes.is_empty():
		return _nodes
	for i in AREAS.size():
		var area: String = AREAS[i]
		var prev: String = AREAS[(i - 1 + AREAS.size()) % AREAS.size()]
		var next: String = AREAS[(i + 1) % AREAS.size()]
		var rows: Array = [[], [], [], []]
		for entry in ROW1[area]:
			var id := _id(entry[0])
			_nodes[id] = {"name": entry[0], "text": describe(entry[1]) + " per rank", "effects": entry[1], "areas": [area], "row": 1, "max": entry[2]}
			rows[0].append(id)
		var own: Array = ROW2[area]
		var own_id := _id(own[0])
		_nodes[own_id] = {"name": own[0], "text": describe(own[1]), "effects": own[1], "areas": [area], "row": 2, "max": 1}
		var left: Array = SHARED[prev + "|" + area]
		var right: Array = SHARED[area + "|" + next]
		for pair in [[left, [prev, area]], [right, [area, next]]]:
			var sid := _id(pair[0][0])
			if not _nodes.has(sid):
				_nodes[sid] = {"name": pair[0][0], "text": describe(pair[0][1]), "effects": pair[0][1], "areas": pair[1], "row": 2, "max": 1, "shared": true}
		rows[1] = [_id(left[0]), own_id, _id(right[0])]
		for entry in ROW3[area]:
			var id := _id(entry[0])
			_nodes[id] = {"name": entry[0], "text": describe(entry[1]), "effects": entry[1], "areas": [area], "row": 3, "max": 1}
			rows[2].append(id)
		var cap: Array = CAPSTONES[area]
		_nodes[area + "_cap"] = {"name": cap[0], "text": cap[1], "effects": cap[2], "areas": [area], "row": 4, "max": 1, "capstone": true}
		rows[3] = [area + "_cap"]
		_layout[area] = rows
	return _nodes


## The ids to show for an area, row by row (row 2 holds the two shared nodes at its edges).
static func layout(area: String) -> Array:
	nodes()
	return _layout[area]


## Ranks taken: owned lists an id once per rank.
static func ranks(id: String, owned: Array) -> int:
	return owned.count(id)


## Points spent in an area; a shared node counts for both of its areas.
static func area_points(area: String, owned: Array) -> int:
	var n := 0
	for id in owned:
		if nodes()[id]["areas"].has(area):
			n += 1
	return n


## Can one more rank be taken? Needs a free rank and the row's gate in any of the node's areas.
static func available(id: String, owned: Array) -> bool:
	var n: Dictionary = nodes()[id]
	if ranks(id, owned) >= n["max"]:
		return false
	var gate: int = GATES[n["row"] - 1]
	for area in n["areas"]:
		if area_points(area, owned) >= gate:
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
			"range_all": parts.append("+%.2f range, all towers" % v)
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
			"parry_splash": parts.append("parries also hit creeps within %d tiles of the target" % int(v))
			"counter": parts.append("unlocks the counter-attack")
			"counter_mult": parts.append("counters +%d%%" % int(v * 100))
			"counter_window_ms": parts.append("counter tap window +%d ms" % int(v))
			_:
				if k.begins_with("range_"):
					parts.append("+%.1f range for %s" % [v, k.substr(6)])
				elif k.begins_with("damage_"):
					parts.append("+%d%% damage for %s" % [int(v * 100), k.substr(7)])
				else:
					parts.append(k)
	return ", ".join(parts)
