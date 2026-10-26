class_name M7Run
extends "res://scripts/m6_run.gd"
## M7: the progression run (D-0039). Everything from M6, with the four layers
## from the progression review under it:
##
## - Type upgrades (gold): no tower is upgraded on its own. Each tower type
##   has a five-rung ladder that applies to every tower of that type, with a
##   two-way fork at rung 3. Upgrade from the type's panel (click its build
##   button, or a tower of that type) or U.
## - Six towers: Cannon, Splash and Frost always; Poison, Lightning and Light
##   unlock in the run when their requirement is met (shown on the button).
## - Levels: kills give XP, each level gives a talent point (first at level 2).
##   Tab opens the tree: five areas, a capstone each, cross links. The game
##   pauses while the tree is open.
## - Counter-attack: a talent. After a landed parry a yellow ring closes on the
##   enemy over one beat; Space as it lands hits it again. Off during a Volley.
## - The draft: after every boss wave, cards rolled for rarity and category
##   (card_pool.gd). Luck and Draft cards shift the odds.
## - The run is 20 waves (bosses at 5, 10, 15, 20) with endless after; the menu
##   also offers a 10-wave quick run (key 8).
##
## Numbers here are first guesses for the M7 playtest.

static var quick := false  # Set by the menu: key 8 is the 10-wave quick run.

const LONG_WAVES := 20
const TOWER_SPECS := {
	"poison": {"cost": 25, "color": Color(0.55, 0.9, 0.4), "range": 2.4, "damage": 2.0, "cooldown": 0.5, "splash": 0.0, "poison": true},
	"lightning": {"cost": 35, "color": Color(0.75, 0.85, 1.0), "range": 2.4, "damage": 7.0, "cooldown": 1.0, "splash": 0.0, "arc": true},
	"light": {"cost": 30, "color": Color(1.0, 0.95, 0.7), "range": 2.0, "damage": 0.0, "cooldown": 1.0, "splash": 0.0, "light": true},
}
const TOWER_NAMES7 := {"kick": "Cannon", "bass": "Splash", "slow": "Frost", "poison": "Poison", "lightning": "Lightning", "light": "Light", "wall": "Wall"}
const PATTERNS7 := {"kick": [0, 4], "bass": [1, 3, 5, 7], "slow": [0, 2, 4, 6], "poison": [0, 2, 4, 6], "lightning": [0, 4], "light": [0]}
## Rung 2 for these types adds steps to the pattern ("+rate"); the others get range.
const RATE_STEPS := {"slow": [1, 3, 5, 7], "poison": [1, 3, 5, 7], "lightning": [2, 6]}
const UNLOCKS := {
	"poison": {"text": "needs 3 Frost", "stat": "built_slow", "need": 3},
	"lightning": {"text": "needs 10 Perfects", "stat": "perfects", "need": 10},
	"light": {"text": "needs a Shade kill", "stat": "kills_shade", "need": 1},
}
const COUNTER_BURST := 2.0  # Tiles a counter on a creep reaches (D-0040).
const EXTRA_DRAFT_WAVES := [3, 8, 13, 18]  # Drafts between bosses (D-0040).
const TRICKLE_GAP := 20.0  # Fallback: a pack comes anyway if no posture break for this long (D-0041).
const TRICKLE_PACKS := 3  # Three big packs, released on posture breaks 1, 3 and 5.
const TRICKLE_BREAKS := [1, 3, 5]
const SUMMON_EVERY_BREAKS := 2  # Bosses after wave 10 summon a pack on every second break.
const COUNTER_TAP_MS := 150.0  # The counter: a second Space this soon after a landed parry (D-0041).
const COUNTER_LATE_MS := 450.0  # A tap after the window but before this gets a "late" message.
const VEIL_MULTS := [0.1, 0.2, 0.3, 1.0]  # Damage a veiled Shade takes at 0, 1, 2, 3 cracks (D-0041).
## The flow (D-0041): throws land on beat 1, notes sit on beats 2 to 4, the counter is
## the tap after a parry. Patterns are three symbols for beats 2, 3 and 4.
const PATTERNS_MID := [".QE", "QQE", "Q.E", "QEE", "QE."]  # Waves 11 to 15, one per wave.
const PATTERNS_LATE := [".QE", "QQE", "Q.E", "QEE", "QE.", "EQE", "E.Q", ".EQ", "EEQ"]  # 16+, per phrase.
const CREEP_HP_M7 := 30.0  # Was 18: waves 1 to 3 died to the first shot (D-0041).
const STAGGER_BEATS := 2  # An elite holds this long after a parried throw.
## Crescendo charts, one rolled per posture break: Q, E or a rest per beat, looped.
const CRESCENDO_SETS := ["QEQE", "QQEE", "QE.E", "EQQ.", "QQQE", "E.QE", "QEE.", "EEQQ"]
const RUNG_MULT := [1.5, 2.0, 3.0, 3.5, 4.0]  # Price = base cost x this x (1 + 0.1 x towers of the type).
const PER_TOWER_PRICE := 0.1
const BRANCHES := {
	"kick": [["Pierce", "snipes also hit the two creeps nearest the target"], ["Siege", "double damage to Brutes and bosses"]],
	"bass": [["Quake", "hits stagger creeps for half a beat"], ["Ember", "hits leave burning ground for a bar"]],
	"slow": [["Deep freeze", "every third hit freezes for a beat"], ["Brittle", "frozen creeps always take crits"]],
	"poison": [["Poison-splash", "hits poison every creep within a tile"], ["Virulent", "poison never wears off"]],
	"lightning": [["Fork", "one more jump"], ["Static", "arcs reach 4 tiles"]],
	"light": [["Beacon", "double buff radius"], ["Flare", "its pulse cracks every veil on the board"]],
}
const XP := {"grunt": 1.0, "runner": 1.0, "swarm": 0.5, "brute": 3.0, "shade": 3.0, "jammer": 8.0, "archer": 8.0, "warden": 8.0, "boss": 40.0}
const XP_BASE := 10.0
const XP_GROWTH := 1.2
const ELITE_GOLD := 6
const BOSS_GOLD := 60
const POISON_TICK := 1.5
const POISON_SECONDS := 3.0
const ARC_RANGE := 2.0
const ARC_JUMPS := 2
const ARC_FALLOFF := 0.7
const LIGHT_BUFF := 0.15
const LIGHT_RADIUS := 2.0
const GHOST_TICK := 2.0
const BURN_DPS := 3.0
const CREEP_HP_GROWTH_M7 := 1.15  # Was 1.19 from 18 HP; from 30 HP this keeps wave 12 close and softens 20 (D-0041).
const CRIT_BASE_MULT := 1.5

var type_rank := {}  # type -> 0..5
var type_branch := {}  # type -> 0 (no fork yet), 1 or 2
var unlocked: Array[String] = []
var progress := {}  # Unlock counters: built_<type>, kills_<kind>, perfects.
var xp := 0.0
var level := 1
var points := 0
var owned: Array[String] = []  # Talent ids.
var gstats := {}  # Global stats talents and cards add to (slice H).
var tree_open := false
var _trickle: Array[Dictionary] = []  # Escorts still to come during a boss fight.
var _trickle_at := -1.0
var _trickle_pack := 0
var _trickle_released := 0  # Packs let out so far this boss fight.
var _counter_open := {}  # After a landed parry: ref (the creep), until (press time), perfect, opened.
var _crack_steps := 1  # Cracks the next crack_veils call adds (2 on a Perfect).
var _wave_pattern := ".Q."  # Beats 2, 3, 4 for the current wave (band 3+); see pattern_text().
var _wave_base := {}  # Stat totals at wave start, for the per-wave miss log.
var wave_log: Array[String] = []  # One line per wave: notes, parries, counters, health lost (D-0041).
var counters: Array[Dictionary] = []  # at, ref (a creep), state (flying / hit / gone)
var draft_cards: Array[Dictionary] = []  # The rolled cards on offer (draft holds their ids).
var rerolls_left := 0
var card_taken := {}  # id -> true: no duplicates in a run.
var orange_taken := false
var ghosts: Array[Dictionary] = []  # target (creep), ttl
var burning: Array[Dictionary] = []  # pos, until
var kills := {}
var _gold_frac := 0.0
var m7_stats := {"xp": 0.0, "levels": 0, "talents": 0, "upgrades": 0, "unlocks": 0, "counters": 0, "counter_hits": 0, "crits": 0, "poison": 0.0, "arcs": 0, "rerolls": 0}


func _ready() -> void:
	for type in TOWER_SPECS:
		builds[type] = TOWER_SPECS[type].duplicate()
	last_wave = 10 if quick else LONG_WAVES
	boss_waves = [5, 10] if quick else [5, 10, 15, 20]
	super._ready()
	title = "M7 Quick run (10 waves)" if quick else "M7 The progression run"
	build_keys = {KEY_1: "wall", KEY_2: "kick", KEY_3: "bass", KEY_4: "slow", KEY_5: "poison", KEY_6: "lightning", KEY_7: "light"}
	creep_hp_growth = CREEP_HP_GROWTH_M7
	creep_hp = CREEP_HP_M7
	_reset_progression()


