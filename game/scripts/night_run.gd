class_name NightRun
extends LevelRun
## One night of the five-night campaign (B1 + B2, D-0067). Everything from the
## song level (LevelRun), plus:
##
## B1, progression (D-0056 to D-0059):
## - Nights in a row (Campaign): health, XP, level, talents and cards carry over;
##   the map, gold and type upgrades stay at the old camp.
## - The locked talent tree (NightTree): points come on each morning (1, 3, 3, 3),
##   spent between nights, never mid-night. Levels no longer give points.
## - Towers unlock only through the tree; nothing unlocks mid-night.
## - Type upgrades: rung 1 picks one of two forks (about 2x the tower's price),
##   rung 2 is that fork's mastery (about 4x).
## - Cards (NightCards): a pick of three after Nights 1 to 4.
## - Tower renames: the old Cannon (snipes, code "kick") is the Arrow, the old
##   Splash (area, code "bass") is the Cannon. Code ids stay as they were.
##
## B2, enemies (D-0061):
## - New names (DEMO_NAMES), notes target a boss or elite while one is in view.
## - Door-to-Door, Last Orders, Busker, Digger, Undertaker, Moths; The Foreman
##   (drum speeds its escort) and The Landlord (stage boss, Night 5).
## - Test arena: J picks an enemy, K drops it at the mine.
##
## Numbers are first guesses; balance is B5.

const TOWER_NAMES_DEMO := {"kick": "Arrow", "bass": "Cannon", "slow": "Frost", "poison": "Poison", "lightning": "Lightning", "light": "Light", "wall": "Wall"}
const DEMO_NAMES := {"grunt": "Bonehead", "runner": "Legger", "swarm": "Knucklebones", "brute": "Big Lad", "shade": "Hush",
	"jammer": "Spanner", "archer": "Pot-shot", "warden": "Crossing Guard", "door": "Door-to-Door", "last_orders": "Last Orders",
	"busker": "Busker", "digger": "Digger", "undertaker": "Undertaker", "moth": "Moth",
	"boss": "The Night Manager", "night_manager": "The Night Manager", "foreman": "The Foreman", "landlord": "The Landlord"}
## What each new enemy is built on, and how it differs (health and speed x the base).
const NEW_BASE := {
	"door": {"base": "grunt", "hp": 1.6, "speed": 0.9},
	"busker": {"base": "grunt", "hp": 1.3, "speed": 0.9},
	"digger": {"base": "brute", "hp": 0.8, "speed": 1.0},
	"moth": {"base": "swarm", "hp": 0.4, "speed": 1.4},
	"last_orders": {"base": "jammer", "hp": 1.0, "speed": 1.0},
	"undertaker": {"base": "jammer", "hp": 1.1, "speed": 0.9},
}
const NEW_XP := {"door": 2.0, "busker": 3.0, "digger": 3.0, "moth": 0.3, "last_orders": 8.0, "undertaker": 8.0}

## The mastery for each fork (D-0059; drafts, Jared reviews them in the B1+B2 test).
const MASTERY := {
	"kick": [["Skewer", "snipes and shots pass through every creep in a line behind the target"], ["Breach", "a hit creep takes 25% more from everything for 2 s"]],
	"bass": [["Aftershock", "a second wave a beat later, half damage, staggers again"], ["Wildfire", "burning ground spreads a tile down the path each beat, up to 3"]],
	"slow": [["Shatter", "a frozen creep that dies freezes everything within a tile"], ["Cold snap", "slowed creeps count as frozen (they always take crits)"]],
	"poison": [["Plague", "poison stacks up to 3 times"], ["Necrosis", "poison ticks 10% harder each beat it stays (up to x3)"]],
	"lightning": [["Storm", "arcs lose no damage as they jump"], ["Overcharge", "every fourth strike stuns for half a beat"]],
	"light": [["Lantern", "towers in the light attack 15% faster"], ["Daybreak", "cracked Hushes take 25% more until they die"]],
}
const FORK_PRICE := 2.0  # x the tower's base price.
const MASTERY_PRICE := 4.0
const DOOR_BLOCK := 0.2  # Share of a hit from ahead that gets through a door.
const DOOR_ARC := 0.35  # Cosine: hits from within about 70 degrees of straight ahead are blocked.
const BUSKER_RADIUS := 3.0
const BUSKER_BOOST := 0.6  # Creeps near a drum move this much faster in the first half of every beat (about +30% overall).
const DIG_BARS := 4
const DIG_REACH := 1.25
const GRAVE_RISE_BARS := 2
const GRAVE_COUNT := 3
const MOTHS_PER_HEALTH := 3  # Moths are tiny: every third one at the fire costs 1 health.
const LANDLORD_HP := 2.0
const MORNING_REPAIR := 4  # Health the camp repairs each morning, up to full (playtest 1, D-0070).
const SOLO_SECONDS := 8.0
const ARENA_KINDS := ["grunt", "runner", "swarm", "brute", "shade", "jammer", "archer", "warden", "door", "last_orders", "busker", "digger", "undertaker", "moth", "night_manager", "foreman", "landlord"]

var repaired := 0  # Health repaired this morning, for the morning screen.
var night_owned: Array[String] = []  # Talents taken this run (NightTree ids).
var card_picks: Array[String] = []  # Cards taken this run, in order.
var accum_crit := 0.0  # Perfect Accumulation: crit chance earned so far this run.
var graves: Array[Dictionary] = []  # cell, rise_at, count
var moth_leaks := 0
var b2_stats := {"blocked": 0, "bells": 0, "bells_parried": 0, "digs": 0, "walls_dug": 0, "graves": 0, "raised": 0, "moths_in": 0, "auto_parries": 0, "solos": 0}
var auto_parry_until := -INF  # Perfect Solo: parries and counters happen by themselves until then.
var _src := Vector2(INF, INF)  # Where the hit being dealt comes from (doors block hits from ahead).
var _shot_acc := {}  # cell -> extra-shot meter (Quick Draw, Lantern)
var _strikes := {}  # cell -> Lightning strikes, for Overcharge
var _aftershocks: Array[Dictionary] = []  # at, pos, amount, radius
var _mute := Vector2(-INF, -INF)  # Last Orders: notes landing in [x, y) are taken off.
var _cres := {}  # Crescendo id -> {n, hit, perfect, missed}
var _cres_next := 1
var _note_scale := 1.0  # Grace and off-beat notes hit for a share.
var _arena := 0
var _carry_text := ""


# --- Setup and carryover ----------------------------------------------------------------

func _ready() -> void:
	super._ready()
	gstats["counter"] = false  # Counter Attack is a talent in the campaign (D-0059).
	if Campaign.active:
		_load_carry(Campaign.carry)
	gold += int(gstats.get("night_gold", 0))
	_apply_stats()


func _load_carry(c: Dictionary) -> void:
	if c.is_empty():
		return
	health = int(c.get("health", health))
	level = int(c.get("level", level))
	xp = float(c.get("xp", xp))
	points = int(c.get("points", 0))
	for id in c.get("talents", []):
		_take(id, false)
	for id in c.get("cards", []):
		var card := NightCards.by_id(id)
		if not card.is_empty():
			card_picks.append(id)
			picks.append(id)
			_apply_effects(card["effects"])
	card_taken = c.get("card_taken", {}).duplicate()
	orange_taken = c.get("orange_taken", false)
	accum_crit = float(c.get("accum_crit", 0.0))
	if accum_crit > 0.0:
		gstats["crit_chance"] = gstats.get("crit_chance", 0.0) + accum_crit
	_xp_start = {"level": level, "xp": xp}


func tower_name(type: String) -> String:
	return TOWER_NAMES_DEMO.get(type, type.capitalize())


static func enemy_name(kind: String) -> String:
	return DEMO_NAMES.get(kind, kind.capitalize())


## Levels still come from XP (a stat), but points come on the morning (D-0058).
func gain_xp(amount: float) -> void:
	var p := points
	super.gain_xp(amount)
	points = p


