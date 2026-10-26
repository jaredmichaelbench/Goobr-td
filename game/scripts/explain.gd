class_name Explain
## Tooltip text for Demo 1 (D-0046, Jared: "a modern tooltip shows writing in
## white, effects and known concepts in blue or upgrades in green"). Every tip
## has the same shape: a title, a plain sentence in white, the numbers in green,
## game words in blue with a one-line glossary under a rule, and any requirement
## last. Output is BBCode for a RichTextLabel.

const WHITE := "#ecebe6"
const GREEN := "#86e39a"
const BLUE := "#8cc8ff"
const GREY := "#9aa0a8"
const RED := "#ff8a7a"
const GOLD := "#ffd95a"

## Game words and what they mean, one line each.
const GLOSSARY := {
	"note": "A ring over a tower. Press its key (Q or E) as the ring closes.",
	"snipe": "A landed note fires its tower across the whole board at the creep nearest the Conductor.",
	"call": "The short sequence of notes every four bars. Land all of it for a finisher.",
	"finisher": "Every note of a call landed: the Conductor fires one big shot.",
	"Perfect": "A note within 35 ms of the beat. It hits twice as hard as a Good.",
	"parry": "Space as an enemy attack lands. It sends damage back and staggers elites.",
	"counter": "Tap Space again right after a landed parry for a second hit.",
	"stagger": "A parried elite holds still and plays a short sequence of its own.",
	"crit": "A critical hit: x1.5 damage, more with crit damage.",
	"focus fire": "A snipe deals +25% for every other tower whose range covers its target.",
	"Restore": "Unlocks a tower an elite has locked (F).",
	"shield": "Blocks one hit on the Conductor.",
	"luck": "Raises the odds of rarer cards in a draft.",
	"Crescendo": "After a boss's posture breaks: every tower +30% and a burst of notes.",
	"veil": "Shades take 10% damage until landed notes crack their veil.",
}

## Talent and card effects: [kind, label, plain sentence, glossary words].
## {v} in the label is the value for the ranks in question.
const EFFECTS := {
	"note_rate": ["int", "{v} note in every call", "Each call gets an extra note on a free off-beat.", ["call"]],
	"perfect_mult": ["pct", "{v} damage on Perfect notes", "Notes you land Perfect hit harder still.", ["Perfect"]],
	"damage_mult": ["pct", "{v} damage, every tower", "Every tower's shots and snipes deal more.", ["snipe"]],
	"echo": ["pct", "{v} of the snipe again", "After a landed note, its target is hit a second time for a share of the snipe.", ["snipe"]],
	"crossfire": ["pct", "{v} focus fire per tower", "Snipes deal more for each other tower covering the target (base +25% each).", ["focus fire", "snipe"]],
	"parry_notes": ["flag", "a landed parry adds a note", "Each landed parry puts a free note on the next beat.", ["parry", "note"]],
	"note_window_ms": ["ms", "{v} note timing window", "A note still counts as Good this much further from the beat.", ["note"]],
	"range_all": ["tiles", "{v} range, every tower", "Every tower reaches further.", []],
	"crit_chance": ["pct", "{v} crit chance", "Each hit has this chance to crit.", ["crit"]],
	"crit_mult": ["pct", "{v} crit damage", "Crits hit harder.", ["crit"]],
	"upgrade_discount": ["off", "type upgrades {v} cheaper", "Upgrading a tower type costs less gold.", []],
	"gold_mult": ["pct", "{v} gold", "All gold you earn.", []],
	"xp_mult": ["pct", "{v} XP", "Level up, and earn talent points, sooner.", []],
	"luck": ["int", "{v} luck", "Rarer cards turn up in drafts.", ["luck"]],
	"kill_gold": ["int", "{v} gold per kill", "Every kill pays extra.", []],
	"interest": ["pct", "{v} interest", "Each wave you clear pays this share of your unspent gold.", []],
	"wave_bonus_mult": ["pct", "{v} wave bonus", "The gold for clearing a wave.", []],
	"wall_cap": ["int", "{v} walls", "You can build more walls.", []],
	"wall_cheap": ["gold", "walls {v} cheaper", "Each wall costs less.", []],
	"wall_slow": ["pct", "walls slow creeps {v}", "Creeps next to a wall move slower.", []],
	"wall_thorns": ["int", "walls deal {v} a second", "Creeps next to a wall take damage every second, through armour.", []],
	"shield_cap": ["int", "{v} shield", "One more hit on the Conductor blocked each wave.", ["shield"]],
	"parry_mult": ["pct", "{v} parry damage", "Parries send back more damage.", ["parry"]],
	"parry_window_ms": ["ms", "{v} parry timing window", "A parry still lands this much further from the hit.", ["parry"]],
	"restore_charges": ["int", "{v} Restore charge", "More towers you can unlock after an elite locks them.", ["Restore"]],
	"parry_splash": ["tiles", "parries hit everything within {v} tiles", "Creeps near the parried enemy take half the return.", ["parry"]],
	"counter_window_ms": ["ms", "{v} counter tap window", "More time for the counter tap after a parry.", ["counter"]],
	"counter_mult": ["pct", "{v} counter damage", "Counters hit harder.", ["counter"]],
	"fermata": ["flag", "a Perfect parry freezes every creep for a beat", "", ["parry", "Perfect"]],
	"arsenal": ["flag", "every tower type unlocks now", "", []],
	"bounty": ["flag", "bosses pay triple gold and XP", "", []],
	"rampart": ["flag", "wall slow and wall damage x2", "", []],
	"riposte": ["flag", "counters hit twice and build double posture", "", ["counter"]],
	"counter": ["flag", "the counter-attack", "", ["counter"]],
}