func make_hud() -> Hud:
	return Hud7.new(self)


func tower_name(type: String) -> String:
	return TOWER_NAMES7.get(type, type.capitalize())


func reset() -> void:
	super.reset()
	tree_open = false
	_reset_progression()


func _reset_progression() -> void:
	type_rank = {}
	type_branch = {}
	for type in builds:
		type_rank[type] = 0
		type_branch[type] = 0
	unlocked = ["wall", "kick", "bass", "slow"]
	progress = {}
	xp = 0.0
	level = 1
	points = 0
	owned.clear()
	gstats = {}
	counters.clear()
	_counter_open = {}
	wave_log.clear()
	_wave_base = {}
	draft_cards.clear()
	rerolls_left = 0
	card_taken = {}
	orange_taken = false
	ghosts.clear()
	burning.clear()
	kills = {}
	_gold_frac = 0.0
	m7_stats = {"xp": 0.0, "levels": 0, "talents": 0, "upgrades": 0, "unlocks": 0, "counters": 0, "counter_hits": 0, "crits": 0, "poison": 0.0, "arcs": 0, "rerolls": 0}
	_apply_stats()


# --- Slice A: type upgrades --------------------------------------------------------

func is_tower(type: String) -> bool:
	return builds.has(type) and builds[type].has("range")


## The spec every tower of a type fires with: base, times its rungs, times
## the talents and cards that name it. Light towers nearby add their buff.
func tower_spec(cell: Vector2i) -> Dictionary:
	var type: String = structures[cell]["type"]
	var spec := type_spec(type)
	if type != "light" and is_tower(type):
		var buff := 0.0
		for other in structures:
			if structures[other]["type"] == "light" and other != cell and tower_ready(other):
				var radius := LIGHT_RADIUS * (2.0 if type_branch["light"] == 1 else 1.0)
				if Vector2(other).distance_to(Vector2(cell)) <= radius:
					buff += LIGHT_BUFF
		if buff > 0.0:
			spec["damage"] *= 1.0 + buff
	return spec


func type_spec(type: String) -> Dictionary:
	var base: Dictionary = builds[type]
	if not base.has("range"):
		return base
	var spec: Dictionary = base.duplicate()
	var rank: int = type_rank.get(type, 0)
	var dmg := 1.0
	if rank >= 1:
		dmg += 0.4
	if rank >= 2 and not RATE_STEPS.has(type):
		spec["range"] += 1.0
	if rank >= 4:
		dmg += 0.4
	if rank >= 5:
		dmg += 0.4
		spec["range"] += 0.5
	dmg += gstats.get("damage_" + type, 0.0)
	spec["range"] += gstats.get("range_all", 0.0) + gstats.get("range_" + type, 0.0)
	if spec.get("splash", 0.0) > 0.0:
		spec["splash"] += gstats.get("splash_bonus", 0.0)
	spec["damage"] *= dmg
	return spec


## The 8th-note steps a type fires on; "+rate" types gain steps at rung 2.
func pattern_for(type: String) -> Array:
	var steps: Array = PATTERNS7.get(type, []).duplicate()
	if RATE_STEPS.has(type) and type_rank.get(type, 0) >= 2:
		steps.append_array(RATE_STEPS[type])
	return steps


func towers_of(type: String) -> int:
	var n := 0
	for cell in structures:
		if structures[cell]["type"] == type:
			n += 1
	return n


func type_upgrade_cost(type: String) -> int:
	var rank: int = type_rank.get(type, 0)
	if rank >= RUNG_MULT.size():
		return 0
	var price: float = builds[type]["cost"] * RUNG_MULT[rank] * (1.0 + PER_TOWER_PRICE * towers_of(type))
	price *= 1.0 - gstats.get("upgrade_discount", 0.0)
	return maxi(1, roundi(price))


## What the next rung does, for the panel. Rung 3 is the fork: pick 1 or 2.
func rung_text(type: String, rank: int) -> String:
	match rank:
		1: return "+40% damage"
		2: return "fires on the off-beats too" if RATE_STEPS.has(type) else "+1 range"
		3: return "the fork: %s or %s" % [BRANCHES[type][0][0], BRANCHES[type][1][0]]
		4: return "+40% damage"
		5: return "+40% damage, +0.5 range"
	return "maxed"


## Buy the next rung for a whole type. At rung 3, `branch` (1 or 2) picks the fork.
func upgrade_type(type: String, branch := 0) -> bool:
	if not is_tower(type) or state != "playing":
		return false
	if not unlocked.has(type):
		_say("%s is locked: %s" % [tower_name(type), unlock_text(type)])
		return false
	var rank: int = type_rank[type]
	if rank >= RUNG_MULT.size():
		_say("%s is maxed" % tower_name(type))
		return false
	if rank == 2 and branch == 0:
		_say("Pick a branch for %s" % tower_name(type))
		return false
	var cost := type_upgrade_cost(type)
	if gold < cost:
		_say("Not enough gold (%dg for %s rung %d)" % [cost, tower_name(type), rank + 1])
		return false
	gold -= cost
	type_rank[type] = rank + 1
	if rank == 2:
		type_branch[type] = branch
	m7_stats["upgrades"] += 1
	for cell in structures:
		if structures[cell]["type"] == type:
			_flashes[cell] = 0.6
			_popup(Vector2(cell), "rung %d" % (rank + 1), Color(1.0, 0.9, 0.3), 12)
	var what := rung_text(type, rank + 1) if rank != 2 else "%s: %s" % [BRANCHES[type][branch - 1][0], BRANCHES[type][branch - 1][1]]
	_show_feedback("%s rung %d   %s" % [tower_name(type).to_upper(), rank + 1, what], Color(1.0, 0.9, 0.3))
	return true


## U and the panel button route here: upgrade the tower's type, not the tower.
func upgrade(cell: Vector2i) -> bool:
	if not structures.has(cell):
		return false
	var type: String = structures[cell]["type"]
	if type_rank.get(type, 0) == 2:
		return false  # The fork needs a choice; the panel shows two buttons.
	return upgrade_type(type)


func upgrade_cost(cell: Vector2i) -> int:
	return type_upgrade_cost(structures[cell]["type"])


# --- Slice B: six towers and unlocks -----------------------------------------------

func try_place(cell: Vector2i, type: String) -> bool:
	if not unlocked.has(type):
		_say("%s is locked: %s" % [tower_name(type), unlock_text(type)])
		return false
	var ok := super.try_place(cell, type)
	if ok and is_tower(type):
		progress["built_" + type] = progress.get("built_" + type, 0) + 1
		_check_unlocks()
	return ok


func unlock_text(type: String) -> String:
	if not UNLOCKS.has(type):
		return ""
	var u: Dictionary = UNLOCKS[type]
	return "%s (%d/%d)" % [u["text"], mini(unlock_progress(type), u["need"]), u["need"]]


func unlock_progress(type: String) -> int:
	var u: Dictionary = UNLOCKS[type]
	if u["stat"] == "perfects":
		return stat_total("perfects")
	return int(progress.get(u["stat"], 0))


func _check_unlocks() -> void:
	for type in UNLOCKS:
		if not unlocked.has(type) and unlock_progress(type) >= UNLOCKS[type]["need"]:
			_unlock(type)


func _unlock(type: String) -> void:
	if unlocked.has(type):
		return
	unlocked.append(type)
	m7_stats["unlocks"] += 1
	_show_feedback("UNLOCKED   %s tower   key %s" % [tower_name(type), _key_for(type)], Color(1.0, 0.9, 0.3))


func _key_for(type: String) -> String:
	for k in build_keys:
		if build_keys[k] == type:
			return OS.get_keycode_string(k)
	return ""


func _spawn_creep(kind := "grunt") -> Dictionary:
	var c := super._spawn_creep(kind)
	c["speed"] *= 1.0 + gstats.get("enemy_speed_mult", 0.0)
	if c.has("base_speed"):
		c["base_speed"] = c["speed"]
	if gstats.get("enemy_hp_mult", 0.0) != 0.0:
		c["hp"] *= 1.0 + gstats["enemy_hp_mult"]
		c["max_hp"] = c["hp"]
	if kind == "brute" and gstats.get("brute_shade", false):
		c["veil"] = true
		c["veil_open_until"] = 0.0
	return c


## Cards that change how many come, and the extra Jammer.
func wave_plan(w: int) -> Array[Dictionary]:
	var plan := super.wave_plan(w)
	var mult: float = 1.0 + gstats.get("enemy_count_mult", 0.0)
	if mult != 1.0:
		var out: Array[Dictionary] = []
		var acc := 0.0
		for e in plan:
			if ELITE_KINDS.has(e["kind"]):
				out.append(e)
				continue
			acc += mult
			while acc >= 1.0:
				out.append(e)
				acc -= 1.0
		plan = out
	for i in int(gstats.get("extra_jammer", 0)):
		plan.insert(mini(plan.size(), 4), {"kind": "jammer", "gap": 0.9})
	return plan


func _cancel_pulse(c: Dictionary) -> void:
	super._cancel_pulse(c)
	c["cooldown_until"] += ELITE_PULSE_BARS * clock.bar_length() * gstats.get("enemy_attack_mult", 0.0)