func _finish() -> void:
	super._finish()
	var n: int = Campaign.POINTS_AFTER[Campaign.index] if Campaign.active else Campaign.POINTS_AFTER[0]
	points += n
	var before := health
	health = mini(START_HEALTH, health + MORNING_REPAIR)  # The camp patches up overnight (D-0070).
	repaired = health - before
	if n > 0:
		_watchman("Made it to morning. %d talent point%s. Hey, I just work here." % [n, "" if n == 1 else "s"], 5.0)


## Talents between nights; before Start only when the night picker handed out points.
func toggle_tree() -> void:
	if not started and (points > 0 or tree_open) and state == "playing":
		tree_open = not tree_open  # Done always closes it, even with every point spent.
		return
	super.toggle_tree()


func take_night_talent(id: String) -> bool:
	if started and night_phase != "summary":
		_say("Talents are spent after the night")
		return false
	if not NightTree.available(id, night_owned, points):
		return false
	points -= 1
	_take(id, true)
	return true


func _take(id: String, announce: bool) -> void:
	if not NightTree.NODES.has(id) or night_owned.has(id):
		return
	specs_changed()
	var n: Dictionary = NightTree.NODES[id]
	night_owned.append(id)
	m7_stats["talents"] += 1
	var effects: Dictionary = n["effects"].duplicate()
	if effects.has("unlock"):
		if announce:
			_unlock(effects["unlock"])
		elif not unlocked.has(effects["unlock"]):
			unlocked.append(effects["unlock"])
		effects.erase("unlock")
	if not effects.is_empty():
		_apply_effects(effects)
	if announce:
		_show_feedback("TALENT   %s" % n["name"], Color(0.6, 1.0, 0.7))


## No mid-night unlocks in the campaign (D-0056): the tree is the only way.
func _check_unlocks() -> void:
	pass


func unlock_text(type: String) -> String:
	return "unlock it in the talent tree" if UNLOCKS.has(type) else ""


func unlock_short(type: String) -> String:
	return "Talent" if UNLOCKS.has(type) else ""


## One line for the run log and the campaign's history.
func night_summary() -> String:
	var t := _totals()
	return "Night %d  %s  %s  health %d  notes %d/%d  parries %d/%d" % [Campaign.night_number(), night["name"].split(": ")[-1],
		"held" if state == "won" else "fell", health, t["hits"], t["notes"], t["parried"], t["throws"]]


# --- Cards --------------------------------------------------------------------------------

func _open_draft() -> void:
	draft.clear()
	draft_cards.clear()
	if Campaign.active and Campaign.is_last():
		drafting = false  # No card after Night 5: the run is over.
		return
	for card in NightCards.roll_hand(rng, 3, gstats.get("luck", 0.0), card_taken, not orange_taken):
		var shown: Dictionary = card.duplicate()
		shown["night_rarity"] = card["rarity"]
		shown["rarity"] = NightCards.RARITY_SLOT[card["rarity"]]
		shown["gems"] = NightCards.RARITIES.find(card["rarity"]) + 1
		shown["cat_name"] = NightCards.CATEGORY_NAMES.get(card["cat"], card["cat"])
		shown["cat"] = NightCards.CATEGORY_GLYPH.get(card["cat"], "star")
		draft_cards.append(shown)
		draft.append(card["id"])
	rerolls_left = 0
	drafting = not draft_cards.is_empty()


func _pick(i: int) -> void:
	if not drafting or i < 0 or i >= draft_cards.size():
		return
	var card: Dictionary = draft_cards[i]
	drafting = false
	picks.append(card["id"])
	card_picks.append(card["id"])
	card_taken[card["id"]] = true
	if card["night_rarity"] == "legendary":
		orange_taken = true
	_apply_effects(card["effects"])
	for k in card.get("once", {}):
		if k == "health":
			health = maxi(1, health + int(card["once"][k]))
	_show_feedback("PICKED   %s" % card["name"], Color(HudKit.RARITY.get(card["rarity"], Color.WHITE)))
	if ending:
		state = "won"


func card_name(id: String) -> String:
	var c := NightCards.by_id(id)
	return c["name"] if not c.is_empty() else super.card_name(id)


func card_text(id: String) -> String:
	var c := NightCards.by_id(id)
	return c["text"] if not c.is_empty() else super.card_text(id)


## Heavy and Light boots change how many come; Wanted posters adds an elite.
func _adjust_plan(plan: Array[Dictionary], s: Dictionary) -> Array[Dictionary]:
	var mult: float = 1.0 + gstats.get("enemy_count_mult", 0.0)
	var out: Array[Dictionary] = []
	var acc := 0.0
	for e in plan:
		if ELITE_KINDS.has(e["kind"]) or e["kind"] in ["last_orders", "undertaker"] or mult == 1.0:
			out.append(e)
			continue
		acc += mult
		while acc >= 1.0:
			out.append(e)
			acc -= 1.0
	if int(gstats.get("extra_elite", 0)) > 0 and s["kind"] != "lull" and not out.is_empty():
		var pick: String = ["jammer", "archer", "warden"][rng.randi() % 3]
		out.insert(mini(out.size(), 3), {"kind": pick, "gap": clock.beat_length() * 2.0})
	return out


# --- Upgrades: fork, then mastery (D-0058, D-0059) -------------------------------------------

func fork_rank() -> int:
	return 0


func top_rank() -> int:
	return 2


func mastered(type: String) -> bool:
	return type_rank.get(type, 0) >= 2


func rank_label(type: String) -> String:
	var rank: int = type_rank.get(type, 0)
	var b: int = type_branch.get(type, 0)
	if rank == 0 or b == 0:
		return "no fork yet"
	return BRANCHES[type][b - 1][0] + ("  +  " + MASTERY[type][b - 1][0] if rank >= 2 else "")


## What the upgrade buttons do, for the tower card (fork tooltips, D-0070).
func upgrade_help(type: String) -> String:
	if not BRANCHES.has(type) or not MASTERY.has(type):
		return ""
	var rank: int = type_rank.get(type, 0)
	if rank == 0:
		var out: Array[String] = []
		for i in 2:
			out.append("%s  %s: %s.\n     Then %s: %s." % ["U" if i == 0 else "I", BRANCHES[type][i][0], BRANCHES[type][i][1], MASTERY[type][i][0], MASTERY[type][i][1]])
		return "Pick a fork for every %s (%dg), then its mastery (%dg):\n%s" % [tower_name(type), type_upgrade_cost(type), roundi(type_upgrade_cost(type) * MASTERY_PRICE / FORK_PRICE), "\n".join(out)]
	var b: int = type_branch.get(type, 1)
	if rank == 1:
		return "Mastery  %s: %s." % [MASTERY[type][b - 1][0], MASTERY[type][b - 1][1]]
	return "%s: %s.  %s: %s." % [BRANCHES[type][b - 1][0], BRANCHES[type][b - 1][1], MASTERY[type][b - 1][0], MASTERY[type][b - 1][1]]


func type_upgrade_cost(type: String) -> int:
	var rank: int = type_rank.get(type, 0)
	if rank >= 2:
		return 0
	var base: float = _base_cost.get(type, builds[type]["cost"])
	var price := base * (FORK_PRICE if rank == 0 else MASTERY_PRICE)
	price *= 1.0 - gstats.get("upgrade_discount", 0.0)
	return maxi(1, roundi(price))


func rung_text(type: String, rank: int) -> String:
	if rank == 1:
		return "the fork: %s or %s" % [BRANCHES[type][0][0], BRANCHES[type][1][0]]
	if rank == 2 and type_branch.get(type, 0) > 0:
		var m: Array = MASTERY[type][type_branch[type] - 1]
		return "%s: %s" % [m[0], m[1]]
	return "maxed"


