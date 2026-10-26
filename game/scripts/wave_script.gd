class_name WaveScript
## The hand-written waves (D-0033). Each wave is a list of groups in spawn
## order: {"kind", "count", "gap"} where gap is seconds between creeps of the
## group. Boss waves (5 and 10) list the escorts; the boss itself comes from
## M5. Waves past the last entry reuse the last one. Tune freely, no code.
##
## Kinds: grunt (the plain creep), runner (fast, half HP, pairs), brute (3x HP,
## armour), swarm (packs of small creeps), shade (immune until a note cracks
## its veil), jammer / archer / warden (elites, see m4_restore.gd).

const WAVES: Array = [
	# 1: just grunts, learn the maze and the rings.
	[{"kind": "grunt", "count": 16, "gap": 0.7}],
	# 2: runners appear in pairs between the grunts.
	[{"kind": "grunt", "count": 6, "gap": 0.7}, {"kind": "runner", "count": 2, "gap": 0.35},
	 {"kind": "grunt", "count": 6, "gap": 0.7}, {"kind": "runner", "count": 2, "gap": 0.35},
	 {"kind": "grunt", "count": 4, "gap": 0.7}],
	# 3: first swarm, first Jammer.
	[{"kind": "grunt", "count": 8, "gap": 0.7}, {"kind": "swarm", "count": 6, "gap": 0.15},
	 {"kind": "runner", "count": 4, "gap": 0.35}, {"kind": "jammer", "count": 1, "gap": 0.9},
	 {"kind": "grunt", "count": 6, "gap": 0.7}],
	# 4: first Brutes, first Archer.
	[{"kind": "grunt", "count": 6, "gap": 0.7}, {"kind": "brute", "count": 2, "gap": 1.2},
	 {"kind": "swarm", "count": 6, "gap": 0.15}, {"kind": "archer", "count": 1, "gap": 0.9},
	 {"kind": "runner", "count": 4, "gap": 0.35}, {"kind": "grunt", "count": 6, "gap": 0.7}],
	# 5: boss. These are the escorts: the first half with the boss, the rest 10 s later.
	[{"kind": "grunt", "count": 4, "gap": 0.7}, {"kind": "swarm", "count": 6, "gap": 0.15},
	 {"kind": "runner", "count": 4, "gap": 0.35}, {"kind": "brute", "count": 2, "gap": 1.2}],
	# 6: Shades. A landed note cracks every veil on the board for 3 beats.
	[{"kind": "grunt", "count": 6, "gap": 0.7}, {"kind": "shade", "count": 2, "gap": 0.8},
	 {"kind": "swarm", "count": 6, "gap": 0.15}, {"kind": "jammer", "count": 1, "gap": 0.9},
	 {"kind": "runner", "count": 4, "gap": 0.35}, {"kind": "brute", "count": 2, "gap": 1.2},
	 {"kind": "archer", "count": 1, "gap": 0.9}, {"kind": "swarm", "count": 6, "gap": 0.15},
	 {"kind": "shade", "count": 2, "gap": 0.8}],
	# 7: the Warden leads a swarm under its cover.
	[{"kind": "grunt", "count": 6, "gap": 0.7}, {"kind": "warden", "count": 1, "gap": 0.4},
	 {"kind": "swarm", "count": 6, "gap": 0.15}, {"kind": "runner", "count": 6, "gap": 0.35},
	 {"kind": "shade", "count": 3, "gap": 0.8}, {"kind": "archer", "count": 1, "gap": 0.9},
	 {"kind": "brute", "count": 3, "gap": 1.2}, {"kind": "grunt", "count": 4, "gap": 0.7}],
	# 8: two swarms, a Warden with brutes, both elites.
	[{"kind": "swarm", "count": 6, "gap": 0.15}, {"kind": "shade", "count": 4, "gap": 0.8},
	 {"kind": "jammer", "count": 1, "gap": 0.9}, {"kind": "brute", "count": 2, "gap": 1.2},
	 {"kind": "warden", "count": 1, "gap": 0.4}, {"kind": "brute", "count": 2, "gap": 1.0},
	 {"kind": "runner", "count": 6, "gap": 0.35}, {"kind": "archer", "count": 1, "gap": 0.9},
	 {"kind": "swarm", "count": 6, "gap": 0.15}],
	# 9: everything, denser.
	[{"kind": "shade", "count": 4, "gap": 0.8}, {"kind": "runner", "count": 8, "gap": 0.35},
	 {"kind": "jammer", "count": 1, "gap": 0.9}, {"kind": "brute", "count": 4, "gap": 1.0},
	 {"kind": "warden", "count": 1, "gap": 0.4}, {"kind": "swarm", "count": 12, "gap": 0.15},
	 {"kind": "archer", "count": 1, "gap": 0.9}, {"kind": "shade", "count": 2, "gap": 0.8},
	 {"kind": "grunt", "count": 6, "gap": 0.7}],
	# 10: boss again, with a full escort: first half with the boss, the rest 10 s later.
	[{"kind": "warden", "count": 1, "gap": 0.4}, {"kind": "swarm", "count": 6, "gap": 0.15},
	 {"kind": "shade", "count": 4, "gap": 0.8}, {"kind": "brute", "count": 4, "gap": 1.0},
	 {"kind": "runner", "count": 8, "gap": 0.35}, {"kind": "swarm", "count": 6, "gap": 0.15},
	 {"kind": "archer", "count": 1, "gap": 0.9}, {"kind": "grunt", "count": 4, "gap": 0.7}],
	# --- M7: the run goes to 20 (D-0039). Waves 11 to 20 mix everything, denser, with two
	# elites a wave from 13 and three from 17. Bosses at 15 (first boss) and 20 (crowned).
	# 11: a breather after the boss, then runners in numbers.
	[{"kind": "grunt", "count": 8, "gap": 0.6}, {"kind": "runner", "count": 8, "gap": 0.3},
	 {"kind": "jammer", "count": 1, "gap": 0.9}, {"kind": "swarm", "count": 6, "gap": 0.15},
	 {"kind": "brute", "count": 3, "gap": 1.0}, {"kind": "grunt", "count": 6, "gap": 0.6}],
	# 12: shades under a Warden.
	[{"kind": "warden", "count": 1, "gap": 0.4}, {"kind": "shade", "count": 5, "gap": 0.7},
	 {"kind": "runner", "count": 6, "gap": 0.3}, {"kind": "swarm", "count": 12, "gap": 0.15},
	 {"kind": "archer", "count": 1, "gap": 0.9}, {"kind": "brute", "count": 3, "gap": 1.0}],
	# 13: two Jammers.
	[{"kind": "grunt", "count": 8, "gap": 0.6}, {"kind": "jammer", "count": 1, "gap": 0.9},
	 {"kind": "brute", "count": 4, "gap": 0.9}, {"kind": "jammer", "count": 1, "gap": 0.9},
	 {"kind": "swarm", "count": 12, "gap": 0.15}, {"kind": "shade", "count": 4, "gap": 0.7},
	 {"kind": "runner", "count": 8, "gap": 0.3}],
	# 14: archers from both ends.
	[{"kind": "archer", "count": 1, "gap": 0.9}, {"kind": "runner", "count": 10, "gap": 0.3},
	 {"kind": "warden", "count": 1, "gap": 0.4}, {"kind": "brute", "count": 4, "gap": 0.9},
	 {"kind": "swarm", "count": 12, "gap": 0.15}, {"kind": "archer", "count": 1, "gap": 0.9},
	 {"kind": "shade", "count": 4, "gap": 0.7}, {"kind": "grunt", "count": 8, "gap": 0.6}],
	# 15: boss (the wave 5 boss, bigger), with a heavy escort.
	[{"kind": "warden", "count": 1, "gap": 0.4}, {"kind": "brute", "count": 4, "gap": 0.9},
	 {"kind": "swarm", "count": 12, "gap": 0.15}, {"kind": "shade", "count": 4, "gap": 0.7},
	 {"kind": "runner", "count": 8, "gap": 0.3}, {"kind": "archer", "count": 1, "gap": 0.9},
	 {"kind": "jammer", "count": 1, "gap": 0.9}, {"kind": "grunt", "count": 6, "gap": 0.6}],
	# 16: brutes in a column.
	[{"kind": "brute", "count": 6, "gap": 0.8}, {"kind": "jammer", "count": 1, "gap": 0.9},
	 {"kind": "runner", "count": 10, "gap": 0.3}, {"kind": "shade", "count": 5, "gap": 0.7},
	 {"kind": "archer", "count": 1, "gap": 0.9}, {"kind": "swarm", "count": 18, "gap": 0.15},
	 {"kind": "grunt", "count": 8, "gap": 0.6}],
	# 17: three elites.
	[{"kind": "grunt", "count": 8, "gap": 0.6}, {"kind": "warden", "count": 1, "gap": 0.4},
	 {"kind": "shade", "count": 6, "gap": 0.7}, {"kind": "jammer", "count": 1, "gap": 0.9},
	 {"kind": "brute", "count": 5, "gap": 0.8}, {"kind": "archer", "count": 1, "gap": 0.9},
	 {"kind": "runner", "count": 10, "gap": 0.3}, {"kind": "swarm", "count": 12, "gap": 0.15}],
	# 18: swarms everywhere.
	[{"kind": "swarm", "count": 18, "gap": 0.15}, {"kind": "warden", "count": 1, "gap": 0.4},
	 {"kind": "swarm", "count": 18, "gap": 0.15}, {"kind": "archer", "count": 1, "gap": 0.9},
	 {"kind": "brute", "count": 5, "gap": 0.8}, {"kind": "jammer", "count": 1, "gap": 0.9},
	 {"kind": "shade", "count": 6, "gap": 0.7}, {"kind": "runner", "count": 8, "gap": 0.3}],
	# 19: everything, densest.
	[{"kind": "shade", "count": 6, "gap": 0.6}, {"kind": "runner", "count": 12, "gap": 0.25},
	 {"kind": "jammer", "count": 1, "gap": 0.9}, {"kind": "brute", "count": 6, "gap": 0.8},
	 {"kind": "warden", "count": 1, "gap": 0.4}, {"kind": "swarm", "count": 18, "gap": 0.15},
	 {"kind": "archer", "count": 1, "gap": 0.9}, {"kind": "shade", "count": 4, "gap": 0.6},
	 {"kind": "jammer", "count": 1, "gap": 0.9}, {"kind": "grunt", "count": 10, "gap": 0.5}],
	# 20: the crowned boss again, with everything as escort: half now, half 10 s later.
	[{"kind": "warden", "count": 1, "gap": 0.4}, {"kind": "swarm", "count": 12, "gap": 0.15},
	 {"kind": "shade", "count": 6, "gap": 0.6}, {"kind": "brute", "count": 6, "gap": 0.8},
	 {"kind": "jammer", "count": 1, "gap": 0.9}, {"kind": "runner", "count": 12, "gap": 0.25},
	 {"kind": "archer", "count": 1, "gap": 0.9}, {"kind": "swarm", "count": 12, "gap": 0.15},
	 {"kind": "grunt", "count": 8, "gap": 0.5}],
]