# --- Firing -----------------------------------------------------------------------

## Every hit on a creep goes through here: M7 adds crits (and Joe's dagger,
## Brittle frost) on top of cover, veil and armour.
func damage(c: Dictionary, amount: float) -> float:
	amount *= veil_mult(c)
	var chance: float = gstats.get("crit_chance", 0.0)
	var forced: bool = (gstats.get("first_crit", false) and not c.get("struck", false)) or (type_branch.get("slow", 0) == 2 and c.get("frozen_until", 0.0) > sim_time)
	c["struck"] = true
	if forced or (chance > 0.0 and rng.randf() < chance):
		amount *= CRIT_BASE_MULT + gstats.get("crit_mult", 0.0)
		m7_stats["crits"] += 1
		if c.has("pos"):
			_popup(c["pos"] + Vector2(0.3, -0.3), "crit %d" % roundi(amount), Color(0.55, 0.75, 1.0), 12)
		if gstats.get("crit_slow", false):
			c["slow_until"] = maxf(c.get("slow_until", 0.0), sim_time + clock.beat_length())
	return super.damage(c, amount)


## Damage that ignores armour (poison, thorns, ghosts), not veils or cover.
func true_damage(c: Dictionary, amount: float) -> float:
	amount *= veil_mult(c)
	var cover := cover_for(c)
	if not cover.is_empty():
		c = cover
	if veiled(c):
		return 0.0
	var dealt := minf(amount, maxf(c["hp"], 0.0))
	c["hp"] -= amount
	return dealt


func _coverage(pos: Vector2) -> int:
	var n := 0
	for cell in structures:
		var type: String = structures[cell]["type"]
		if is_tower(type) and type != "light" and pos.distance_to(Vector2(cell)) <= tower_spec(cell)["range"]:
			n += 1
	return n


func _fire_towers_on(pattern_step: int) -> void:
	for cell in structures.keys():
		var s: Dictionary = structures[cell]
		var type: String = s["type"]
		if not is_tower(type) or not pattern_for(type).has(pattern_step) or not tower_ready(cell):
			continue
		var spec := tower_spec(cell)
		if type == "light":
			_light_pulse(cell, spec)
			continue
		var target := _pick_target(Vector2(cell), spec["range"])
		if target.is_empty():
			continue
		var amount: float = spec["damage"] * damage_scale()
		match type:
			"poison":
				_poison(target, amount)
				if type_branch["poison"] == 1:
					for c in creeps:
						if c != target and c["hp"] > 0.0 and c["pos"].distance_to(target["pos"]) <= 1.0:
							_poison(c, amount)
			"lightning":
				_hit(target, spec, amount)
				_arc(target, amount, spec["color"])
			"kick":
				if type_branch["kick"] == 2 and (target.get("kind", "") == "brute" or target.get("boss", false)):
					amount *= 2.0
				_hit(target, spec, amount)
			"bass":
				_hit(target, spec, amount)
				if type_branch["bass"] == 1:
					for c in creeps:
						if c["pos"].distance_to(target["pos"]) <= spec["splash"]:
							c["frozen_until"] = maxf(c.get("frozen_until", 0.0), sim_time + clock.beat_length() * 0.5)
				elif type_branch["bass"] == 2:
					burning.append({"pos": target["pos"], "until": sim_time + clock.bar_length()})
			_:
				_hit(target, spec, amount)
				if spec.has("slow"):
					target["slow_until"] = sim_time + spec["slow"]
				if type == "slow" and type_branch["slow"] == 1:
					s["hits"] = int(s.get("hits", 0)) + 1
					if s["hits"] % 3 == 0:
						target["frozen_until"] = maxf(target.get("frozen_until", 0.0), sim_time + clock.beat_length())
		_flashes[cell] = 0.12
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": spec["color"], "ttl": 0.12, "splash": spec["splash"]})


func _poison(c: Dictionary, amount: float) -> void:
	c["poison"] = float(c.get("poison", 0.0)) + amount
	c["poison_until"] = sim_time + POISON_SECONDS


## Lightning: after the hit, the bolt arcs to the nearest other creeps.
func _arc(from_creep: Dictionary, amount: float, color: Color) -> void:
	var jumps := ARC_JUMPS + (1 if type_branch["lightning"] == 1 else 0)
	var reach: float = ARC_RANGE + gstats.get("arc_range", 0.0) + (2.0 if type_branch["lightning"] == 2 else 0.0)
	var hit := [from_creep]
	var last := from_creep
	for j in jumps:
		var next := {}
		var best := reach
		for c in creeps:
			if c["hp"] > 0.0 and not hit.has(c) and not veiled(c) and c["pos"].distance_to(last["pos"]) <= best:
				next = c
				best = c["pos"].distance_to(last["pos"])
		if next.is_empty():
			break
		amount *= ARC_FALLOFF
		damage(next, amount)
		m7_stats["arcs"] += 1
		shots.append({"from": last["pos"], "to": next["pos"], "color": color, "ttl": 0.15, "splash": 0.0, "width": 2.0})
		hit.append(next)
		last = next


## Light: no shot. On the downbeat it cracks veils in reach one step (Flare: everywhere).
func _light_pulse(cell: Vector2i, spec: Dictionary) -> void:
	for c in creeps:
		if c.get("veil", false) and c["hp"] > 0.0 and (type_branch["light"] == 2 or c["pos"].distance_to(Vector2(cell)) <= spec["range"]):
			_crack(c, 1)
	_flashes[cell] = 0.2
	_bursts.append({"pos": Vector2(cell), "color": spec["color"], "ttl": 0.4, "crit": false, "radius": spec["range"] * 0.5})


## Shades in M7 (D-0041, Jared's model): never immune. A veiled Shade takes 10% damage;
## every landed note cracks the veil a step (20%, 30%, then stripped), a Perfect two
## steps. The veil_crack talent adds a step to every crack.
func veiled(_c: Dictionary) -> bool:
	return false


func veil_mult(c: Dictionary) -> float:
	if not c.get("veil", false):
		return 1.0
	return VEIL_MULTS[mini(int(c.get("cracks", 0)), VEIL_MULTS.size() - 1)]


func _crack(c: Dictionary, steps: int) -> void:
	c["cracks"] = mini(int(c.get("cracks", 0)) + steps + (1 if gstats.get("veil_crack", 0.0) > 0.0 else 0), VEIL_MULTS.size() - 1)


func crack_veils(_seconds: float) -> int:
	var n := 0
	for c in creeps:
		if c.get("veil", false) and c["hp"] > 0.0 and int(c.get("cracks", 0)) < VEIL_MULTS.size() - 1:
			_crack(c, _crack_steps)
			n += 1
	_crack_steps = 1
	return n


## One free shot from a tower, for the Light note.
func _fire_once(cell: Vector2i) -> void:
	var spec := tower_spec(cell)
	var target := _pick_target(Vector2(cell), spec["range"])
	if target.is_empty():
		return
	var type: String = structures[cell]["type"]
	var amount: float = spec["damage"] * damage_scale()
	if type == "poison":
		_poison(target, amount)
	else:
		_hit(target, spec, amount)
		if type == "lightning":
			_arc(target, amount, spec["color"])
	_flashes[cell] = 0.3
	shots.append({"from": Vector2(cell), "to": target["pos"], "color": Color.WHITE, "ttl": 0.3, "splash": spec["splash"], "width": 2.5})


# --- Notes --------------------------------------------------------------------------

## Wave 1 had its first note six bars in; from M7 waves start at chart level 1
## and the first two bars are written at the wave start.
func chart_for_wave(w: int) -> Array:
	return CHARTS[clampi(1 if w <= 2 else (w + 1) / 2, 1, CHARTS.size() - 1)]


func start_wave() -> void:
	var was_active := wave_active
	var base := _totals()  # Before the first bars are written, so their notes count for this wave.
	super.start_wave()
	if wave_active and not was_active:
		var bar := floori(beat_time() / clock.bar_length())
		_schedule_bar(bar + 1)
		_schedule_bar(bar + 2)
		# Boss waves: the second escort pack becomes a trickle for the whole fight (D-0040).
		_trickle.clear()
		_trickle_at = -1.0
		if boss_waves.has(wave) and not _escort_queue.is_empty():
			_trickle = _escort_queue.duplicate()
			_escort_queue.clear()
			_escort_at = -1.0
			_trickle_pack = maxi(1, ceili(_trickle.size() / float(TRICKLE_PACKS)))
			_trickle_at = beat_time() + TRICKLE_GAP
			_trickle_released = 0
		_roll_pattern(true)
		_wave_base = base
		_wave_base["health"] = health


## The flow band of a wave: 1 = Q only, 2 = Q then E, 3 = a rolled pattern per wave,
## 4 = patterns flip every phrase and E can sit on the "and".
func band(w: int) -> int:
	if quick:
		w = w * 2
	return 1 if w <= 5 else (2 if w <= 10 else (3 if w <= 15 else 4))