func upgrade_type(type: String, branch := 0) -> bool:
	specs_changed()
	if not is_tower(type) or state != "playing":
		return false
	if not unlocked.has(type):
		_say("%s is locked: %s" % [tower_name(type), unlock_text(type)])
		return false
	var rank: int = type_rank.get(type, 0)
	if rank >= 2:
		_say("%s is mastered" % tower_name(type))
		return false
	if rank == 0 and branch == 0:
		_say("Pick a fork for %s: U %s, I %s" % [tower_name(type), BRANCHES[type][0][0], BRANCHES[type][1][0]])
		return false
	var cost := type_upgrade_cost(type)
	if gold < cost:
		_say("Not enough gold (%dg for %s)" % [cost, tower_name(type)])
		return false
	gold -= cost
	type_rank[type] = rank + 1
	if rank == 0:
		type_branch[type] = branch
	m7_stats["upgrades"] += 1
	var b: int = type_branch[type]
	var what: String = ("FORK   %s: %s" % [BRANCHES[type][b - 1][0], BRANCHES[type][b - 1][1]]) if rank == 0 else ("MASTERY   %s: %s" % [MASTERY[type][b - 1][0], MASTERY[type][b - 1][1]])
	for cell in structures:
		if structures[cell]["type"] == type:
			_flashes[cell] = 0.6
			_popup(Vector2(cell), BRANCHES[type][b - 1][0] if rank == 0 else MASTERY[type][b - 1][0], Color(1.0, 0.9, 0.3), 12)
	_show_feedback("%s   %s" % [tower_name(type).to_upper(), what], Color(1.0, 0.9, 0.3))
	return true


## Upgrades no longer add flat damage: the fork and its mastery are the upgrade.
## Extended Reach adds a share of range.
func type_spec(type: String) -> Dictionary:
	var base: Dictionary = builds[type]
	if not base.has("range"):
		return base
	var spec: Dictionary = base.duplicate()
	var dmg: float = 1.0 + gstats.get("damage_" + type, 0.0)
	spec["range"] = (spec["range"] + gstats.get("range_all", 0.0) + gstats.get("range_" + type, 0.0)) * (1.0 + gstats.get("range_pct", 0.0))
	if spec.get("splash", 0.0) > 0.0:
		spec["splash"] += gstats.get("splash_bonus", 0.0)
	spec["damage"] *= dmg
	return spec


func pattern_for(type: String) -> Array:
	return PATTERNS7.get(type, []).duplicate()


func light_boost() -> float:
	return LIGHT_BUFF * (1.0 + gstats.get("damage_light", 0.0))


func _in_light(cell: Vector2i) -> bool:
	var reach := light_radius()
	for other in _light_cells():
		if other != cell and Vector2(other).distance_to(Vector2(cell)) <= reach:
			return true
	return false


# --- Firing ---------------------------------------------------------------------------------

## The towers' beat (M7's, with the forks, the masteries and the talents that
## change it: Quick Draw and Lantern add shots, Improved Light adds off-beats).
func _fire_towers_on(pattern_step: int) -> void:
	for cell in structures.keys():
		if not structures.has(cell):
			continue
		var type: String = structures[cell]["type"]
		if not is_tower(type) or not tower_ready(cell):
			continue
		var steps := pattern_for(type)
		if gstats.get("improved_light", false) and type != "light" and _in_light(cell):
			# Improved Light: half a beat after each of its own shots, it fires again.
			for st in steps.duplicate():
				if not steps.has((st + 1) % STEPS_PER_BAR):
					steps.append((st + 1) % STEPS_PER_BAR)
		if pattern_step == STEPS_PER_BAR - 1 and gstats.get("pickup", false) and type != "light":
			_tower_shot(cell)  # Pickup: one more shot on the "and" of beat 4 (D-0070).
		if not steps.has(pattern_step):
			continue
		_tower_shot(cell)
		var rate: float = gstats.get("attack_speed", 0.0)
		if type_branch.get("light", 0) == 1 and mastered("light") and _in_light(cell):
			rate += 0.15
		if rate > 0.0 and type != "light":
			_shot_acc[cell] = _shot_acc.get(cell, 0.0) + rate
			if _shot_acc[cell] >= 1.0:
				_shot_acc[cell] -= 1.0
				_tower_shot(cell)


func _tower_shot(cell: Vector2i) -> void:
	var s: Dictionary = structures[cell]
	var type: String = s["type"]
	var spec := tower_spec(cell)
	if type == "light":
		_light_pulse(cell, spec)
		return
	var target := _pick_target(Vector2(cell), spec["range"])
	if target.is_empty():
		return
	var amount: float = spec["damage"] * damage_scale()
	var branch: int = type_branch.get(type, 0)
	var master := mastered(type)
	_src = Vector2(cell)
	match type:
		"poison":
			_poison(target, amount)
			if branch == 1:
				for c in creeps:
					if c != target and c["hp"] > 0.0 and c["pos"].distance_to(target["pos"]) <= 1.0:
						_poison(c, amount)
		"lightning":
			_hit(target, spec, amount)
			_arc(target, amount, spec["color"])
			if branch == 2 and master:
				_strikes[cell] = _strikes.get(cell, 0) + 1
				if _strikes[cell] % 4 == 0:
					target["frozen_until"] = maxf(target.get("frozen_until", 0.0), sim_time + clock.beat_length() * 0.5)
					_popup(target["pos"], "STUN", Color(0.8, 0.9, 1.0), 12)
		"kick":
			if branch == 2 and (target.get("kind", "") == "brute" or target.get("boss", false)):
				amount *= 2.0
			_hit(target, spec, amount)
			if branch == 2 and master:
				target["breach_until"] = sim_time + 2.0
			if branch == 1:
				for c in _nearest_to(target, 2, 1.6):
					damage(c, amount * 0.5)
				if master:
					for c in _line_behind(Vector2(cell), target):
						damage(c, amount * 0.6)
			if gstats.get("arrow_two", false):
				for c in _nearest_to(target, 1, 2.0):
					damage(c, amount)
		"bass":
			_hit(target, spec, amount)
			if branch == 1:
				for c in creeps:
					if c["pos"].distance_to(target["pos"]) <= spec["splash"]:
						c["frozen_until"] = maxf(c.get("frozen_until", 0.0), sim_time + clock.beat_length() * 0.5)
				if master:
					_aftershocks.append({"at": beat_time() + clock.beat_length(), "pos": target["pos"], "amount": amount * 0.5, "radius": spec["splash"]})
			elif branch == 2:
				burning.append({"pos": target["pos"], "until": sim_time + clock.bar_length(), "gen": 0 if master else 99, "cell": Vector2i(target["pos"].round())})
		_:
			_hit(target, spec, amount)
			if spec.has("slow"):
				target["slow_until"] = sim_time + spec["slow"]
			if type == "slow" and branch == 1:
				s["hits"] = int(s.get("hits", 0)) + 1
				if s["hits"] % 3 == 0:
					target["frozen_until"] = maxf(target.get("frozen_until", 0.0), sim_time + clock.beat_length())
	_src = Vector2(INF, INF)
	_flashes[cell] = 0.12
	shots.append({"from": Vector2(cell), "to": target["pos"], "color": spec["color"], "ttl": 0.12, "splash": spec["splash"]})


## The `count` live creeps nearest `target` within `reach`, not the target.
func _nearest_to(target: Dictionary, count: int, reach: float) -> Array:
	var near := []
	for c in creeps:
		if c != target and c["hp"] > 0.0 and c["pos"].distance_to(target["pos"]) <= reach:
			near.append(c)
	near.sort_custom(func(a, b): return a["pos"].distance_to(target["pos"]) < b["pos"].distance_to(target["pos"]))
	return near.slice(0, count)


## Skewer: creeps within half a tile of the line from the tower through the target, beyond it.
func _line_behind(from: Vector2, target: Dictionary) -> Array:
	var dir: Vector2 = (target["pos"] - from).normalized()
	var out := []
	for c in creeps:
		if c == target or c["hp"] <= 0.0:
			continue
		var rel: Vector2 = c["pos"] - target["pos"]
		var along := rel.dot(dir)
		if along > 0.0 and along < 6.0 and absf(rel.cross(dir)) <= 0.5:
			out.append(c)
	return out


## Plague lets poison stack three times; without it a new dose only tops it up.
func _poison(c: Dictionary, amount: float) -> void:
	var cap := 3.0 if (type_branch.get("poison", 0) == 1 and mastered("poison")) else 1.0
	var cur: float = c.get("poison", 0.0) if c.get("poison_until", 0.0) > sim_time or type_branch.get("poison", 0) == 2 else 0.0
	c["poison"] = minf(cur + amount, maxf(cur, amount * cap))
	c["poison_base"] = maxf(float(c.get("poison_base", 0.0)), amount)
	c["poison_until"] = maxf(float(c.get("poison_until", 0.0)), sim_time + POISON_SECONDS)


