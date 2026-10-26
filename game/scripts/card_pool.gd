class_name CardPool
## The M7 draft pool (D-0039). A card is rolled twice: once for rarity, once
## for category. Rarity says how far the card bends the run, category what it
## touches. Luck adds to every rarity weight above grey. Edit freely, no code:
## effects are stat bumps on the game's gstats, run flags (mods), or
## immediate actions (gold, xp, unlock).
##
## Rarities: grey, green, blue, purple, orange (orange once per run, not
## before wave 3). Categories: stats, economy, enemy, tower, abilities,
## special, draft.

const RARITIES: Array[String] = ["grey", "green", "blue", "purple", "orange"]
const RARITY_WEIGHT := {"grey": 50.0, "green": 28.0, "blue": 14.0, "purple": 6.0, "orange": 2.0}
const RARITY_COLORS := {"grey": Color(0.8, 0.8, 0.85), "green": Color(0.55, 0.9, 0.55), "blue": Color(0.55, 0.7, 1.0), "purple": Color(0.8, 0.55, 1.0), "orange": Color(1.0, 0.65, 0.3)}
const CATEGORIES: Array[String] = ["stats", "economy", "enemy", "tower", "abilities", "special", "draft"]
const CATEGORY_NAMES := {"stats": "Stats", "economy": "Economy", "enemy": "Enemy altering", "tower": "Tower altering", "abilities": "Abilities", "special": "Special", "draft": "Draft"}
const LOCK_CHANCE := 0.35  # Blue and above may come locked with a condition for the next wave.
const CONDITIONS := {
	"perfects": "land 6 Perfects next wave",
	"clean": "let no pulse, arrow, bolt or stomp land next wave",
	"shields": "lose no shield next wave",
}