func _roll_pattern(new_wave: bool) -> void:
	var b := band(wave)
	if b == 1:
		_wave_pattern = ".Q."
	elif b == 2:
		_wave_pattern = ".QE"
	elif b == 3 and new_wave:
		_wave_pattern = PATTERNS_MID[rng.randi() % PATTERNS_MID.size()]
	elif b == 4:
		_wave_pattern = PATTERNS_LATE[rng.randi() % PATTERNS_LATE.size()]


## "1 parry  2 -  3 Q  4 E": the bar as the HUD prints it.
func pattern_text() -> String:
	var parts: Array[String] = ["1 parry"]
	for i in 3:
		parts.append("%d %s" % [i + 2, _wave_pattern[i].replace(".", "-")])
	return "   ".join(parts)


func _totals() -> Dictionary:
	return {
		"notes": stat_total("notes"), "hits": stat_total("hits"),
		"throws": m4_stats["pulses"] + m4_stats["arrows"] + m5_stats["bolts"] + m6_stats["stomps"],
		"parried": m4_stats["parried"] + m5_stats["parries"] + m6_stats["stomp_parries"],
		"counters": m7_stats["counters"], "counter_hits": m7_stats["counter_hits"],
	}


func _log_wave() -> void:
	if _wave_base.is_empty():
		return
	var t := _totals()
	var line := "W%d  notes %d/%d  parries %d/%d  counters %d/%d  hp -%d" % [wave,
		t["hits"] - _wave_base["hits"], t["notes"] - _wave_base["notes"],
		t["parried"] - _wave_base["parried"], t["throws"] - _wave_base["throws"],
		t["counter_hits"] - _wave_base["counter_hits"], t["counters"] - _wave_base["counters"],
		maxi(0, _wave_base["health"] - health)]
	wave_log.append(line)
	print("WAVE LOG  " + line)
	_wave_base = {}


## The flow (D-0041): one ask per beat. Beat 1 belongs to throws, so notes sit on
## beats 2 to 4 (steps 2, 4, 6) by the wave's pattern. Bands 1 and 2 play every
## other bar of the phrase; bands 3 and 4 every bar, band 4 re-rolling each phrase
## and sometimes adding an E on the "and" of 4. While a boss lives and no Crescendo
## plays, a quiet chart keeps the left hand busy: one Q a bar on the tower nearest
## the boss. Extra notes from the Rhythm area go on the off-beats of beats 2 to 4.
func _schedule_bar(bar: int) -> void:
	var bar_t := bar * STEPS_PER_BAR * step_length()
	var step := step_length()
	if boss_alive():
		if crescendo > 0.0:
			return
		var tower := _nearest_tower(boss["pos"])
		if tower.x >= 0:
			add_note(bar_t + 4 * step, "kick", tower)
			notes[notes.size() - 1]["quiet"] = true
		return
	var b := band(wave)
	var bar_in_phrase := posmod(bar, PHRASE_BARS)
	if b <= 2 and bar_in_phrase % 2 == 1:
		return
	if b == 4 and bar_in_phrase == 0:
		_roll_pattern(false)
	for i in 3:
		var ch := _wave_pattern[i]
		if ch == "Q":
			add_note(bar_t + (2 + 2 * i) * step, "kick")
		elif ch == "E":
			add_note(bar_t + (2 + 2 * i) * step, "bass")
	if b == 4 and rng.randf() < 0.5:
		add_note(bar_t + 7 * step, "bass")
	var extra := int(gstats.get("note_rate", 0))
	var slots := [[1, 5, "kick"], [3, 3, "bass"], [0, 7, "kick"], [2, 5, "bass"], [1, 3, "kick"], [3, 7, "bass"]]
	for i in mini(extra, slots.size()):
		if slots[i][0] == bar_in_phrase:
			add_note(bar_t + slots[i][1] * step, slots[i][2])


func _summon_boss() -> void:
	var had := boss_alive()
	super._summon_boss()
	if boss_alive() and not had:
		_show_feedback("THE BOSS   parry at the boss as it throws; its notes play between", Color(1, 0.4, 0.5))


## Late-run elites may wind up for a bar and a half and land on beat 3.
func throw_wind_bars() -> float:
	if band(wave) >= 3 and rng.randf() < 0.5:
		return 1.5
	return 1.0


func _resonance(n: Dictionary, g: String, offset_ms: float) -> void:
	var cell = n["tower"]
	var type: String = structures[cell]["type"] if cell is Vector2i and structures.has(cell) else ""
	var crit := g == "Perfect"
	_crack_steps = 2 if crit else 1
	if type in ["poison", "lightning", "light"]:
		_resonance_new(n, type, g, offset_ms)
	else:
		super._resonance(n, g, offset_ms)
	_check_unlocks()
	# Echo: the note's target takes a share again.
	var echo: float = gstats.get("echo", 0.0)
	var target := _lead_creep()
	if echo > 0.0 and not target.is_empty() and cell is Vector2i and structures.has(cell):
		var extra: float = tower_spec(cell)["damage"] * damage_scale() * (8.0 if crit else 4.0) * echo
		damage(target, extra)
		_popup(target["pos"] + Vector2(0, -0.5), "echo %d" % roundi(extra), Color(1, 1, 1, 0.7), 12)
	# A Perfect repeats on the next beat as a free note (card).
	if crit and gstats.get("perfect_echo", false) and cell is Vector2i and structures.has(cell):
		var beat := clock.beat_length()
		add_note((floorf(beat_time() / beat) + 1.0) * beat, n["type"], cell)


## Notes for the three new towers: spread, chain-all, chorus.
func _resonance_new(n: Dictionary, type: String, g: String, offset_ms: float) -> void:
	var color: Color = NOTE_COLORS[n["type"]]
	var crit := g == "Perfect"
	stats[n["type"]]["hits"] += 1
	if crit:
		stats[n["type"]]["perfects"] += 1
	on_streak_hit()
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	_sfx["perfect" if crit else "good"].play()
	var cell: Vector2i = n["tower"]
	var spec := tower_spec(cell)
	var cracked := crack_veils(VEIL_CRACK_BEATS * clock.beat_length())
	var target := _lead_creep()
	var what := ""
	var dealt := 0.0
	var mult := WAVE_PERFECT if crit else WAVE_GOOD
	match type:
		"poison":
			if target.is_empty():
				what = "nothing to hit"
			else:
				var stacks: float = maxf(float(target.get("poison", 0.0)), spec["damage"] * 3.0) * (2.0 if crit else 1.0)
				var struck := 0
				for c in creeps:
					if c["hp"] > 0.0 and (c == target or c["pos"].distance_to(target["pos"]) <= WAVE_RADIUS):
						_poison(c, stacks)
						struck += 1
				what = "SPREAD  %d poisoned (%d stacks)" % [struck, roundi(stacks)]
				shots.append({"from": Vector2(cell), "to": target["pos"], "color": color, "ttl": 0.4, "splash": WAVE_RADIUS, "width": 3.0})
				_bursts.append({"pos": target["pos"], "color": spec["color"], "ttl": 0.5, "crit": crit, "radius": WAVE_RADIUS})
		"lightning":
			var struck := 0
			var last_pos := Vector2(cell)
			for c in creeps:
				if c["hp"] > 0.0 and not veiled(c):
					dealt += damage(c, spec["damage"] * damage_scale() * mult * 0.5)
					struck += 1
					shots.append({"from": last_pos, "to": c["pos"], "color": color, "ttl": 0.3, "splash": 0.0, "width": 2.0})
					last_pos = c["pos"]
			what = "STORM  %d struck" % struck
			_punch = PUNCH_SECONDS
		"light":
			var radius := LIGHT_RADIUS * (2.0 if type_branch["light"] == 1 else 1.0)
			var fired := 0
			for other in structures:
				if other != cell and is_tower(structures[other]["type"]) and structures[other]["type"] != "light" and tower_ready(other) and Vector2(other).distance_to(Vector2(cell)) <= radius:
					_fire_once(other)
					fired += 1
					if crit:
						_fire_once(other)
			what = "CHORUS  %d towers fired%s" % [fired, " twice" if crit else ""]
			_bursts.append({"pos": Vector2(cell), "color": spec["color"], "ttl": 0.5, "crit": crit, "radius": radius})
	_flashes[cell] = 0.3
	if dealt > 0.0 and not target.is_empty():
		_popup(target["pos"], ("%d!" if crit else "%d") % roundi(dealt), Color(1.0, 0.9, 0.3) if crit else Color.WHITE, 24 if crit else 16)
	_flash_line(Color(1.0, 0.9, 0.3) if crit else Color.WHITE)
	_show_feedback("%s%s  %s  %+.0f ms%s" % ["CRIT  " if crit else "", what, g, offset_ms, ("   %d veil%s cracked" % [cracked, "" if cracked == 1 else "s"]) if cracked > 0 else ""], Color(1.0, 0.9, 0.3) if crit else color)


# --- Slice C: levels and XP -----------------------------------------------------------

func xp_to_next() -> float:
	return XP_BASE * pow(XP_GROWTH, level - 1)