## Lightning: Fork and Improved Lightning add jumps; Static reaches further;
## Storm keeps the damage up as it jumps.
func _arc(from_creep: Dictionary, amount: float, color: Color) -> void:
	var jumps := ARC_JUMPS + (1 if type_branch.get("lightning", 0) == 1 else 0) + int(gstats.get("arc_jumps", 0))
	var reach: float = ARC_RANGE + gstats.get("arc_range", 0.0) + (2.0 if type_branch.get("lightning", 0) == 2 else 0.0)
	var falloff := 1.0 if (type_branch.get("lightning", 0) == 1 and mastered("lightning")) else ARC_FALLOFF
	var hit := [from_creep]
	var last := from_creep
	for j in jumps:
		var next := {}
		var best := reach
		for c in creeps:
			if c["hp"] > 0.0 and not hit.has(c) and c["pos"].distance_to(last["pos"]) <= best:
				next = c
				best = c["pos"].distance_to(last["pos"])
		if next.is_empty():
			break
		amount *= falloff
		damage(next, amount)
		m7_stats["arcs"] += 1
		shots.append({"from": last["pos"], "to": next["pos"], "color": color, "ttl": 0.15, "splash": 0.0, "width": 2.0})
		hit.append(next)
		last = next


## Every hit: doors block from ahead, Breach and Daybreak add, Cold snap counts a
## slowed creep as frozen, grace and off-beat notes hit for their share.
func damage(c: Dictionary, amount: float) -> float:
	amount *= _note_scale
	if c.get("door", false) and _src.x < INF:
		var ahead: Vector2 = Vector2(c["target"]) - c["pos"]
		if ahead.length() > 0.01 and ahead.normalized().dot((_src - c["pos"]).normalized()) > DOOR_ARC:
			amount *= DOOR_BLOCK
			b2_stats["blocked"] += 1
			if rng.randf() < 0.3:
				_popup(c["pos"] + Vector2(0, -0.4), "BLOCKED", Color(0.8, 0.8, 0.85), 11)
	if c.get("breach_until", 0.0) > sim_time:
		amount *= 1.25
	if type_branch.get("light", 0) == 2 and mastered("light") and c.get("veil", false) and int(c.get("cracks", 0)) > 0:
		amount *= 1.25
	var faked := false
	if type_branch.get("slow", 0) == 2 and mastered("slow") and c.get("slow_until", 0.0) > sim_time and c.get("frozen_until", 0.0) <= sim_time:
		c["frozen_until"] = sim_time + 0.0001
		faked = true
	var dealt := super.damage(c, amount)
	if faked:
		c["frozen_until"] = 0.0
	return dealt



# --- Notes ------------------------------------------------------------------------------------

## Notes go to the creep nearest the camp, boss or not, so a leak can always be
## saved with a note (playtest 1, D-0070). Crescendo notes are the boss's: while a
## Crescendo runs, notes hit the boss.
func _lead_creep() -> Dictionary:
	if boss_alive() and crescendo > 0.0:
		return boss
	return super._lead_creep()


## Grace Notes (talent) and Off-beat (card) add 8th notes to calls; they aren't
## part of the call, so missing one never costs the finisher.
func _add_sequence(times: Array, target: Dictionary, stagger: bool) -> int:
	var id := super._add_sequence(times, target, stagger)
	if stagger or times.size() < 2:
		return id
	var half := clock.beat_length() * 0.5
	if gstats.get("grace_notes", false):
		add_note(times[1] + half, "kick")
		notes[notes.size() - 1]["grace"] = true
	if gstats.get("off_beat", false):
		for i in times.size() - 1:
			if gstats.get("grace_notes", false) and i == 1:
				continue
			add_note(times[i] + half, "bass" if i % 2 == 0 else "kick")
			notes[notes.size() - 1]["half"] = true
	return id


func add_note(time: float, type: String, tower = null) -> void:
	if time >= _mute.x and time < _mute.y:
		return  # Last Orders rang: this bar is muted.
	super.add_note(time, type, tower)


func _resonance(n: Dictionary, g: String, offset_ms: float) -> void:
	var perfect := g == "Perfect"
	var target := _lead_creep()
	var cell = n.get("tower")
	var type: String = structures[cell]["type"] if cell is Vector2i and structures.has(cell) else ""
	_note_scale = 1.0
	if n.get("grace", false):
		_note_scale = 1.3 if perfect else 0.7
	elif n.get("half", false):
		_note_scale = 0.5
	super._resonance(n, g, offset_ms)
	_note_scale = 1.0
	if perfect and gstats.get("perfect_accum", false):
		accum_crit += 0.001
		gstats["crit_chance"] = gstats.get("crit_chance", 0.0) + 0.001
	if gstats.get("slowing_song", false) and not target.is_empty() and target["hp"] > 0.0 and target.get("slow_until", 0.0) <= sim_time:
		if int(target.get("song_n", 0)) < 3 or target.get("song_until", 0.0) <= sim_time:
			if target.get("song_until", 0.0) <= sim_time:
				target["song_n"] = 0
				target["song_slow"] = 0.0
			target["song_n"] = int(target.get("song_n", 0)) + 1
			target["song_slow"] = float(target.get("song_slow", 0.0)) + (0.15 if perfect else 0.05)
		target["song_until"] = sim_time + clock.bar_length() * 2.0
	if perfect and gstats.get("right_instrument", false) and type != "" and not target.is_empty():
		_right_instrument(type, cell, target)
	_cres_note(n, true, perfect)


## The Right Instrument: a Perfect note's extra, by the tower it came from.
func _right_instrument(type: String, cell: Vector2i, target: Dictionary) -> void:
	var spec := tower_spec(cell)
	var dmg: float = spec.get("damage", 0.0) * damage_scale() * 4.0
	match type:
		"kick":
			for c in _nearest_to(target, 2, 3.0):
				damage(c, dmg)
			_popup(target["pos"], "PIERCE", UiTheme.GOLD, 12)
		"bass":
			for c in creeps:
				if c["hp"] > 0.0 and c["pos"].distance_to(target["pos"]) <= 3.5:
					damage(c, dmg * 0.5)
			_bursts.append({"pos": target["pos"], "color": spec["color"], "ttl": 0.5, "crit": true, "radius": 3.5})
		"slow":
			if target["hp"] > 0.0:
				target["frozen_until"] = maxf(target.get("frozen_until", 0.0), sim_time + 2.0)
		"poison":
			for c in creeps:
				if c.get("poison", 0.0) > 0.0:
					c["poison_until"] = float(c.get("poison_until", 0.0)) + 6.0
		"lightning":
			if target["hp"] > 0.0:
				_arc(target, dmg * 0.5, spec["color"])
				_arc(target, dmg * 0.5, spec["color"])
		"light":
			for other in structures:
				if other != cell and is_tower(structures[other]["type"]) and structures[other]["type"] != "light" and Vector2(other).distance_to(Vector2(cell)) <= light_radius():
					_fire_once(other)


func _on_miss(n: Dictionary) -> void:
	super._on_miss(n)
	_cres_note(n, false, false)


# --- Crescendos: Solo, Perfect Solo, Melodic Healing, Improved Restore ---------------------------

func _posture_break() -> void:
	var had := {}
	for n in notes:
		had[n] = true
	super._posture_break()
	_mark_crescendo(had)


func _mark_crescendo(had: Dictionary) -> void:
	var id := _cres_next
	_cres_next += 1
	var count := 0
	for n in notes:
		if not had.has(n) and n["state"] == "open":
			n["cres"] = id
			count += 1
	if count > 0:
		_cres[id] = {"n": count, "hit": 0, "perfect": 0, "missed": 0}