static func c(color: String, text: String) -> String:
	return "[color=%s]%s[/color]" % [color, text]


static func title(text: String, color := GOLD, sub := "") -> String:
	var out := "[font_size=17][b]%s[/b][/font_size]" % c(color, text)
	if sub != "":
		out += "   " + c(GREY, sub)
	return out


static func value(kind: String, v) -> String:
	match kind:
		"pct": return "+%d%%" % roundi(float(v) * 100.0)
		"off": return "%d%%" % roundi(float(v) * 100.0)
		"ms": return "+%d ms" % roundi(float(v))
		"tiles": return "+%.2f" % float(v) if fmod(float(v) * 10.0, 1.0) != 0.0 else "+%.1f" % float(v)
		"gold": return "%dg" % int(v)
		"int": return "+%d" % int(v)
	return ""


## One effect line with its value for `ranks` ranks, the value in green.
static func effect_line(key: String, v, ranks := 1) -> String:
	if not EFFECTS.has(key):
		return c(WHITE, key)
	var e: Array = EFFECTS[key]
	if e[0] == "flag":
		return c(GREEN, e[1])
	var total = v * ranks if (v is float or v is int) else v
	return c(WHITE, String(e[1]).replace("{v}", c(GREEN, value(e[0], total))))


## The glossary block for some words: blue word, grey meaning.
static func glossary(words: Array) -> String:
	var seen := {}
	var lines: Array[String] = []
	for w in words:
		if seen.has(w) or not GLOSSARY.has(w):
			continue
		seen[w] = true
		lines.append("%s  %s" % [c(BLUE, w[0].to_upper() + w.substr(1)), c(GREY, GLOSSARY[w])])
	if lines.is_empty():
		return ""
	return "\n[font_size=12]" + "\n".join(lines) + "[/font_size]"


## A talent node: what it does, now and with the next rank, and what it needs.
static func talent(node: Dictionary, ranks: int, available: bool, points: int) -> String:
	var area_col: Color = TalentTree.AREA_COLORS[node["areas"][0]]
	var where := " or ".join(node["areas"].map(func(a): return TalentTree.AREA_NAMES[a]))
	var sub := ("rank %d/%d" % [ranks, node["max"]]) if node["max"] > 1 else ("taken" if ranks > 0 else "")
	if node.get("shared", false):
		sub += ("   " if sub != "" else "") + "shared: " + where
	elif node.get("capstone", false):
		sub += ("   " if sub != "" else "") + where + " capstone"
	var out: Array[String] = [title(node["name"], "#" + area_col.to_html(false), sub)]
	var words: Array = []
	var sentence := ""
	for k in node["effects"]:
		if EFFECTS.has(k):
			if EFFECTS[k][2] != "" and sentence == "":
				sentence = EFFECTS[k][2]
			words.append_array(EFFECTS[k][3])
	if node.get("capstone", false):
		sentence = node["text"] + "."
	if sentence != "":
		out.append(c(WHITE, sentence))
	var effects: Dictionary = node["effects"]
	if node["max"] > 1:
		if ranks > 0:
			out.append(c(GREY, "Now: ") + _effects(effects, ranks))
		if ranks < node["max"]:
			var nxt := c(GREY, "Next rank: ") + _effects(effects, 1)
			if ranks > 0:
				nxt += c(GREY, "   for a total of ") + _effects(effects, ranks + 1, true)
			out.append(nxt)
	else:
		out.append(_effects(effects, 1))
	var gate: int = TalentTree.GATES[node["row"] - 1]
	if ranks < node["max"]:
		if not available and gate > 0:
			out.append(c(RED, "Needs %d points in %s" % [gate, where]))
		elif points <= 0:
			out.append(c(GREY, "No talent point to spend. Level up to earn one."))
		else:
			out.append(c(GREEN, "Click to take it."))
	return "\n".join(out) + glossary(words)


static func _effects(effects: Dictionary, ranks: int, plain := false) -> String:
	var parts: Array[String] = []
	for k in effects:
		if k in ["counter"] and effects.size() > 1:
			continue
		if plain and EFFECTS.has(k) and EFFECTS[k][0] != "flag":
			parts.append(c(GREEN, value(EFFECTS[k][0], effects[k] * ranks)))
		else:
			parts.append(effect_line(k, effects[k], ranks))
	return ", ".join(parts)


