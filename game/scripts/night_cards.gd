class_name NightCards
## The campaign's cards (locked in D-0059, built in B1). Four picks a run, a
## pick of three after Nights 1 to 4. No flat stat cards: every one changes how
## you play. Rarity is Rare (about 65%), Epic (28%) or Legendary (7%, at most one
## a run); luck nudges the odds up. Talents are the plan, cards are the twist.
##
## Edit freely, no code. "effects" are added to the game's stats once, when the
## card is taken and again at the start of every later night (they last the
## run). "once" effects happen only when the card is taken (Blood money's health).
## A card marked "later" is designed but not in the pool yet.
##
## The HUD shows rarity by colour and gems, never by word; rare, epic and
## legendary borrow the old blue, purple and orange slots of the colour table.

const RARITIES: Array[String] = ["rare", "epic", "legendary"]
const RARITY_WEIGHT := {"rare": 65.0, "epic": 28.0, "legendary": 7.0}
const RARITY_SLOT := {"rare": "blue", "epic": "purple", "legendary": "orange"}  # HudKit colour and gem keys.
const CATEGORY_NAMES := {"enemy": "Enemy", "rhythm": "Rhythm", "camp": "Camp", "special": "Special"}
const CATEGORY_GLYPH := {"enemy": "enemy", "rhythm": "abilities", "camp": "economy", "special": "star"}

const CARDS: Array[Dictionary] = [
	{"id": "splitting_headache", "name": "Splitting headache", "rarity": "epic", "cat": "enemy",
		"text": "Every creep splits in two halves when it dies, but Arrows hit two targets, Cannon blasts reach further and Lightning bounces once more.",
		"effects": {"split_on_death": true, "arrow_two": true, "splash_bonus": 0.5, "arc_jumps": 1}},
	{"id": "f_beat", "name": "F beat", "rarity": "legendary", "cat": "rhythm", "later": true,
		"text": "A third note on the F key joins the song for the rest of the run.", "effects": {}},
	{"id": "perfect_accumulation", "name": "Perfect Accumulation", "rarity": "rare", "cat": "rhythm",
		"text": "Every Perfect note gives towers +0.1% crit chance for the rest of the run.", "effects": {"perfect_accum": true}},
	{"id": "sharpshooter", "name": "Sharpshooter", "rarity": "rare", "cat": "rhythm",
		"text": "Perfect snipes do x12 instead of x8.", "effects": {"snipe_perfect": 12.0}},
	{"id": "rally", "name": "Rally", "rarity": "rare", "cat": "rhythm",
		"text": "A parried attack is fired back by every tower near the attacker.", "effects": {"mod_rally": true}},
	{"id": "echo", "name": "Echo", "rarity": "epic", "cat": "rhythm",
		"text": "A Perfect note repeats on the next beat for half.", "effects": {"perfect_echo": true}},
	{"id": "off_beat", "name": "Off-beat", "rarity": "epic", "cat": "rhythm",
		"text": "In pushes and finales, notes also come on the off-beats, each worth half.", "effects": {"off_beat": true}},
	{"id": "heavy_boots", "name": "Heavy boots", "rarity": "rare", "cat": "enemy",
		"text": "Creeps 10% slower, 20% more of them.", "effects": {"enemy_speed_mult": -0.1, "enemy_count_mult": 0.2}},
	{"id": "light_boots", "name": "Light boots", "rarity": "rare", "cat": "enemy",
		"text": "Creeps 15% faster, 25% fewer of them.", "effects": {"enemy_speed_mult": 0.15, "enemy_count_mult": -0.25}},
	{"id": "wanted_posters", "name": "Wanted posters", "rarity": "rare", "cat": "enemy",
		"text": "One extra elite every push; elites pay triple gold and XP.", "effects": {"extra_elite": 1, "elite_reward_mult": 2.0}},
	{"id": "dread", "name": "Dread", "rarity": "epic", "cat": "enemy",
		"text": "Every Big Lad is also a Hush; Hushes pay double.", "effects": {"brute_shade": true, "shade_reward_mult": 1.0}},
	{"id": "blood_money", "name": "Blood money", "rarity": "rare", "cat": "camp",
		"text": "Lose 3 health now; start every night with 100 more gold.", "effects": {"night_gold": 100}, "once": {"health": -3}},
	{"id": "difficulty_tome", "name": "Difficulty tome", "rarity": "epic", "cat": "camp",
		"text": "Creeps have 25% more health; you get 60% more gold and XP.", "effects": {"enemy_hp_mult": 0.25, "gold_mult": 0.6, "xp_mult": 0.6}},
	{"id": "glass_cannon", "name": "Glass cannon", "rarity": "epic", "cat": "camp",
		"text": "Towers do double damage; every creep that gets through costs double health.", "effects": {"damage_mult": 1.0, "leak_double": true}},
	{"id": "fermata", "name": "Fermata", "rarity": "legendary", "cat": "rhythm",
		"text": "A Perfect parry freezes every creep for a beat.", "effects": {"fermata": true}},
	{"id": "haunting", "name": "Haunting", "rarity": "legendary", "cat": "special",
		"text": "Every kill spawns a ghost that haunts the nearest creep for 2 damage a beat until it dies.", "effects": {"ghost": true, "ghost_forever": true}},
	{"id": "jambaya", "name": "Jambaya", "rarity": "legendary", "cat": "special",
		"text": "The first hit on every creep is a crit.", "effects": {"first_crit": true}},
]


static func by_id(id: String) -> Dictionary:
	for c in CARDS:
		if c["id"] == id:
			return c
	return {}


## Three different cards: rarity by weight (luck lifts Epic and Legendary), then
## a random card of that rarity not yet taken, falling back a rarity when one is
## empty. No legendary once one is taken.
static func roll_hand(rng: RandomNumberGenerator, size: int, luck: float, taken: Dictionary, legendary_ok: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var exclude := taken.duplicate()
	for i in size:
		var weights := RARITY_WEIGHT.duplicate()
		weights["epic"] += luck * 0.6
		weights["legendary"] = (weights["legendary"] + luck * 0.4) if legendary_ok else 0.0
		var rarity := _weighted(rng, weights)
		var ri := RARITIES.find(rarity)
		var pick := {}
		while ri >= 0 and pick.is_empty():
			var pool: Array[Dictionary] = []
			for c in CARDS:
				if c["rarity"] == RARITIES[ri] and not exclude.has(c["id"]) and not c.get("later", false):
					pool.append(c)
			if not pool.is_empty():
				pick = pool[rng.randi() % pool.size()]
			ri -= 1
		if pick.is_empty():
			break
		exclude[pick["id"]] = true
		out.append(pick)
	return out


static func _weighted(rng: RandomNumberGenerator, weights: Dictionary) -> String:
	var total := 0.0
	for k in weights:
		total += maxf(0.0, weights[k])
	var x := rng.randf() * total
	for k in weights:
		x -= maxf(0.0, weights[k])
		if x <= 0.0:
			return k
	return weights.keys()[weights.size() - 1]