## Improved Restore: a Restore starts a Crescendo (with no boss, a short burst of
## notes on every beat and the +30% damage of a Crescendo).
func _restore() -> void:
	super._restore()
	if not gstats.get("improved_restore", false):
		return
	if boss_alive():
		_posture_break()
		return
	var had := {}
	for n in notes:
		had[n] = true
	crescendo = crescendo_seconds
	var beat := clock.beat_length()
	var first := (floorf(beat_time() / beat) + 2.0) * beat
	var i := 0
	while first + i * beat < beat_time() + crescendo_seconds - 0.2:
		add_note(first + i * beat, "kick" if i % 2 == 0 or not asks("e") else "bass")
		i += 1
	_mark_crescendo(had)
	_show_feedback("RESTORE   CRESCENDO", Color(1.0, 0.9, 0.3))


func _cres_note(n: Dictionary, hit: bool, perfect: bool) -> void:
	var id: int = n.get("cres", 0)
	if not _cres.has(id):
		return
	var c: Dictionary = _cres[id]
	if hit:
		c["hit"] += 1
		if perfect:
			c["perfect"] += 1
	else:
		c["missed"] += 1
	if c["hit"] + c["missed"] < c["n"]:
		return
	_cres.erase(id)
	if c["missed"] == 0 and gstats.get("solo", false):
		shields += 2
		restore_charges = mini(restore_cap(), restore_charges + 1)
		b2_stats["solos"] += 1
		_show_feedback("SOLO   +2 shields, +1 Restore", Color(0.6, 1.0, 0.7))
	if c["perfect"] == c["n"]:
		if gstats.get("perfect_solo", false):
			auto_parry_until = beat_time() + SOLO_SECONDS
			_show_feedback("PERFECT SOLO   you parry and counter by yourself for 8 s", UiTheme.GOLD)
		if gstats.get("melodic_healing", false) and health < START_HEALTH:
			health += 1
			_show_feedback("MELODIC HEALING   +1 health", Color(0.6, 1.0, 0.7))


# --- The counter (Improved Counter Attack) and Perfect Solo ----------------------------------

func _resolve_parry(cand: Dictionary, g: String, offset_ms: float) -> void:
	if cand["kind"] == "elite" and cand["ref"].get("kind", "") == "last_orders":
		b2_stats["bells_parried"] += 1
	if cand["kind"] == "dig":
		_parry_dig(cand["ref"], g == "Perfect", offset_ms)
		return
	var target: Dictionary = {}
	if cand["kind"] == "counter":
		target = cand["ref"]["ref"]
	var had_counter := not _counter_open.is_empty()
	super._resolve_parry(cand, g, offset_ms)
	if cand["kind"] != "counter" and not _counter_open.is_empty() and not had_counter:
		_time_counter(cand["time"])
	if cand["kind"] == "counter" and gstats.get("counter_all", false) and not target.is_empty() and target.has("pos"):
		var dmg: float = parry_damage() * (1.0 + gstats.get("counter_mult", 0.0)) * (2.0 if g == "Perfect" else 1.0)
		for c in creeps:
			if c != target and c["hp"] > 0.0 and not c.get("boss", false) and c["pos"].distance_to(target["pos"]) <= COUNTER_BURST:
				damage(c, dmg * 0.5)  # With M7's half burst: full damage to everything within 2 tiles.


## The counter is a rhythm hit (playtest 1, D-0070): after a landed parry a yellow
## ring closes on the next half beat, and Space as it lands is judged like a note.
## Improved Counter Attack widens the window.
func _time_counter(parry_time: float) -> void:
	var half := clock.beat_length() * 0.5
	var at := (floorf(parry_time / half + 0.25) + 1.0) * half
	if at - press_time() < 0.1:
		at += half
	_counter_open["at"] = at
	_counter_open["opened"] = press_time()
	_counter_open["until"] = at + counter_window_ms() / 1000.0


func counter_window_ms() -> float:
	return parry_good_ms() + gstats.get("counter_window_ms", 0.0) * 0.4


func _parry() -> void:
	if _counter_open.is_empty() or not _counter_open.has("at"):
		super._parry()
		return
	var k: Dictionary = _counter_open
	var off_ms: float = (press_time() - k["at"]) * 1000.0
	if off_ms < -counter_window_ms():
		_counter_open = {}
		_show_feedback("Counter early (%.0f ms)   wait for the yellow ring" % off_ms, Color(1, 1, 1, 0.55))
		return
	if off_ms > counter_window_ms():
		_counter_open = {}
		super._parry()
		return
	_fire_counter(absf(off_ms) <= note_perfect_ms(), off_ms)


func _fire_counter(perfect: bool, off_ms := 0.0) -> void:
	var k: Dictionary = _counter_open
	_counter_open = {}
	if not creeps.has(k["ref"]) or k["ref"]["hp"] <= 0.0:
		return
	on_streak_hit()
	_sfx["parry_perfect" if perfect else "parry"].play()
	var c := {"at": press_time(), "from": k["opened"], "ref": k["ref"], "state": "flying"}
	_resolve_parry({"time": press_time(), "kind": "counter", "ref": c}, "Perfect" if perfect else "Good", off_ms)


## A Digger's shovel swing at the wall, parried: the wall holds and the Digger is
## knocked back a beat, open for a counter (D-0070).
func _parry_dig(c: Dictionary, perfect: bool, offset_ms: float) -> void:
	c["dig_until"] = -1.0
	c["dig_held"] = int(c.get("dig_held", 0)) + 1
	c["dug"] = int(c.get("dug", 0)) + 1
	m4_stats["parried"] += 1
	b2_stats["digs_parried"] = int(b2_stats.get("digs_parried", 0)) + 1
	var dmg := parry_damage() * (2.0 if perfect else 1.0)
	damage(c, dmg)
	c["frozen_until"] = maxf(c.get("frozen_until", 0.0), sim_time + clock.beat_length() * STAGGER_BEATS)
	shots.append({"from": Vector2(c["dig_cell"]), "to": c["pos"], "color": Color(1.0, 0.9, 0.3), "ttl": 0.35, "splash": 0.0, "width": 3.0})
	_show_feedback("%sPARRY  %+.0f ms   the wall holds" % ["PERFECT " if perfect else "", offset_ms], Color(1.0, 0.9, 0.3) if perfect else Color.WHITE)
	if gstats.get("counter", false) and c["hp"] > 0.0:
		_counter_open = {"ref": c, "until": 0.0, "opened": press_time(), "perfect": perfect}
		m7_stats["counters"] += 1
		_time_counter(beat_time())


func _parry_candidates() -> Array[Dictionary]:
	var out := super._parry_candidates()
	for c in creeps:
		if c.get("digger", false) and c["hp"] > 0.0 and c.get("dig_until", -1.0) > 0.0 and c["dig_until"] - beat_time() <= clock.bar_length():
			out.append({"time": c["dig_until"], "kind": "dig", "ref": c})
	return out


func _auto_parry() -> void:
	if beat_time() >= auto_parry_until or state != "playing":
		return
	for cand in _parry_candidates():
		if press_time() >= cand["time"] - 0.005 and press_time() <= cand["time"] + parry_good_ms() / 1000.0:
			on_streak_hit()
			_sfx["parry_perfect"].play()
			_resolve_parry(cand, "Perfect", 0.0)
			b2_stats["auto_parries"] += 1
			if not _counter_open.is_empty():
				_fire_counter(true)  # The counter, on the same breath.
			return


# --- New enemies ---------------------------------------------------------------------------------

func _spawn_creep(kind := "grunt") -> Dictionary:
	if not NEW_BASE.has(kind):
		return super._spawn_creep(kind)
	var nb: Dictionary = NEW_BASE[kind]
	var c := super._spawn_creep(nb["base"])
	c["kind"] = kind
	c["hp"] *= nb["hp"]
	c["max_hp"] = c["hp"]
	c["speed"] *= nb["speed"]
	if c.has("base_speed"):
		c["base_speed"] = c["speed"]
	match kind:
		"door":
			c["door"] = true
		"moth":
			c["moth"] = true
			c["target"] = GOAL
			c["pos"] += Vector2(0, rng.randf_range(-0.6, 0.6))
		"busker":
			c["drum"] = true
		"digger":
			c["digger"] = true
	return c