func gain_xp(amount: float) -> void:
	amount *= 1.0 + gstats.get("xp_mult", 0.0)
	xp += amount
	m7_stats["xp"] += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		points += 1
		m7_stats["levels"] += 1
		_show_feedback("LEVEL %d   +1 talent point (Tab)" % level, Color(0.6, 1.0, 0.7))


## Kills happen inside the base step; compare before and after to pay XP and gold.
func step(delta: float) -> void:
	var before: Array[Dictionary] = creeps.duplicate()
	var gold_before := gold
	var was_active := wave_active
	super.step(delta)
	var leaks := 0
	for c in before:
		if c.get("leaked", false) and not creeps.has(c):
			leaks += 1
			continue
		if c["hp"] <= 0.0 and not creeps.has(c) and not c.get("counted", false):
			c["counted"] = true
			_on_kill(c)
	if leaks > 0 and gstats.get("leak_double", false) and state == "playing":
		health -= leaks
		if health <= 0:
			health = 0
			state = "lost"
	if was_active and not wave_active:
		_log_wave()
	if was_active and not wave_active and state == "playing":
		gold += roundi((12 + wave * 3) * gstats.get("wave_bonus_mult", 0.0))
		gold += roundi(gold * gstats.get("interest", 0.0))
	var gained := gold - gold_before
	if gained > 0 and gstats.get("gold_mult", 0.0) > 0.0:
		_gold_frac += gained * gstats["gold_mult"]
		var whole := int(_gold_frac)
		gold += whole
		_gold_frac -= whole
	if paused:
		return
	if not _trickle.is_empty():
		if not boss_alive():
			_trickle.clear()  # The escorts scatter when the boss falls.
		elif beat_time() >= _trickle_at:
			_release_pack()  # Fallback: the boss has not broken for a while.
	# The counter window closes: a parry nobody followed up.
	if not _counter_open.is_empty() and press_time() > _counter_open["until"] and press_time() > _counter_open["until"] + COUNTER_LATE_MS / 1000.0:
		_counter_open = {}
	# Bolts whose parry moment (the throw) passed fly on and land unparried (D-0041 option A).
	for b in bolts:
		if b["state"] == "flying" and press_time() > b["launch"] + parry_good_ms() / 1000.0:
			b["state"] = "loose"
		elif b["state"] == "loose" and beat_time() >= b["arrive"]:
			b["state"] = "hit"
			_bolt_hit()
			on_streak_miss()
	_tick_m7(delta)


## One escort pack out of the trickle, on a posture break or the fallback timer.
func _release_pack() -> void:
	if _trickle.is_empty():
		return
	var pack := _trickle.slice(0, _trickle_pack)
	_trickle = _trickle.slice(_trickle_pack)
	spawn_queue.append_array(pack)
	_to_spawn = spawn_queue.size()
	_trickle_at = beat_time() + TRICKLE_GAP
	_trickle_released += 1
	_show_feedback("ESCORTS", Color(1, 0.4, 0.5))


func _on_kill(c: Dictionary) -> void:
	var kind: String = c.get("kind", "grunt")
	kills[kind] = kills.get(kind, 0) + 1
	progress["kills_" + kind] = progress.get("kills_" + kind, 0) + 1
	var xp_gain: float = XP.get(kind, 1.0)
	if c.get("boss", false):
		var mult := 3.0 if gstats.get("bounty", false) else 1.0
		xp_gain = XP["boss"] * mult
		gold += roundi(BOSS_GOLD * mult)
	elif c.get("elite", false):
		var mult: float = 1.0 + gstats.get("elite_reward_mult", 0.0)
		xp_gain *= mult
		if gstats.get("elite_charge", false):
			restore_charges = mini(restore_cap(), restore_charges + 1)
		else:
			gold += roundi(ELITE_GOLD * mult)
	elif kind == "shade":
		xp_gain *= 1.0 + gstats.get("shade_reward_mult", 0.0)
	gain_xp(xp_gain)
	if gstats.get("ghost", false):
		var target := _nearest_creep(c["pos"], c)
		if not target.is_empty():
			ghosts.append({"target": target, "ttl": 8.0})
	_check_unlocks()


func _nearest_creep(pos: Vector2, skip: Dictionary) -> Dictionary:
	var best := {}
	var best_d := INF
	for c in creeps:
		if c != skip and c["hp"] > 0.0 and c["pos"].distance_to(pos) < best_d:
			best = c
			best_d = c["pos"].distance_to(pos)
	return best


## Per-tick M7 effects: poison and ghost ticks happen on beats (see on_step);
## here are the continuous ones: walls, burning ground, counters timing out.
func _tick_m7(delta: float) -> void:
	var thorns: float = gstats.get("wall_thorns", 0.0) * (2.0 if gstats.get("rampart", false) else 1.0)
	if thorns > 0.0:
		for c in creeps:
			if c["hp"] > 0.0 and _beside_wall(c["pos"]):
				true_damage(c, thorns * delta)
	var keep_b: Array[Dictionary] = []
	for b in burning:
		if b["until"] > sim_time:
			keep_b.append(b)
			for c in creeps:
				if c["hp"] > 0.0 and c["pos"].distance_to(b["pos"]) <= 0.7:
					true_damage(c, BURN_DPS * delta * damage_scale())
	burning = keep_b
	var keep_g: Array[Dictionary] = []
	for g in ghosts:
		g["ttl"] -= delta
		if g["ttl"] <= 0.0:
			continue
		if g["target"]["hp"] <= 0.0 or not creeps.has(g["target"]):
			var next := _nearest_creep(g["target"]["pos"], g["target"])
			if next.is_empty():
				continue
			g["target"] = next
		keep_g.append(g)
	ghosts = keep_g
	# Counters nobody pressed fall away quietly.
	var keep_c: Array[Dictionary] = []
	for k in counters:
		if k["state"] == "flying" and press_time() > k["at"] + parry_good_ms() / 1000.0:
			k["state"] = "gone"
		if k["at"] > beat_time() - 0.5:
			keep_c.append(k)
	counters = keep_c