## The wave's groups. Past the end (endless) the last five repeat, so the
## repeats keep the boss cadence.
static func groups(w: int) -> Array:
	if w <= WAVES.size():
		return WAVES[maxi(w - 1, 0)]
	return WAVES[WAVES.size() - 5 + posmod(w - WAVES.size() - 1, 5)]


## Flattened spawn list for a wave: one {"kind", "gap"} per creep.
static func plan(w: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in groups(w):
		for i in g["count"]:
			out.append({"kind": g["kind"], "gap": g["gap"]})
	return out


## "16 grunts, 4 runners, 1 swarm, Jammer" for the HUD.
static func summary(w: int) -> String:
	var counts := {}
	var order: Array[String] = []
	for g in groups(w):
		var k: String = g["kind"]
		if not counts.has(k):
			counts[k] = 0
			order.append(k)
		counts[k] += g["count"]
	var parts: Array[String] = []
	for k in order:
		match k:
			"swarm":
				parts.append("%d swarm" % (counts[k] / 6))
			"jammer", "archer", "warden":
				parts.append(k.capitalize() if counts[k] == 1 else "%d %ss" % [counts[k], k.capitalize()])
			_:
				parts.append("%d %s%s" % [counts[k], k, "s" if counts[k] != 1 else ""])
	return ", ".join(parts)