## Moths fly straight at the camp fire; diggers stand while they dig; buskers'
## drums push their neighbours on the beat; Thorny Walls and Slowing Song slow.
func _move_creeps(delta: float) -> void:
	var flyers: Array[Dictionary] = []
	var held: Array[Dictionary] = []
	var keep: Array[Dictionary] = []
	for c in creeps:
		if c.get("moth", false):
			flyers.append(c)
		elif c.get("dig_until", -1.0) > beat_time():
			held.append(c)
		else:
			keep.append(c)
	creeps = keep
	var scaled: Array = []  # [creep, speed before], restored after the move.
	var beat := clock.beat_length()
	var on_beat := fposmod(beat_time(), beat) < beat * 0.5
	var drums: Array = []
	for c in creeps:
		if c["hp"] > 0.0 and (c.get("drum", false) or c.get("foreman", false)):
			drums.append(c)
	var thorny: bool = gstats.get("thorny_walls", false)
	for c in creeps:
		if c.get("boss", false):
			continue
		var f := 1.0
		if on_beat and not drums.is_empty():
			for d in drums:
				if d != c and d["pos"].distance_to(c["pos"]) <= BUSKER_RADIUS:
					f *= 1.0 + BUSKER_BOOST
					break
		if c.get("song_until", 0.0) > sim_time and c.get("slow_until", 0.0) <= sim_time:
			f *= maxf(0.4, 1.0 - float(c.get("song_slow", 0.0)))
		if thorny:
			if _beside_wall(c["pos"]):
				c["thorn_t"] = float(c.get("thorn_t", 0.0)) + delta
				var t: float = c["thorn_t"]
				f *= 1.0 - minf(0.1 + 0.08 * t, 0.5)
				true_damage(c, minf(1.0 + 1.5 * t, 6.0) * damage_scale() * delta)
			else:
				c["thorn_t"] = maxf(0.0, float(c.get("thorn_t", 0.0)) - delta * 2.0)
		if f != 1.0:
			scaled.append([c, c["speed"]])
			c["speed"] *= f
	super._move_creeps(delta)
	for pair in scaled:
		pair[0]["speed"] = pair[1]
	for c in flyers:
		var to: Vector2 = Vector2(GOAL) - c["pos"]
		var step: float = c["speed"] * delta * (0.0 if c.get("frozen_until", 0.0) > sim_time else (0.5 if c.get("slow_until", 0.0) > sim_time else 1.0))
		if to.length() <= maxf(step, 0.3):
			moth_leaks += 1
			b2_stats["moths_in"] += 1
			if moth_leaks % MOTHS_PER_HEALTH == 0 and state == "playing":
				health -= 1
				_show_feedback("MOTHS AT THE FIRE   -1 health", Color(1, 0.4, 0.3))
				if health <= 0:
					health = 0
					state = "lost"
			continue
		c["pos"] += to.normalized() * step
		creeps.append(c)
	creeps.append_array(held)


func step(delta: float) -> void:
	super.step(delta)
	if state != "playing" or paused:
		return
	_auto_parry()
	_tick_digs()
	_tick_graves()
	var keep: Array[Dictionary] = []
	for a in _aftershocks:
		if beat_time() >= a["at"]:
			for c in creeps:
				if c["hp"] > 0.0 and c["pos"].distance_to(a["pos"]) <= a["radius"]:
					damage(c, a["amount"])
					c["frozen_until"] = maxf(c.get("frozen_until", 0.0), sim_time + clock.beat_length() * 0.5)
			_bursts.append({"pos": a["pos"], "color": Color(0.7, 0.55, 1.0), "ttl": 0.4, "crit": false, "radius": a["radius"]})
		else:
			keep.append(a)
	_aftershocks = keep
	_check_early_end()
	if not suppressed.is_empty() and restore_charges > 0 and not _told.has("restore"):
		_told["restore"] = true
		_watchman("Tower's jammed. Press F to Restore it.", 4.5)


## The night ends when the last enemy dies (playtest 1, D-0070): in the last
## section, once nothing is left to spawn and the board is clear, the morning comes
## two bars later. The song plays on under it.
const EARLY_END_BARS := 2.0
var _clear_at := -1.0


func _check_early_end() -> void:
	if ending or not started or section < night["sections"].size() - 1:
		return
	var s: Dictionary = night["sections"][section]
	var clear: bool = spawn_queue.is_empty() and _escort_queue.is_empty() and creeps.is_empty() and not boss_alive() \
		and _boss_due < 0.0 and graves.is_empty() and song_bar() >= s["start"] + 2.0
	if not clear:
		_clear_at = -1.0
		return
	if _clear_at < 0.0:
		_clear_at = song_bar() + EARLY_END_BARS
		if song_bar() < night["bars"] - EARLY_END_BARS:
			_watchman("That's the last of them.", 3.0)
	elif song_bar() >= _clear_at:
		_finish()


## Diggers: next to a wall, they stop and dig for four bars; then the wall is
## gone and the path reroutes. Kill them first.
func _tick_digs() -> void:
	for c in creeps:
		if not c.get("digger", false) or c["hp"] <= 0.0:
			continue
		if c.get("dig_until", -1.0) > 0.0:
			if press_time() > c["dig_until"] + parry_good_ms() / 1000.0:
				var cell: Vector2i = c["dig_cell"]
				c["dig_until"] = -1.0
				c["dug"] = int(c.get("dug", 0)) + 1
				if structures.has(cell) and structures[cell]["type"] == "wall":
					structures.erase(cell)
					grid.blocked.erase(cell)
					grid.rebuild()
					specs_changed()
					b2_stats["walls_dug"] += 1
					_shockwaves.append({"pos": Vector2(cell), "ttl": 0.5, "color": Color(0.9, 0.6, 0.3)})
					_show_feedback("A DIGGER BROKE A WALL   parry the swing to hold it", Color(1, 0.6, 0.35))
					_popup(Vector2(cell), "DUG", Color(1, 0.6, 0.35), 16)
			continue
		if int(c.get("dug", 0)) >= 2:
			continue
		var best := Vector2i(-1, -1)
		var best_d := DIG_REACH
		for cell in structures:
			if structures[cell]["type"] == "wall" and Vector2(cell).distance_to(c["pos"]) <= best_d:
				best = cell
				best_d = Vector2(cell).distance_to(c["pos"])
		if best.x >= 0:
			c["dig_cell"] = best
			c["dig_from"] = beat_time()
			c["dig_until"] = beat_time() + DIG_BARS * clock.bar_length()
			b2_stats["digs"] += 1
			_popup(Vector2(best), "DIGGING", Color(1, 0.6, 0.35), 13)
			if not _told.has("digger"):
				_told["digger"] = true
				_watchman("That one's digging at your wall. Parry the swing when the ring closes.", 5.0)


func _tick_graves() -> void:
	var keep: Array[Dictionary] = []
	for g in graves:
		if beat_time() < g["rise_at"]:
			keep.append(g)
			continue
		for i in g["count"]:
			var c := _spawn_creep("grunt")
			c["pos"] = Vector2(g["cell"]) + Vector2(rng.randf_range(-0.3, 0.3), rng.randf_range(-0.3, 0.3))
			c["target"] = g["cell"]
			c["frozen_until"] = sim_time + clock.beat_length()
			b2_stats["raised"] += 1
		_to_spawn = spawn_queue.size()
		_shockwaves.append({"pos": Vector2(g["cell"]), "ttl": 0.6, "color": Color(0.6, 0.9, 0.5)})
		_show_feedback("THE DEAD CLIMB OUT", Color(0.7, 1.0, 0.6))
	graves = keep