func _nearest_tower(pos: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for cell in structures:
		if is_tower(structures[cell]["type"]) and tower_ready(cell) and Vector2(cell).distance_to(pos) < best_d:
			best_d = Vector2(cell).distance_to(pos)
			best = cell
	return best


func _beside_wall(pos: Vector2) -> bool:
	var cell := Vector2i(pos.round())
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var n := cell + Vector2i(dx, dy)
			if structures.has(n) and structures[n]["type"] == "wall":
				return true
	return false


## Walls slow passing creeps (talents, cards): scale speed around the base move.
func _move_creeps(delta: float) -> void:
	var slow: float = float(gstats.get("wall_slow", 0.0)) * (2.0 if gstats.get("rampart", false) else 1.0)
	if slow <= 0.0:
		super._move_creeps(delta)
		return
	var touched: Array[Dictionary] = []
	for c in creeps:
		if _beside_wall(c["pos"]):
			c["_speed_save"] = c["speed"]
			c["speed"] *= maxf(0.2, 1.0 - slow)
			touched.append(c)
	super._move_creeps(delta)
	for c in touched:
		c["speed"] = c["_speed_save"]


func on_step(s: int) -> void:
	super.on_step(s)
	if state != "playing" or posmod(s, 2) != 0:
		return
	# Beat ticks: poison and ghosts.
	for c in creeps:
		var stacks: float = c.get("poison", 0.0)
		if stacks > 0.0 and c["hp"] > 0.0 and (type_branch["poison"] == 2 or c.get("poison_until", 0.0) > sim_time):
			var amount: float = stacks * POISON_TICK * (1.0 + gstats.get("poison_mult", 0.0)) * damage_scale() * 0.25
			m7_stats["poison"] += true_damage(c, amount)
			_popup(c["pos"], "%d" % roundi(amount), Color(0.6, 1.0, 0.5, 0.8), 11)
	for g in ghosts:
		if creeps.has(g["target"]) and g["target"]["hp"] > 0.0:
			true_damage(g["target"], GHOST_TICK * damage_scale())


# --- Slice D: talents ------------------------------------------------------------------

func toggle_tree() -> void:
	if state != "playing":
		return
	tree_open = not tree_open
	if tree_open != paused:
		toggle_pause()


func take_talent(id: String) -> bool:
	if points <= 0 or not TalentTree.available(id, owned) or state != "playing":
		return false
	var node: Dictionary = TalentTree.nodes()[id]
	owned.append(id)
	points -= 1
	m7_stats["talents"] += 1
	_apply_effects(node["effects"])
	_show_feedback("TALENT   %s: %s" % [node["name"], node["text"]], Color(0.6, 1.0, 0.7))
	return true


## Stat bumps and flags from a talent or a card; derived values follow.
func _apply_effects(effects: Dictionary) -> void:
	for k in effects:
		var v = effects[k]
		match k:
			"gold":
				gold += int(v)
			"points":
				points += int(v)
			"restore_charges":
				gstats[k] = gstats.get(k, 0) + int(v)
				restore_charges = mini(restore_cap(), restore_charges + int(v))
			"unlock_one":
				for type in UNLOCKS:
					if not unlocked.has(type):
						_unlock(type)
						break
			"arsenal":
				for type in UNLOCKS:
					_unlock(type)
			"snipe_perfect":
				snipe_perfect_mult = float(v)
			"draft_size":
				gstats[k] = maxi(int(gstats.get(k, 3)), int(v))
			_:
				if k.begins_with("mod_"):
					mods[k.substr(4)] = true
				elif v is bool:
					gstats[k] = true
				else:
					gstats[k] = gstats.get(k, 0.0) + v
	_apply_stats()


func _apply_stats() -> void:
	shield_cap = SHIELDS + int(gstats.get("shield_cap", 0))
	wall_limit = WALL_LIMIT + int(gstats.get("wall_cap", 0))
	builds["wall"]["cost"] = maxi(1, BASE_BUILDS["wall"]["cost"] - int(gstats.get("wall_cheap", 0)))
	crescendo_seconds = CRESCENDO_SECONDS + gstats.get("crescendo", 0.0)


func parry_damage() -> float:
	return PARRY_DAMAGE * (1.0 + gstats.get("parry_mult", 0.0))


func parry_good_ms() -> float:
	return Timing.PARRY_GOOD_MS + gstats.get("parry_window_ms", 0.0)


func restore_cap() -> int:
	return RESTORE_CHARGES + int(gstats.get("restore_charges", 0))


# --- Slice E: counter-attack ------------------------------------------------------------

func _resolve_parry(cand: Dictionary, g: String, offset_ms: float) -> void:
	var perfect := g == "Perfect"
	if cand["kind"] == "counter":
		var k: Dictionary = cand["ref"]
		k["state"] = "hit"
		var target: Dictionary = k["ref"]
		m7_stats["counter_hits"] += 1
		if creeps.has(target) and target["hp"] > 0.0:
			var dmg: float = parry_damage() * (1.0 + gstats.get("counter_mult", 0.0)) * (2.0 if perfect else 1.0)
			if target.get("boss", false):
				target["hp"] -= dmg
				posture += (POSTURE_PERFECT if perfect else POSTURE_GOOD) * 0.5 * (2.0 if gstats.get("riposte", false) else 1.0)
				if posture >= POSTURE_MAX:
					_posture_break()
			else:
				damage(target, dmg)
				# On a creep the counter bursts: everything within two tiles takes half.
				for c in creeps:
					if c != target and c["hp"] > 0.0 and not c.get("boss", false) and c["pos"].distance_to(target["pos"]) <= COUNTER_BURST:
						damage(c, dmg * 0.5)
				_bursts.append({"pos": target["pos"], "color": Color(1.0, 0.9, 0.3), "ttl": 0.4, "crit": perfect, "radius": COUNTER_BURST})
			if gstats.get("riposte", false):
				damage(target, dmg) if not target.get("boss", false) else target.set("hp", target["hp"] - dmg)
			shots.append({"from": Vector2(GOAL), "to": target["pos"], "color": Color(1.0, 0.9, 0.3), "ttl": 0.35, "splash": 0.0, "width": 3.5})
			_shockwaves.append({"pos": target["pos"], "ttl": 0.4, "color": Color(1.0, 0.9, 0.3)})
			_popup(target["pos"], ("%d!" if perfect else "%d") % roundi(dmg), Color(1.0, 0.9, 0.3) if perfect else Color.WHITE, 20 if perfect else 15)
		_show_feedback("%sCOUNTER  %+.0f ms" % ["PERFECT " if perfect else "", offset_ms], Color(1.0, 0.9, 0.3) if perfect else Color.WHITE)
		return
	super._resolve_parry(cand, g, offset_ms)
	# What the parry hit, for the extras below.
	var struck: Dictionary = {}
	match cand["kind"]:
		"elite":
			struck = cand["ref"]
		"arrow":
			struck = cand["ref"]["ref"]
		"bolt", "stomp":
			struck = boss
	# An elite staggers after a parried throw: it holds for two beats and opens a two-note phrase
	# on the tower nearest it (D-0040; never a full Crescendo).
	if (cand["kind"] == "elite" or cand["kind"] == "arrow") and not struck.is_empty() and creeps.has(struck) and struck["hp"] > 0.0:
		var beat := clock.beat_length()
		struck["frozen_until"] = maxf(struck.get("frozen_until", 0.0), sim_time + beat * STAGGER_BEATS)
		var tower := _nearest_tower(struck["pos"])
		if tower.x >= 0:
			var first := (floorf(beat_time() / beat) + 2.0) * beat
			add_note(first, "kick", tower)
			add_note(first + beat, "bass", tower)
			_popup(struck["pos"], "STAGGER", Color(1.0, 0.9, 0.3), 13)
	# Wide guard: creeps near the struck one take half the return.
	var splash: float = gstats.get("parry_splash", 0.0)
	if splash > 0.0 and not struck.is_empty() and struck.has("pos"):
		for c in creeps:
			if c != struck and c["hp"] > 0.0 and c["pos"].distance_to(struck["pos"]) <= splash:
				damage(c, parry_damage() * 0.5 * (2.0 if perfect else 1.0))
	# Fermata: a Perfect parry holds everything for a beat.
	if perfect and gstats.get("fermata", false):
		for c in creeps:
			if not c.get("boss", false):
				c["frozen_until"] = maxf(c.get("frozen_until", 0.0), sim_time + clock.beat_length())
	# Encore: a parry adds a note on the next beat.
	if gstats.get("parry_notes", 0) > 0 and not struck.is_empty():
		var beat := clock.beat_length()
		add_note((floorf(beat_time() / beat) + 2.0) * beat, "kick")
	# The counter (D-0041): a second Space within COUNTER_TAP_MS of this parry, no ring,
	# no beat to wait for. A Perfect parry makes a Perfect counter. Not during a Volley.
	if gstats.get("counter", false) and not struck.is_empty() and creeps.has(struck) and struck["hp"] > 0.0 and not (cand["kind"] == "bolt" and boss2()):
		_counter_open = {"ref": struck, "until": press_time() + COUNTER_TAP_MS / 1000.0, "opened": press_time(), "perfect": perfect}
		m7_stats["counters"] += 1


## Space: the tap after a landed parry fires the counter; otherwise a parry as before.
func _parry() -> void:
	if not _counter_open.is_empty():
		var k: Dictionary = _counter_open
		var since_ms: float = (press_time() - k["opened"]) * 1000.0
		if press_time() <= k["until"]:
			_counter_open = {}
			if creeps.has(k["ref"]) and k["ref"]["hp"] > 0.0:
				on_streak_hit()
				_sfx["parry_perfect" if k["perfect"] else "parry"].play()
				var c := {"at": press_time(), "from": k["opened"], "ref": k["ref"], "state": "flying"}
				_resolve_parry({"time": press_time(), "kind": "counter", "ref": c}, "Perfect" if k["perfect"] else "Good", since_ms)
			return
		_counter_open = {}
		if since_ms < COUNTER_LATE_MS:
			_show_feedback("Counter late (+%.0f ms)   tap right after the parry" % since_ms, Color(1, 1, 1, 0.5))
			return
	super._parry()


## Option A (D-0041): a bolt is parried at the boss as it leaves, not at the Conductor.
func _parry_candidates() -> Array[Dictionary]:
	var out := super._parry_candidates()
	for cand in out:
		if cand["kind"] == "bolt":
			cand["time"] = cand["ref"]["launch"]
	return out


## A posture break rolls its Crescendo chart from a set, and bosses after wave 10
## summon a pack every third break (D-0040).
func _posture_break() -> void:
	# The quiet boss chart makes way for the Crescendo.
	for n in notes.duplicate():
		if n.get("quiet", false) and n["state"] == "open":
			notes.erase(n)
			_wave_notes -= 1
			stats[n["type"]]["notes"] -= 1
	var before := notes.size()
	super._posture_break()
	if TRICKLE_BREAKS.has(m5_stats["breaks"]):
		_release_pack()
	# Replace the fixed Q E Q E burst with a rolled pattern on the same beats and towers.
	var burst: Array[Dictionary] = []
	for n in notes.slice(before):
		burst.append(n)
	if not burst.is_empty():
		var pattern: String = CRESCENDO_SETS[rng.randi() % CRESCENDO_SETS.size()]
		for i in burst.size():
			var ch := pattern[i % pattern.length()]
			var n: Dictionary = burst[i]
			if ch == ".":
				notes.erase(n)
				_wave_notes -= 1
				stats[n["type"]]["notes"] -= 1
			elif ch == "Q" and n["type"] != "kick":
				_retype_note(n, "kick")
			elif ch == "E" and n["type"] != "bass":
				_retype_note(n, "bass")
		_show_feedback("POSTURE BREAK   CRESCENDO   %s" % pattern.replace(".", "-"), Color(1.0, 0.9, 0.3))
	if wave > 10 and m5_stats["breaks"] % SUMMON_EVERY_BREAKS == 0 and boss_alive():
		for i in 4:
			spawn_queue.append({"kind": "runner", "gap": 0.4})
		_to_spawn = spawn_queue.size()
		_say("The boss summons")


func _retype_note(n: Dictionary, type: String) -> void:
	stats[n["type"]]["notes"] -= 1
	n["type"] = type
	stats[type]["notes"] += 1


# --- Slice F: the draft ------------------------------------------------------------------

## Long run: after every boss wave. Quick run: after every other wave.
func wants_draft() -> bool:
	if wave >= last_wave:
		return false
	if quick:
		return wave % 2 == 0
	return boss_waves.has(wave) or EXTRA_DRAFT_WAVES.has(wave)


func card_name(id: String) -> String:
	var c := CardPool.by_id(id)
	return c["name"] if not c.is_empty() else super.card_name(id)


func card_text(id: String) -> String:
	var c := CardPool.by_id(id)
	return c["text"] if not c.is_empty() else super.card_text(id)


func card_condition(id: String) -> String:
	if not pending.is_empty() and pending["id"] == id:
		return CardPool.CONDITIONS.get(pending.get("cond", ""), "")
	return ""


func _open_draft() -> void:
	draft.clear()
	draft_cards.clear()
	var size := int(gstats.get("draft_size", 3))
	var bias := {}
	for cat in CardPool.CATEGORIES:
		bias[cat] = gstats.get("bias_" + cat, 1.0)
	var exclude: Array = card_taken.keys()
	var allow_orange := wave >= 3 and not orange_taken
	var cats := {}
	for i in size:
		var card := CardPool.roll(rng, gstats.get("luck", 0.0), bias, exclude, allow_orange)
		# Soft floor: not three of the same category; one reroll.
		if not card.is_empty() and cats.get(card["cat"], 0) >= 2:
			var again := CardPool.roll(rng, gstats.get("luck", 0.0), bias, exclude, allow_orange)
			if not again.is_empty():
				card = again
		if card.is_empty():
			break
		card = card.duplicate()
		if CardPool.rarity_index(card["rarity"]) >= 2 and pending.is_empty() and rng.randf() < CardPool.LOCK_CHANCE:
			var keys: Array = CardPool.CONDITIONS.keys()
			card["cond"] = keys[rng.randi() % keys.size()]
		exclude.append(card["id"])
		cats[card["cat"]] = cats.get(card["cat"], 0) + 1
		draft_cards.append(card)
		draft.append(card["id"])
	rerolls_left = int(gstats.get("rerolls", 0))
	drafting = not draft_cards.is_empty()


func reroll_draft() -> void:
	if not drafting or rerolls_left <= 0:
		return
	rerolls_left -= 1
	m7_stats["rerolls"] += 1
	var keep := rerolls_left
	_open_draft()
	rerolls_left = keep


func _pick(i: int) -> void:
	if not drafting or i < 0 or i >= draft_cards.size():
		return
	var card: Dictionary = draft_cards[i]
	drafting = false
	picks.append(card["id"])
	card_taken[card["id"]] = true
	if card["rarity"] == "orange":
		orange_taken = true
	if card.has("cond"):
		pending = {"id": card["id"], "wave": wave + 1, "cond": card["cond"], "effects": card["effects"]}
		_show_feedback("LOCKED PICK   %s: %s" % [card["name"], CardPool.CONDITIONS[card["cond"]]], Color(0.8, 0.8, 1.0))
		return
	_apply_effects(card["effects"])
	_show_feedback("PICKED   %s: %s" % [card["name"], card["text"]], Color(CardPool.RARITY_COLORS[card["rarity"]]))


func _judge_pending() -> void:
	if pending.is_empty() or pending["wave"] != wave:
		return
	var p := pending
	pending = {}
	var ok := false
	match p["cond"]:
		"perfects":
			ok = stat_total("perfects") - _base["perfects"] >= 6
		"clean":
			ok = m4_stats["suppressed"] + m4_stats["shields_lost"] + m5_stats["hits"] + m6_stats["stomp_hits"] - _base["landed"] == 0
		"shields":
			ok = m4_stats["shields_lost"] - _base["shields"] == 0
	if ok:
		_apply_effects(p["effects"])
		m6_stats["unlocked"] += 1
		_show_feedback("UNLOCKED   %s: %s" % [card_name(p["id"]), card_text(p["id"])], Color(1.0, 0.9, 0.3))
	else:
		m6_stats["lost"] += 1
		_show_feedback("%s stays locked (%s)" % [card_name(p["id"]), CardPool.CONDITIONS[p["cond"]]], Color(1, 0.5, 0.4))


# --- Slice G: the longer run ---------------------------------------------------------------

func is_boss2_wave(w: int) -> bool:
	return w % 10 == 0


# --- Input ----------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			toggle_tree()
			return
		if tree_open and event.keycode != KEY_ESCAPE:
			return
		if drafting and [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5].has(event.keycode):
			_pick([KEY_1, KEY_2, KEY_3, KEY_4, KEY_5].find(event.keycode))
			return
		if (event.keycode == KEY_U or event.keycode == KEY_I) and state == "playing":
			var type := selected
			if structures.has(selected_cell):
				type = structures[selected_cell]["type"]
			if not is_tower(type):
				_say("Select a tower (or a tower button) to upgrade its type")
			elif type_rank.get(type, 0) == 2:
				upgrade_type(type, 2 if event.keycode == KEY_I else 1)  # The fork: U takes the first branch, I the second.
			elif event.keycode == KEY_U:
				upgrade_type(type)
			return
	if tree_open and event is InputEventMouseButton:
		return
	super._unhandled_input(event)


# --- Drawing and text -------------------------------------------------------------------------

func _draw() -> void:
	super._draw()
	var beat := clock.beat_length()
	var font := ThemeDB.fallback_font
	# The bar strip over the board (D-0041): what each beat asks for, the live beat lit.
	if wave_active and state == "playing":
		var cur := posmod(floori(beat_time() / beat), 4)
		var labels: Array = ["1 parry"]
		for i in 3:
			labels.append("%d %s" % [i + 2, _wave_pattern[i].replace(".", "-")])
		if boss_alive():
			labels = ["1 parry", "2 -", "3 Q boss", "4 -"] if crescendo <= 0.0 else ["CRESCENDO", "", "", ""]
		for i in 4:
			var r := Rect2(_origin.x + i * 66.0, _origin.y - 24.0, 62.0, 18.0)
			var lit := i == cur
			var col := Color(1.0, 0.6, 0.35) if i > 0 else Color(1.0, 0.9, 0.3)
			if i > 0 and _wave_pattern[i - 1] == "E":
				col = Color(0.7, 0.45, 1.0)
			draw_rect(r, col * Color(1, 1, 1, 0.35 if lit else 0.1))
			draw_rect(r, col * Color(1, 1, 1, 0.9 if lit else 0.35), false, 1.0)
			draw_string(font, r.position + Vector2(5, 13), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 1.0 if lit else 0.6))
	# The counter window: a yellow flash on the parried enemy for the tap.
	if not _counter_open.is_empty() and creeps.has(_counter_open["ref"]):
		var a: float = clampf((_counter_open["until"] - press_time()) / (COUNTER_TAP_MS / 1000.0), 0.0, 1.0)
		if a > 0.0:
			var p := _to_screen(_counter_open["ref"]["pos"])
			draw_arc(p, TILE * (0.6 + 0.5 * (1.0 - a)), 0, TAU, 32, Color(1.0, 0.9, 0.3, 0.3 + 0.7 * a), 3.0)
			draw_string(font, p + Vector2(-16, -TILE * 0.8), "TAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.9, 0.3))
	# Veils: a purple ring that fades as it cracks, with the damage it still blocks.
	for c in creeps:
		if c.get("veil", false) and c["hp"] > 0.0 and int(c.get("cracks", 0)) < VEIL_MULTS.size() - 1:
			var p := _to_screen(c["pos"])
			var cracks := int(c.get("cracks", 0))
			draw_arc(p, TILE * 0.42, 0, TAU, 24, Color(0.6, 0.4, 1.0, 0.9 - 0.25 * cracks), 3.0 - 0.6 * cracks)
			draw_string(font, p + Vector2(-9, TILE * 0.75), "%d%%" % roundi(VEIL_MULTS[cracks] * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.6, 1.0))
	# Boss bolts (D-0041 option A): the parry ring closes on the boss over the last beat
	# before the throw; a bolt that got away flies red to the Conductor.
	if boss_alive():
		var bp := _to_screen(boss["pos"])
		for b in bolts:
			if b["state"] == "flying":
				var to_launch: float = b["launch"] - beat_time()
				if to_launch < beat and to_launch > -0.2:
					var f: float = clampf(1.0 - to_launch / beat, 0.0, 1.0)
					draw_arc(bp, TILE * (1.8 - 1.05 * f), 0, TAU, 40, Color(1.0, 0.9, 0.3, 0.4 + 0.6 * f), 2.0 + 2.0 * f)
					draw_arc(bp, TILE * 0.75, 0, TAU, 48, Color(1.0, 0.9, 0.3, 0.9), 2.0)
				break
		for b in bolts:
			if b["state"] == "loose":
				var p := _to_screen(_bolt_pos(b))
				draw_circle(p, TILE * 0.22, Color(1, 0.3, 0.3))
				draw_circle(p, TILE * 0.1, Color.WHITE)
	# Counters: a yellow ring closing on the parried enemy over one beat.
	for k in counters:
		if k["state"] != "flying" or not creeps.has(k["ref"]):
			continue
		var p := _to_screen(k["ref"]["pos"])
		var frac: float = clampf((beat_time() - k["from"]) / maxf(k["at"] - k["from"], 0.01), 0.0, 1.0)
		draw_arc(p, TILE * (1.6 - 1.1 * frac), 0, TAU, 40, Color(1.0, 0.9, 0.3, 0.4 + 0.6 * frac), 2.0 + 2.0 * frac)
		draw_arc(p, TILE * 0.5, 0, TAU, 32, Color(1.0, 0.9, 0.3, 0.9), 2.0)
	for g in ghosts:
		if creeps.has(g["target"]):
			var p := _to_screen(g["target"]["pos"]) + Vector2(0, -TILE * 0.7)
			draw_circle(p, 5.0, Color(0.8, 0.9, 1.0, 0.6))
	for b in burning:
		var a: float = clampf((b["until"] - sim_time) / clock.bar_length(), 0.0, 1.0)
		draw_circle(_to_screen(b["pos"]), TILE * 0.7, Color(1.0, 0.5, 0.2, 0.15 + 0.2 * a))
	for c in creeps:
		if c.get("poison", 0.0) > 0.0 and c["hp"] > 0.0 and (type_branch["poison"] == 2 or c.get("poison_until", 0.0) > sim_time):
			var p := _to_screen(c["pos"])
			draw_circle(p, TILE * 0.3, Color(0.4, 1.0, 0.3, 0.45))
			draw_arc(p, TILE * 0.3, 0, TAU, 16, Color(0.6, 1.0, 0.4, 0.9), 1.5)
			draw_string(ThemeDB.fallback_font, p + Vector2(-8, -TILE * 0.45), "%d" % roundi(c["poison"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 1.0, 0.4))
	# Rung pips on every tower; the fork colours them.
	for cell in structures:
		var type: String = structures[cell]["type"]
		var rank: int = type_rank.get(type, 0)
		if not is_tower(type) or rank <= 0:
			continue
		var branch: int = type_branch.get(type, 0)
		var col := Color.WHITE if branch == 0 else (Color(0.5, 0.9, 1.0) if branch == 1 else Color(1.0, 0.6, 0.3))
		var tc := _to_screen(Vector2(cell)) + Vector2(-TILE * 0.38, TILE * 0.38)
		for i in rank:
			draw_circle(tc + Vector2(i * 5.0, 0), 1.8, col)
		if branch > 0:
			draw_arc(_to_screen(Vector2(cell)), TILE * 0.4, 0, TAU, 24, col * Color(1, 1, 1, 0.7), 1.5)
	# Level bar under the title.
	var x := 24.0
	var y := 42.0
	draw_rect(Rect2(x + 330, y - 8, 100, 6), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(x + 330, y - 8, 100 * clampf(xp / xp_to_next(), 0.0, 1.0), 6), Color(0.6, 1.0, 0.7))
	draw_string(ThemeDB.fallback_font, Vector2(x + 436, y), "Lv %d%s" % [level, ("   %d point%s (Tab)" % [points, "" if points == 1 else "s"]) if points > 0 else ""], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 1.0, 0.7) if points > 0 else Color(1, 1, 1, 0.6))


func run_lines() -> Array[String]:
	var lines := super.run_lines()
	var taken: Array[String] = []
	for id in owned:
		var n: Dictionary = TalentTree.nodes()[id]
		var label: String = n["name"] + ((" %d" % TalentTree.ranks(id, owned)) if n["max"] > 1 else "")
		if not taken.has(label):
			taken.append(label)
	lines.append("Level %d   XP %d   Talents %d (%s)" % [level, roundi(m7_stats["xp"]), owned.size(), ", ".join(taken) if not taken.is_empty() else "none"])
	var ranks: Array[String] = []
	for type in ["kick", "bass", "slow", "poison", "lightning", "light"]:
		if type_rank.get(type, 0) > 0:
			ranks.append("%s %d%s" % [tower_name(type), type_rank[type], (" " + BRANCHES[type][type_branch[type] - 1][0]) if type_branch[type] > 0 else ""])
	lines.append("Type upgrades: %s   Unlocked: %s" % [", ".join(ranks) if not ranks.is_empty() else "none", ", ".join(unlocked.slice(4).map(func(t): return tower_name(t))) if unlocked.size() > 4 else "none"])
	lines.append("Crits %d   Arcs %d   Poison %d   Counters %d of %d" % [m7_stats["crits"], m7_stats["arcs"], roundi(m7_stats["poison"]), m7_stats["counter_hits"], m7_stats["counters"]])
	lines.append("Stats: " + stats_line())
	if not wave_log.is_empty():
		lines.append("")
		lines.append("By wave (hit/offered):")
		var i := 0
		while i < wave_log.size():
			lines.append("   |   ".join(wave_log.slice(i, i + 2)))
			i += 2
	return lines


## The global stats block (slice H), one line.
func stats_line() -> String:
	var parts: Array[String] = []
	var show := {"damage_mult": "damage", "crit_chance": "crit", "crit_mult": "crit dmg", "luck": "luck", "gold_mult": "gold", "xp_mult": "XP", "enemy_speed_mult": "enemy speed", "enemy_attack_mult": "enemy wind-up", "parry_mult": "parry", "parry_window_ms": "parry ms", "range_all": "range"}
	for k in show:
		var v: float = gstats.get(k, 0.0)
		if v != 0.0:
			if k in ["luck", "parry_window_ms", "range_all"]:
				parts.append("%s %+.1f" % [show[k], v] if k == "range_all" else "%s %+d" % [show[k], int(v)])
			else:
				parts.append("%s %+d%%" % [show[k], roundi(v * 100.0)])
	return ", ".join(parts) if not parts.is_empty() else "base"


## The M7 column from scratch: short lines that fit left of the board (the
## long per-key stat lines from M3 to M6 spilled onto the map on Jared's screen).
func status_lines() -> Array[String]:
	var wave_label := ("Wave %d (endless)" % wave) if endless or wave > last_wave else ("Wave %d/%d" % [wave, last_wave])
	var lines: Array[String] = [
		"Gold %d   Health %d   Walls %d/%d" % [gold, health, wall_count(), wall_limit],
		(wave_label + " in progress") if wave_active else ("N starts wave %d%s" % [wave + 1, _unspent_hint()]),
		"Selected: %s %dg   Shields %d/%d   Restores %d/%d" % [selected, builds.get(selected, {}).get("cost", 0), shields, shield_cap, restore_charges, restore_cap()],
		"",
	]
	var notes := stat_total("notes")
	var hits := stat_total("hits")
	var rate := 0 if notes == 0 else roundi(100.0 * hits / notes)
	lines.append("Notes %d/%d (%d%%)   Perfects %d   streak %d" % [hits, notes, rate, stat_total("perfects"), streak])
	lines.append("Bar: %s" % pattern_text())
	var thrown: int = m4_stats["pulses"] + m4_stats["arrows"] + m5_stats["bolts"] + m6_stats["stomps"]
	var parried: int = m4_stats["parried"] + m5_stats["parries"] + m6_stats["stomp_parries"]
	lines.append("Parries %d/%d   Counters %d/%d   Locked %d   Shields lost %d" % [parried, thrown, m7_stats["counter_hits"], m7_stats["counters"], m4_stats["suppressed"], m4_stats["shields_lost"]])
	if boss_alive():
		lines.append("Boss: breaks %d   bolts parried %d/%d" % [m5_stats["breaks"], m5_stats["parries"], m5_stats["bolts"]])
	if crescendo > 0.0:
		lines.append("CRESCENDO  %.1f s" % crescendo)
	lines.append("")
	lines.append("Level %d   XP %d/%d   Points %d" % [level, roundi(xp), roundi(xp_to_next()), points])
	lines.append("Stats: %s" % stats_line())
	if not pending.is_empty():
		lines.append("Locked card: %s (%s)" % [card_name(pending["id"]), card_condition(pending["id"])])
	lines.append("Picks (%d): %s" % [picks.size(), ", ".join(picks.map(func(id): return card_name(id))) if not picks.is_empty() else "none yet"])
	lines.append("Song: %s   %.0f BPM   [ ] switch" % [songs[song_index]["name"], clock.bpm])
	return lines


func help_lines() -> Array[String]:
	if selected_cell.x >= 0 or (hud != null and hud.panel.visible):
		return []
	return [
		"Q / E  the key on a tower as its ring lands (beats 2 to 4)",
		"Space  parry on beat 1; tap again at once = counter-attack",
		"Shades: 10% damage until notes crack the veil",
		"Tab  talent tree   U / I  upgrade or fork the selected type",
		"Click a tower for its panel.  Right click sells.  Esc twice  menu",
		"",
		"TEST  T speed %dx   Y auto %s   G +100g   H skip   O boss" % [SPEEDS[speed_index], "ON" if auto_send else "off"],
		"Next wave: %s   (%.0f HP each)" % [wave_summary(wave + 1), creep_hp_at(wave + 1)],
	]