const CARDS: Array[Dictionary] = [
	# Stats
	{"id": "dmg1", "name": "Whetstone", "text": "+15% tower damage", "rarity": "grey", "cat": "stats", "effects": {"damage_mult": 0.15}},
	{"id": "crit1", "name": "Keen edge", "text": "+10% crit chance", "rarity": "grey", "cat": "stats", "effects": {"crit_chance": 0.1}},
	{"id": "luck1", "name": "Rabbit's foot", "text": "+1 luck (rarer cards)", "rarity": "grey", "cat": "stats", "effects": {"luck": 1}},
	{"id": "dmg2", "name": "Grindstone", "text": "+25% tower damage", "rarity": "green", "cat": "stats", "effects": {"damage_mult": 0.25}},
	{"id": "critdmg", "name": "Executioner's oil", "text": "+80% crit damage", "rarity": "green", "cat": "stats", "effects": {"crit_mult": 0.8}},
	{"id": "range1", "name": "Spyglass", "text": "+0.7 range on every tower", "rarity": "green", "cat": "stats", "effects": {"range_all": 0.7}},
	{"id": "critslow", "name": "Chilling crits", "text": "Crits also slow the creep for a beat", "rarity": "blue", "cat": "stats", "effects": {"crit_slow": true}},
	{"id": "glass", "name": "Glass cannon", "text": "+100% tower damage; every leaked creep costs double", "rarity": "purple", "cat": "stats", "effects": {"damage_mult": 1.0, "leak_double": true}},
	# Economy
	{"id": "gold1", "name": "Coin purse", "text": "+90 gold now", "rarity": "grey", "cat": "economy", "effects": {"gold": 90}},
	{"id": "killgold", "name": "Bounty", "text": "+1 gold per kill", "rarity": "grey", "cat": "economy", "effects": {"kill_gold": 1}},
	{"id": "xp1", "name": "Bonk cup", "text": "+35% XP", "rarity": "green", "cat": "economy", "effects": {"xp_mult": 0.35}},
	{"id": "goldmult", "name": "Tithe", "text": "+20% gold from everything", "rarity": "green", "cat": "economy", "effects": {"gold_mult": 0.2}},
	{"id": "interest", "name": "Vault", "text": "3% interest on unspent gold at each wave end", "rarity": "blue", "cat": "economy", "effects": {"interest": 0.03}},
	{"id": "elitegold", "name": "Elite contracts", "text": "Elites drop a free Restore charge instead of gold", "rarity": "blue", "cat": "economy", "effects": {"elite_charge": true}},
	{"id": "tome", "name": "Difficulty tome", "text": "Creeps +25% health; +60% gold and XP", "rarity": "purple", "cat": "economy", "effects": {"enemy_hp_mult": 0.25, "gold_mult": 0.6, "xp_mult": 0.6}},
	# Enemy altering
	{"id": "slowmore", "name": "Heavy boots", "text": "Creeps 10% slower, 20% more of them", "rarity": "green", "cat": "enemy", "effects": {"enemy_speed_mult": -0.1, "enemy_count_mult": 0.2}},
	{"id": "fastless", "name": "Light boots", "text": "Creeps 15% faster, 25% fewer of them", "rarity": "green", "cat": "enemy", "effects": {"enemy_speed_mult": 0.15, "enemy_count_mult": -0.25}},
	{"id": "lazyelite", "name": "Slack bowstrings", "text": "Elites wind up 50% slower between throws", "rarity": "blue", "cat": "enemy", "effects": {"enemy_attack_mult": 0.5}},
	{"id": "moreelite", "name": "Wanted posters", "text": "One extra Jammer every wave; elites pay x3 gold and XP", "rarity": "blue", "cat": "enemy", "effects": {"extra_jammer": 1, "elite_reward_mult": 2.0}},
	{"id": "bruteshade", "name": "Dread", "text": "Every Brute is also a Shade; Shades pay double", "rarity": "purple", "cat": "enemy", "effects": {"brute_shade": true, "shade_reward_mult": 1.0}},
	# Tower altering
	{"id": "chain", "name": "Chain snipe", "text": "Cannon snipes jump to a second creep within 3 tiles for half", "rarity": "blue", "cat": "tower", "effects": {"mod_chain": true}},
	{"id": "slow_wave", "name": "Undertow", "text": "Splash waves slow everything they hit for 1 s", "rarity": "green", "cat": "tower", "effects": {"mod_slow_wave": true}},
	{"id": "shatter", "name": "Shatter", "text": "A freeze on an already frozen creep does x3", "rarity": "blue", "cat": "tower", "effects": {"mod_shatter": true}},
	{"id": "pierce", "name": "Piercing shot", "text": "Cannon snipes also hit the two creeps nearest the target", "rarity": "purple", "cat": "tower", "effects": {"snipe_pierce": true}},
	{"id": "lightjump", "name": "Static", "text": "Lightning arcs reach 4 tiles instead of 2", "rarity": "blue", "cat": "tower", "effects": {"arc_range": 2.0}},
	{"id": "venom", "name": "Venom", "text": "Poison ticks do double", "rarity": "green", "cat": "tower", "effects": {"poison_mult": 1.0}},
	{"id": "unlock", "name": "Blueprint", "text": "Unlock one locked tower type now (the first still locked)", "rarity": "blue", "cat": "tower", "effects": {"unlock_one": true}},
	# Abilities
	{"id": "rally", "name": "Rally", "text": "A parried pulse is returned by every tower near the elite", "rarity": "blue", "cat": "abilities", "effects": {"mod_rally": true}},
	{"id": "charge", "name": "Spare battery", "text": "+1 Restore charge now and to the cap", "rarity": "grey", "cat": "abilities", "effects": {"restore_charges": 1}},
	{"id": "shield", "name": "Extra shield", "text": "+1 Conductor shield every wave", "rarity": "grey", "cat": "abilities", "effects": {"shield_cap": 1}},
	{"id": "parry4", "name": "Wide guard", "text": "Parries also hit creeps within 2 tiles of the target", "rarity": "blue", "cat": "abilities", "effects": {"parry_splash": 2.0}},
	{"id": "echo", "name": "Echo", "text": "A Perfect note repeats on the next beat for half", "rarity": "purple", "cat": "abilities", "effects": {"perfect_echo": true}},
	{"id": "counter_card", "name": "Riposte lesson", "text": "Unlocks the counter-attack (a yellow ring after every parry)", "rarity": "purple", "cat": "abilities", "effects": {"counter": true}},
	{"id": "sharpshooter", "name": "Sharpshooter", "text": "Perfect snipes do x12 instead of x8", "rarity": "blue", "cat": "abilities", "effects": {"snipe_perfect": 12.0}},
	# Special
	{"id": "ghost", "name": "Haunting", "text": "Every kill spawns a ghost that haunts the nearest creep: 2 damage a beat until it dies", "rarity": "orange", "cat": "special", "effects": {"ghost": true}},
	{"id": "dagger", "name": "Joe's dagger", "text": "The first hit on every creep is a crit", "rarity": "orange", "cat": "special", "effects": {"first_crit": true}},
	{"id": "thornwalls", "name": "Thorned walls", "text": "Creeps beside a wall take 3 damage a second", "rarity": "purple", "cat": "special", "effects": {"wall_thorns": 3.0}},
	{"id": "tarwalls", "name": "Tar walls", "text": "Creeps beside a wall move 25% slower", "rarity": "purple", "cat": "special", "effects": {"wall_slow": 0.25}},
	{"id": "fermata", "name": "Fermata", "text": "A Perfect parry freezes every creep for a beat", "rarity": "orange", "cat": "special", "effects": {"fermata": true}},
	# Draft
	{"id": "reroll", "name": "Second look", "text": "One reroll in each draft", "rarity": "green", "cat": "draft", "effects": {"rerolls": 1}},
	{"id": "bias_tower", "name": "Blueprints", "text": "Tower cards show twice as often", "rarity": "green", "cat": "draft", "effects": {"bias_tower": 2.0}},
	{"id": "bias_special", "name": "Curiosity", "text": "Special cards show three times as often", "rarity": "blue", "cat": "draft", "effects": {"bias_special": 3.0}},
	{"id": "five", "name": "Wide hand", "text": "Drafts show five cards", "rarity": "purple", "cat": "draft", "effects": {"draft_size": 5}},
	{"id": "luck3", "name": "Loaded dice", "text": "+3 luck", "rarity": "blue", "cat": "draft", "effects": {"luck": 3}},
	# --- Round 2 additions (D-0040): more of every category, bigger numbers.
	# Stats
	{"id": "dmg3", "name": "Honed steel", "text": "+40% tower damage; creeps 10% faster", "rarity": "blue", "cat": "stats", "effects": {"damage_mult": 0.4, "enemy_speed_mult": 0.1}},
	{"id": "crit2", "name": "Sharpshooter's eye", "text": "+15% crit chance", "rarity": "green", "cat": "stats", "effects": {"crit_chance": 0.15}},
	{"id": "critboth", "name": "Assassin", "text": "+10% crit chance, +50% crit damage", "rarity": "blue", "cat": "stats", "effects": {"crit_chance": 0.1, "crit_mult": 0.5}},
	{"id": "range2", "name": "Watchtower", "text": "+1.2 range on every tower", "rarity": "blue", "cat": "stats", "effects": {"range_all": 1.2}},
	{"id": "luck2", "name": "Four-leaf clover", "text": "+4 luck", "rarity": "green", "cat": "stats", "effects": {"luck": 4}},
	{"id": "perfects", "name": "Metronome", "text": "Perfects +30% damage", "rarity": "green", "cat": "stats", "effects": {"perfect_mult": 0.3}},
	{"id": "parrydmg", "name": "Iron wrist", "text": "Parry return +40%", "rarity": "green", "cat": "stats", "effects": {"parry_mult": 0.4}},
	{"id": "window", "name": "Slow motion", "text": "Note and parry windows +20 ms", "rarity": "blue", "cat": "stats", "effects": {"note_window_ms": 20.0, "parry_window_ms": 20.0}},
	{"id": "allin", "name": "Overclock", "text": "+60% tower damage; +1 Jammer every wave", "rarity": "purple", "cat": "stats", "effects": {"damage_mult": 0.6, "extra_jammer": 1}},
	# Economy
	{"id": "gold2", "name": "Treasure chest", "text": "+200 gold now", "rarity": "green", "cat": "economy", "effects": {"gold": 200}},
	{"id": "xpnow", "name": "Tome of insight", "text": "+1 talent point now", "rarity": "blue", "cat": "economy", "effects": {"points": 1}},
	{"id": "xp2", "name": "Mentor", "text": "+60% XP", "rarity": "blue", "cat": "economy", "effects": {"xp_mult": 0.6}},
	{"id": "wavebonus", "name": "Tax collector", "text": "Wave bonus +75%", "rarity": "green", "cat": "economy", "effects": {"wave_bonus_mult": 0.75}},
	{"id": "killgold2", "name": "Head hunter", "text": "+3 gold per kill", "rarity": "blue", "cat": "economy", "effects": {"kill_gold": 3}},
	{"id": "bossgold", "name": "Royal ransom", "text": "Bosses pay triple gold and XP", "rarity": "purple", "cat": "economy", "effects": {"bounty": true}},
	{"id": "cheapwalls", "name": "Quarry", "text": "Walls cost 1g; +6 walls", "rarity": "green", "cat": "economy", "effects": {"wall_cheap": 3, "wall_cap": 6}},
	{"id": "discount", "name": "Guild card", "text": "Type upgrades 25% cheaper", "rarity": "blue", "cat": "economy", "effects": {"upgrade_discount": 0.25}},
	# Enemy altering
	{"id": "tome2", "name": "Cursed tome", "text": "Creeps +50% health; +120% gold and XP", "rarity": "orange", "cat": "enemy", "effects": {"enemy_hp_mult": 0.5, "gold_mult": 1.2, "xp_mult": 1.2}},
	{"id": "slowall", "name": "Mud season", "text": "Creeps 15% slower", "rarity": "blue", "cat": "enemy", "effects": {"enemy_speed_mult": -0.15}},
	{"id": "fewer", "name": "Thinning", "text": "20% fewer creeps; elites pay x2", "rarity": "blue", "cat": "enemy", "effects": {"enemy_count_mult": -0.2, "elite_reward_mult": 1.0}},
	{"id": "swarmy", "name": "Infestation", "text": "40% more creeps; +40% gold", "rarity": "purple", "cat": "enemy", "effects": {"enemy_count_mult": 0.4, "gold_mult": 0.4}},
	{"id": "slowelite", "name": "Rusty bows", "text": "Elites wind up twice as slowly", "rarity": "purple", "cat": "enemy", "effects": {"enemy_attack_mult": 1.0}},
	{"id": "shadegold", "name": "Ghost bounty", "text": "Shades pay triple", "rarity": "green", "cat": "enemy", "effects": {"shade_reward_mult": 2.0}},
	# Tower altering
	{"id": "poison2", "name": "Toxin", "text": "Poison ticks do triple", "rarity": "blue", "cat": "tower", "effects": {"poison_mult": 2.0}},
	{"id": "arc2", "name": "Conductor's wire", "text": "Lightning arcs reach 6 tiles", "rarity": "purple", "cat": "tower", "effects": {"arc_range": 4.0}},
	{"id": "splash2", "name": "Shrapnel", "text": "+1 splash radius on Splash towers", "rarity": "green", "cat": "tower", "effects": {"splash_bonus": 1.0}},
	{"id": "cannon2", "name": "Siegeworks", "text": "Cannons +40% damage, +1 range", "rarity": "green", "cat": "tower", "effects": {"damage_kick": 0.4, "range_kick": 1.0}},
	{"id": "frost2", "name": "Permafrost", "text": "Frost towers +50% damage, +1 range", "rarity": "green", "cat": "tower", "effects": {"damage_slow": 0.5, "range_slow": 1.0}},
	{"id": "light2", "name": "Lighthouse", "text": "Light towers +2 range", "rarity": "green", "cat": "tower", "effects": {"range_light": 2.0}},
	{"id": "veils", "name": "Daylight", "text": "Cracked veils stay open 2 beats longer", "rarity": "blue", "cat": "tower", "effects": {"veil_crack": 2.0}},
	{"id": "unlockall", "name": "Master key", "text": "Every tower type unlocks now", "rarity": "purple", "cat": "tower", "effects": {"arsenal": true}},
	# Abilities
	{"id": "notes", "name": "Double time", "text": "+1 note per phrase", "rarity": "green", "cat": "abilities", "effects": {"note_rate": 1}},
	{"id": "notes2", "name": "Virtuoso", "text": "+2 notes per phrase; Perfects +20%", "rarity": "purple", "cat": "abilities", "effects": {"note_rate": 2, "perfect_mult": 0.2}},
	{"id": "echo2", "name": "Reverb", "text": "Hit notes echo for 50%", "rarity": "blue", "cat": "abilities", "effects": {"echo": 0.5}},
	{"id": "crescendo", "name": "Long Crescendo", "text": "Crescendo +4 s", "rarity": "blue", "cat": "abilities", "effects": {"crescendo": 4.0}},
	{"id": "counter2", "name": "Riposte drills", "text": "Counters +50%", "rarity": "blue", "cat": "abilities", "effects": {"counter_mult": 0.5}},
	{"id": "shield2", "name": "Aegis", "text": "+2 Conductor shields every wave", "rarity": "blue", "cat": "abilities", "effects": {"shield_cap": 2}},
	{"id": "charge2", "name": "Capacitor", "text": "+2 Restore charges now and to the cap", "rarity": "green", "cat": "abilities", "effects": {"restore_charges": 2}},
	# Special
	{"id": "wallsboth", "name": "Murder holes", "text": "Walls slow 20% and deal 2 a second", "rarity": "purple", "cat": "special", "effects": {"wall_slow": 0.2, "wall_thorns": 2.0}},
	{"id": "crits_slow", "name": "Frostbite", "text": "Crits slow for a beat; +10% crit chance", "rarity": "purple", "cat": "special", "effects": {"crit_slow": true, "crit_chance": 0.1}},
	{"id": "echo_perfect", "name": "Afterimage", "text": "A Perfect note repeats on the next beat for half", "rarity": "orange", "cat": "special", "effects": {"perfect_echo": true}},
	# Draft
	{"id": "reroll2", "name": "Third look", "text": "Two rerolls in each draft", "rarity": "blue", "cat": "draft", "effects": {"rerolls": 2}},
	{"id": "bias_abil", "name": "Grimoire", "text": "Ability cards show twice as often", "rarity": "green", "cat": "draft", "effects": {"bias_abilities": 2.0}},
	{"id": "bias_econ", "name": "Ledger", "text": "Economy cards show twice as often", "rarity": "green", "cat": "draft", "effects": {"bias_economy": 2.0}},
	{"id": "bias_enemy", "name": "Bestiary", "text": "Enemy cards show twice as often", "rarity": "green", "cat": "draft", "effects": {"bias_enemy": 2.0}},
	{"id": "bias_stats", "name": "Training manual", "text": "Stat cards show twice as often", "rarity": "green", "cat": "draft", "effects": {"bias_stats": 2.0}},
	{"id": "four", "name": "Open hand", "text": "Drafts show four cards", "rarity": "blue", "cat": "draft", "effects": {"draft_size": 4}},
	{"id": "luck4", "name": "Horseshoe", "text": "+6 luck", "rarity": "purple", "cat": "draft", "effects": {"luck": 6}},
]