## Last Orders rings its bell and the Undertaker marks a grave: both wind up a
## bar like any throw and land on beat 1, so Space answers them.
func on_step(s: int) -> void:
	super.on_step(s)
	if state != "playing" or posmod(s, STEPS_PER_BAR) != 0:
		return
	var bar_time := floori(float(s) / STEPS_PER_BAR) * clock.bar_length()
	for c in creeps:
		var kind: String = c.get("kind", "")
		if not c.get("elite", false) or c["hp"] <= 0.0 or not kind in ["last_orders", "undertaker"]:
			continue
		if c["pulse_at"] >= 0.0 or beat_time() < c["cooldown_until"]:
			continue
		if kind == "undertaker":
			var cell := Vector2i(c["target"])
			for i in 4:
				if cell == GOAL:
					break
				cell = grid.next_step(cell)
			c["grave"] = cell
			b2_stats["graves"] += 1
		else:
			b2_stats["bells"] += 1
		c["pulse_from"] = bar_time
		c["pulse_at"] = bar_time + clock.bar_length()
		c["told"] = false
		c["ticked"] = -1
		c["pulse_targets"] = [] as Array[Vector2i]
		m4_stats["pulses"] += 1
	# Necrosis: poison grows each beat it stays.
	if type_branch.get("poison", 0) == 2 and mastered("poison"):
		for c in creeps:
			if c.get("poison", 0.0) > 0.0:
				c["poison"] = minf(c["poison"] * 1.1, float(c.get("poison_base", c["poison"])) * 3.0)
	# Wildfire: burning ground creeps a tile down the path each beat, three times.
	var spread: Array[Dictionary] = []
	for b in burning:
		if int(b.get("gen", 99)) < 3 and b["until"] > sim_time:
			var next := grid.next_step(b["cell"])
			b["gen"] = 99
			spread.append({"pos": Vector2(next), "until": sim_time + clock.bar_length(), "gen": int(b.get("spread_gen", 0)) + 1, "spread_gen": int(b.get("spread_gen", 0)) + 1, "cell": next})
	burning.append_array(spread)


func _pulse_lands(c: Dictionary) -> void:
	match c.get("kind", ""):
		"last_orders":
			_cancel_pulse(c)
			var bar := clock.bar_length()
			var from := (floorf(beat_time() / bar) + 1.0) * bar
			_mute = Vector2(from, from + bar)
			for n in notes.duplicate():
				if n["state"] == "open" and n["time"] >= _mute.x and n["time"] < _mute.y:
					notes.erase(n)
					stats[n["type"]]["notes"] -= 1
					_wave_notes -= 1
			_shockwaves.append({"pos": c["pos"], "ttl": 0.5, "color": Color(1.0, 0.75, 0.3)})
			_show_feedback("LAST ORDERS   the next bar is muted", Color(1, 0.7, 0.35))
		"undertaker":
			_cancel_pulse(c)
			var cell: Vector2i = c.get("grave", Vector2i(c["pos"].round()))
			graves.append({"cell": cell, "rise_at": beat_time() + GRAVE_RISE_BARS * clock.bar_length(), "count": GRAVE_COUNT})
			_shockwaves.append({"pos": Vector2(cell), "ttl": 0.6, "color": Color(0.6, 0.9, 0.5)})
			_show_feedback("A GRAVE   three Boneheads climb out in 2 bars", Color(0.7, 1.0, 0.6))
		_:
			super._pulse_lands(c)


## Splitting headache halves creeps; Shatter freezes around a frozen kill;
## Haunting's ghosts stay; the new enemies pay their own XP.
func _on_kill(c: Dictionary) -> void:
	super._on_kill(c)
	var kind: String = c.get("kind", "")
	if NEW_XP.has(kind):
		gain_xp(NEW_XP[kind] - 1.0)
	if gstats.get("ghost_forever", false) and not ghosts.is_empty():
		ghosts[-1]["ttl"] = INF
	if type_branch.get("slow", 0) == 1 and mastered("slow") and c.get("frozen_until", 0.0) > sim_time:
		for o in creeps:
			if o != c and o["hp"] > 0.0 and o["pos"].distance_to(c["pos"]) <= 1.0:
				o["frozen_until"] = maxf(o.get("frozen_until", 0.0), sim_time + clock.beat_length())
	if gstats.get("poison_jump", false) and float(c.get("poison", 0.0)) > 0.0:
		var next := _nearest_creep(c["pos"], c)
		if not next.is_empty():
			_poison(next, float(c["poison"]))
			shots.append({"from": c["pos"], "to": next["pos"], "color": Color(0.55, 0.9, 0.4), "ttl": 0.2, "splash": 0.0, "width": 2.0})
	if gstats.get("split_on_death", false) and not c.get("half", false) and not c.get("boss", false) and not c.get("elite", false) and not c.get("moth", false):
		for i in 2:
			var h := _spawn_creep(kind if kind != "" else "grunt")
			h["hp"] = c["max_hp"] * 0.5
			h["max_hp"] = h["hp"]
			h["half"] = true
			h["pos"] = c["pos"] + Vector2(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25))
			h["target"] = c["target"]


# --- Bosses: The Night Manager, The Foreman, The Landlord ---------------------------------------

## Night 5's rugpull (Jared, 2026-11-03): the Night Manager opens the night and the
## Landlord walks in when the overtime song starts. If the manager is still up, the
## Landlord waits for him to fall and comes in on the next bar.
func _boss_enters() -> void:
	if boss_alive():
		_boss_due = floorf(song_bar()) + 1.0
		return
	super._boss_enters()
	if boss_kind == "landlord":
		_watchman("Hang on. That's... the Landlord. It's not over.", 5.0)


func _summon_boss() -> void:
	var had := boss_alive()
	super._summon_boss()
	if not boss_alive() or had:
		return
	boss["second"] = false
	match boss_kind:
		"foreman":
			boss["foreman"] = true
			_show_feedback("THE FOREMAN   its drum speeds up everything near it", Color(1, 0.6, 0.35))
		"landlord":
			boss["landlord"] = true
			boss["hp"] *= LANDLORD_HP
			boss["max_hp"] = boss["hp"]
			_string_count = 0
			_show_feedback("THE LANDLORD   stomps your maze, volleys the camp", Color(0.8, 0.5, 1.0))
		_:
			_show_feedback("THE NIGHT MANAGER   parry its bolts as they land", Color(1, 0.4, 0.5))


func boss_name() -> String:
	if boss.get("landlord", false):
		return "The Landlord"
	if boss.get("foreman", false):
		return "The Foreman"
	return "The Night Manager"


## The Landlord alternates a Volley (4 bolts early in the night, 6 mid, 8 in the
## last stretch, one a beat) with a Stomp (two-bar wind-up, lands on beat 1; if it
## lands it locks towers near it and breaks the two walls nearest it).
func _call_string(bar: int) -> void:
	if not boss.get("landlord", false):
		super._call_string(bar)
		return
	var beat := clock.beat_length()
	var start := bar * clock.bar_length()
	_string_count += 1
	if _string_count % 2 == 1:
		var progress := clampf((song_bar() if started else 0.0) / maxf(float(night["bars"]), 1.0), 0.0, 1.0)
		var count := 4 if progress < 0.4 else (6 if progress < 0.75 else 8)
		_throw_bar = bar
		_hold_until = start + ceilf(count / 4.0) * clock.bar_length()
		var flight := clampi(ceili(boss_path_left() / BOLT_SPEED / beat - 0.001), BOSS_FLIGHT_MIN_BEATS, BOSS_FLIGHT_MAX_BEATS)
		var landings: Array[float] = []
		for i in count:
			var launch := start + i * beat
			bolts.append({"launch": launch, "arrive": launch + flight * beat, "from": boss["pos"], "state": "flying", "told": false})
			m5_stats["bolts"] += 1
			landings.append(launch + flight * beat)
		_clear_notes_near(landings)
		_next_string_bar = bar + ceili(count / 4.0) + BOSS_REST_BARS
	else:
		var at := start + 2.0 * clock.bar_length()
		_hold_until = at
		stomps.append({"from": start, "at": at, "pos": boss["pos"], "state": "flying", "told": false, "ticked": -1})
		m6_stats["stomps"] += 1
		var land: Array[float] = [at]
		_clear_notes_near(land)
		_next_string_bar = bar + 2 + BOSS_REST_BARS