## What each tower does on its own and with its note.
const TOWERS := {
	"wall": ["Blocks the path. Creeps reroute around walls as you build them, so walls make your maze.", ""],
	"kick": ["Heavy single shots on beats 1 and 3.", "Its note fires a snipe: x4 its damage (x8 Perfect)."],
	"bass": ["Splash shots on every off-beat, hitting creeps near the target.", "Its note fires a wave: x2 (x4 Perfect) to everything within 2 tiles of the target."],
	"slow": ["Shoots on every beat and slows what it hits for 1.5 s.", "Its note freezes everything within 2 tiles of the target for a beat (two on Perfect), x2 damage (x4 Perfect)."],
	"poison": ["Poisons on every beat. Poison ticks every beat and goes through armour.", "Its note spreads the target's poison to every creep within 2 tiles."],
	"lightning": ["Shots on beats 1 and 3 that arc to two more creeps nearby.", "Its note is a storm: every creep on the board takes a hit at once."],
	"light": ["Deals no damage. Every tower in its light deals more damage, and on beat 1 it cracks Shade veils in reach.", "Its note is a chorus: every tower in its light fires at once (twice on Perfect)."],
}


## A tower type for the build card and the tower panel. `game` is the run.
static func tower(game, type: String, key_hint := "") -> String:
	var out: Array[String] = []
	var cost: int = game.builds[type]["cost"]
	out.append(title(game.tower_name(type), GOLD, "%dg" % cost))
	out.append(c(WHITE, TOWERS[type][0]))
	if type == "wall":
		out.append(c(WHITE, "Walls ") + c(GREEN, "%d / %d" % [game.wall_count(), game.wall_limit]))
	elif type == "light":
		out.append(c(WHITE, "Boost ") + c(GREEN, "+%d%% damage" % roundi(game.light_boost() * 100.0)) + c(WHITE, " to towers within ") + c(GREEN, "%.1f tiles" % game.light_radius()))
	else:
		var spec: Dictionary = game.type_spec(type)
		var line := c(WHITE, "Damage ") + c(GREEN, "%.0f" % (spec["damage"] * game.damage_scale())) + c(WHITE, "   Range ") + c(GREEN, "%.1f" % spec["range"])
		if spec.get("splash", 0.0) > 0.0:
			line += c(WHITE, "   Splash ") + c(GREEN, "%.1f" % spec["splash"])
		out.append(line)
	var words: Array = []
	if TOWERS[type][1] != "":
		var note: String = TOWERS[type][1]
		for w in ["snipe", "Perfect"]:
			if note.contains(w):
				note = note.replace(w, c(BLUE, w))
				words.append(w)
		out.append(c(WHITE, note.replace("Its note", c(BLUE, "Its note"))))
		words.push_front("note")
	if game.is_tower(type):
		var rank: int = game.type_rank.get(type, 0)
		if rank < 5:
			out.append(c(GREY, "Next upgrade (rung %d): " % (rank + 1)) + c(GREEN, game.rung_text(type, rank + 1)) + c(GREY, "   %dg, every %s" % [game.type_upgrade_cost(type), game.tower_name(type)]))
	if not game.unlocked.has(type):
		out.append(c(RED, "Locked. To unlock: " + game.unlock_text(type)))
	if key_hint != "":
		out.append(c(GREY, key_hint))
	return "\n".join(out) + glossary(words)


## The three game controls in the middle of the bottom panel.
static func control(game, which: String) -> String:
	match which:
		"talents":
			var pts: int = game.points
			return "\n".join([title("Talents", "#86e39a", "Tab"),
				c(WHITE, "Spend talent points. You earn one every level; the run keeps playing while the tree is open."),
				c(GREEN, "%d point%s to spend" % [pts, "" if pts == 1 else "s"]) if pts > 0 else c(GREY, "No points right now.")])
		"restore":
			return "\n".join([title("Restore", GOLD, "F"),
				c(WHITE, "Unlocks every tower an elite has locked."),
				c(WHITE, "Charges ") + c(GREEN, "%d / %d" % [game.restore_charges, game.restore_cap()]) + c(GREY, "   +1 each wave"),
				c(GREY, "Nothing is locked right now.") if game.suppressed.is_empty() else c(GREEN, "%d tower%s locked" % [game.suppressed.size(), "" if game.suppressed.size() == 1 else "s"])])
		"start":
			return "\n".join([title("Start wave", GOLD, "N"),
				c(WHITE, "Sends the next wave. Build and spend first; nothing comes until you start it."),
				c(GREY, "Wave %d is running." % game.wave) if game.wave_active else c(WHITE, "Next: ") + c(GREEN, "wave %d" % (game.wave + 1))])
	return ""