static func by_id(id: String) -> Dictionary:
	for c in CARDS:
		if c["id"] == id:
			return c
	return {}


static func rarity_index(r: String) -> int:
	return RARITIES.find(r)


## Roll one card: rarity by weight (luck added above grey), then category by
## weight (biases from cards), then a random card of that pair. Falls back a
## rarity step when the pair has nothing left to offer.
static func roll(rng: RandomNumberGenerator, luck: float, bias: Dictionary, exclude: Array, allow_orange: bool) -> Dictionary:
	var weights := {}
	for r in RARITIES:
		weights[r] = RARITY_WEIGHT[r] + (luck if r != "grey" else 0.0)
	if not allow_orange:
		weights["orange"] = 0.0
	var rarity := _weighted(rng, weights)
	var cat_weights := {}
	for c in CATEGORIES:
		cat_weights[c] = bias.get(c, 1.0)
	var cat := _weighted(rng, cat_weights)
	var ri := rarity_index(rarity)
	while ri >= 0:
		var pool := _matching(RARITIES[ri], cat, exclude)
		if pool.is_empty():
			pool = _matching(RARITIES[ri], "", exclude)
		if not pool.is_empty():
			return pool[rng.randi() % pool.size()]
		ri -= 1
	return {}


static func _matching(rarity: String, cat: String, exclude: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in CARDS:
		if c["rarity"] == rarity and (cat == "" or c["cat"] == cat) and not exclude.has(c["id"]):
			out.append(c)
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