func _stomp_lands(st: Dictionary) -> void:
	super._stomp_lands(st)
	var walls := []
	for cell in structures:
		if structures[cell]["type"] == "wall" and Vector2(cell).distance_to(st["pos"]) <= 2.5:
			walls.append(cell)
	walls.sort_custom(func(a, b): return Vector2(a).distance_to(st["pos"]) < Vector2(b).distance_to(st["pos"]))
	for cell in walls.slice(0, 2):
		structures.erase(cell)
		grid.blocked.erase(cell)
	if not walls.is_empty():
		grid.rebuild()
		specs_changed()
		_show_feedback("STOMP   %d wall%s cracked" % [mini(2, walls.size()), "" if walls.size() == 1 else "s"], Color(1, 0.5, 0.4))


## The Landlord is out all night: the calls keep coming around him (his own
## quiet chart is for field bosses). Lulls and quiet pushes still ask nothing.
func _schedule_bar(bar: int) -> void:
	if boss_alive() and boss.get("landlord", false) and crescendo <= 0.0 and started:
		var sb := (bar * clock.bar_length() - song_start) / clock.bar_length()
		for s in night["sections"]:
			if sb >= s["start"] and sb < s["start"] + s["bars"]:
				if s["kind"] == "lull" or s["quiet"]:
					return
				break
		_schedule_call(bar)
		return
	super._schedule_bar(bar)


## RunSim's call, one every four bars, without the boss check.
func _schedule_call(bar: int) -> void:
	if posmod(bar - _call_origin, CALL_BARS) != 0:
		return
	var bar_t := bar * STEPS_PER_BAR * step_length()
	if _stagger_until > bar_t - clock.bar_length():
		return
	var sizes: Array = CALL_SIZES[band(wave)]
	var size: int = sizes[rng.randi() % sizes.size()]
	size = mini(size + int(gstats.get("note_rate", 0)), CALL_MAX)
	_add_sequence(_beats_from(bar_t + clock.beat_length(), size), {}, false)


## The boss's nameplate and the marks the HUD and the indicators draw for B2:
## bells, graves and digs, each with its wind-up.
func b2_marks() -> Array:
	var out := []
	var beat := clock.beat_length()
	for c in creeps:
		if c["hp"] <= 0.0:
			continue
		var kind: String = c.get("kind", "")
		if kind in ["last_orders", "undertaker"] and c.get("pulse_at", -1.0) >= 0.0:
			var at: Vector2 = c["pos"] if kind == "last_orders" else Vector2(c.get("grave", Vector2i(c["pos"].round())))
			out.append({"pos": at, "label": "BELL" if kind == "last_orders" else "GRAVE", "frac": clampf((beat_time() - c["pulse_from"]) / maxf(c["pulse_at"] - c["pulse_from"], 0.01), 0.0, 1.0),
				"gone": clampi(floori((beat_time() - c["pulse_from"]) / beat), 0, 4), "color": Color(1.0, 0.7, 0.3) if kind == "last_orders" else Color(0.6, 0.95, 0.5)})
		if c.get("dig_until", -1.0) > 0.0 and press_time() <= c["dig_until"] + parry_good_ms() / 1000.0:
			var to_go: float = c["dig_until"] - beat_time()
			if to_go > clock.bar_length():
				var left := ceili(to_go / clock.bar_length())
				out.append({"pos": Vector2(c["dig_cell"]), "label": "DIG %d" % left, "frac": clampf((beat_time() - c["dig_from"]) / (DIG_BARS * clock.bar_length()), 0.0, 1.0), "gone": -1, "color": Color(1.0, 0.6, 0.35)})
			else:
				# The last bar: the shovel swing, parried like any attack (D-0070).
				out.append({"pos": Vector2(c["dig_cell"]), "label": "PARRY", "frac": clampf(1.0 - to_go / clock.bar_length(), 0.0, 1.0),
					"gone": clampi(floori((clock.bar_length() - to_go) / beat), 0, 4), "color": Color(1.0, 0.3, 0.4)})
	for g in graves:
		out.append({"pos": Vector2(g["cell"]), "label": "RISING", "frac": 1.0 - clampf((g["rise_at"] - beat_time()) / (GRAVE_RISE_BARS * clock.bar_length()), 0.0, 1.0), "gone": -1, "color": Color(0.6, 0.95, 0.5)})
	return out


# --- Test arena ---------------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and state != "playing" and Campaign.active:
		if event.keycode == KEY_R:
			if campaign_done():
				new_run()
			else:
				retry_night()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_N and state == "won" and not Campaign.is_last():
			next_night()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo and state == "playing" and not tree_open:
		if event.keycode == KEY_J:
			_arena = posmod(_arena + (-1 if event.shift_pressed else 1), ARENA_KINDS.size())
			_say("Test spawn: %s   (K drops it at the mine, Shift+J goes back)" % enemy_name(ARENA_KINDS[_arena]))
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_K:
			_arena_spawn(ARENA_KINDS[_arena])
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)


func _arena_spawn(kind: String) -> void:
	if not started:
		_say("Start the night first (N), then K drops test enemies")
		return
	if kind in BOSS_KINDS:
		if boss_alive():
			_say("A boss is already out")
			return
		boss_kind = kind
		_boss_enters()
		return
	wave = maxi(wave, 1)
	var count := 8 if kind == "moth" else 1
	for i in count:
		spawn_queue.append({"kind": kind, "gap": 0.15})
	_to_spawn = spawn_queue.size()
	if not wave_active:
		wave_active = true
	_say("Test spawn: %s" % enemy_name(kind))


# --- Run log -------------------------------------------------------------------------------

func run_lines() -> Array[String]:
	var lines := super.run_lines()
	var extra: Array[String] = []
	if Campaign.active:
		extra.append("Campaign: night %d of %d" % [Campaign.night_number(), Campaign.NIGHTS.size()])
		for h in Campaign.history:
			extra.append("   " + h)
	extra.append("Talents: %s   points left %d" % [", ".join(night_owned.map(func(id): return NightTree.name_of(id))) if not night_owned.is_empty() else "none", points])
	extra.append("Cards: %s" % (", ".join(card_picks.map(func(id): return card_name(id))) if not card_picks.is_empty() else "none"))
	var ups: Array[String] = []
	for type in ["kick", "bass", "slow", "poison", "lightning", "light"]:
		if type_rank.get(type, 0) > 0:
			ups.append("%s %s" % [tower_name(type), rank_label(type)])
	extra.append("Upgrades: %s" % (", ".join(ups) if not ups.is_empty() else "none"))
	var b := b2_stats
	extra.append("Enemies: door blocks %d, bells %d (parried %d), digs %d (walls lost %d), graves %d (raised %d), moths at the fire %d" % [b["blocked"], b["bells"], b["bells_parried"], b["digs"], b["walls_dug"], b["graves"], b["raised"], b["moths_in"]])
	if b["auto_parries"] > 0 or b["solos"] > 0:
		extra.append("Perfect Solo parries %d   Solos %d" % [b["auto_parries"], b["solos"]])
	var at := mini(5, lines.size())
	for i in extra.size():
		lines.insert(at + i, extra[i])
	return lines


# --- Moving through the campaign (the results screen and R / N) ------------------------------

func next_night() -> void:
	Campaign.advance(self)


func retry_night() -> void:
	Campaign.retry(self)


func new_run() -> void:
	Campaign.begin(0)
	get_tree().reload_current_scene()


## Night 5 held: the five-night run is complete.
func campaign_done() -> bool:
	return Campaign.active and Campaign.is_last() and state == "won"


## The start panel's line for each night: what's new tonight (B1+B2 drafts).
const NIGHT_BLURB := [
	"",
	"New tonight: E notes (purple) and Door-to-Door, who carries a door. Hits from ahead barely scratch him, so put towers beside and behind the path.",
	"New tonight: Buskers, whose drums speed up the creeps around them, and Last Orders: parry the bell or the next bar's notes go quiet. The Foreman comes in the last push.",
	"New tonight: Diggers tunnel through a wall in four bars (kill them first), Moths fly over the maze straight at the fire, and the Undertaker digs graves: parry them or three skeletons rise. The Night Manager is back.",
	"Everything together. The Landlord walks in at the top and fights all night: parry his Stomps (they break walls) and his Volleys at the camp. He won't fall before the last song.",
]


func night_blurb() -> String:
	return NIGHT_BLURB[Campaign.index] if Campaign.active and Campaign.index < NIGHT_BLURB.size() else ""
