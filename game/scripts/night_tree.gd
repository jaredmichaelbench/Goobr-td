class_name NightTree
## The campaign talent tree, locked in D-0057 to D-0059 and built in B1 (D-0067).
## Counter Attack sits in the middle of the bottom row. Towers branch left,
## Rhythm right. Each side has two flavour nodes and a gate, then an inner path
## that runs to Perfect Solo (the middle capstone, reachable from either side;
## nothing leads on from it since D-0070) and an outer path that swings wide to a power node
## and climbs to the side's top capstone. You only move up: a node opens once any
## node in its "after" list is owned. Every node costs 1 point and is taken once.
## 10 points a run, so one run reaches the top of one side, never both.
##
## Edit freely, no code: names, texts and links live in NODES. Effects are read
## by NightRun (see NightRun._apply_talent). x and y are the node's place on a
## 2000 x 1440 sheet, as in Jared's builder mockup; the HUD scales them.

const NODES := {
	"counter_attack": {"name": "Counter Attack", "side": "mid", "x": 1000, "y": 1290, "after": [],
		"text": "Tap Space again right after a landed parry: a counter with big stagger damage (less on bosses).",
		"effects": {"counter": true}},
	# --- Towers (left) ---
	"well_constructed": {"name": "Well Constructed", "side": "towers", "x": 760, "y": 1290, "after": ["counter_attack"],
		"text": "+15% damage for every tower.", "effects": {"damage_mult": 0.15}},
	"extended_reach": {"name": "Extended Reach", "side": "towers", "x": 520, "y": 1290, "after": ["well_constructed"],
		"text": "+25% range for every tower. The range rings grow to show it.", "effects": {"range_pct": 0.25}},
	"pickup": {"name": "Pickup", "side": "towers", "x": 520, "y": 1070, "after": ["extended_reach"],
		"text": "Every tower fires an extra shot on the \"and\" of beat 4, the off-beat just before each new bar. Replaced Quick Draw (D-0070).", "effects": {"pickup": true}},
	"unlock_lightning": {"name": "Unlock Lightning", "side": "towers", "x": 380, "y": 850, "after": ["pickup"],
		"text": "The Lightning tower joins your roster for the rest of the run.", "effects": {"unlock": "lightning"}},
	"unlock_poison": {"name": "Unlock Poison", "side": "towers", "x": 660, "y": 850, "after": ["pickup"],
		"text": "The Poison tower joins your roster for the rest of the run.", "effects": {"unlock": "poison"}},
	"thorny_walls": {"name": "Thorny Walls", "side": "towers", "x": 140, "y": 700, "after": ["unlock_lightning"],
		"text": "Creeps beside your walls are slowed and bleed, more the longer they stay.", "effects": {"thorny_walls": true}},
	"improved_lightning": {"name": "Improved Lightning", "side": "towers", "x": 380, "y": 590, "after": ["unlock_lightning"],
		"text": "Lightning arcs jump once more (stacks with the Fork upgrade).", "effects": {"arc_jumps": 1}},
	"improved_poison": {"name": "Improved Poison", "side": "towers", "x": 660, "y": 450, "after": ["unlock_poison"],
		"text": "When a poisoned creep dies its poison jumps to the nearest creep.",
		"effects": {"poison_jump": true}},
	"unlock_light": {"name": "Unlock Light", "side": "towers", "x": 520, "y": 320, "after": ["improved_lightning", "improved_poison"],
		"text": "The Light tower joins your roster for the rest of the run.", "effects": {"unlock": "light"}},
	"improved_light": {"name": "Improved Light", "side": "towers", "x": 520, "y": 100, "after": ["unlock_light"], "capstone": true,
		"text": "Towers in a Light tower's glow also fire on the off-beats.", "effects": {"improved_light": true}},
	# --- The middle ---
	"perfect_solo": {"name": "Perfect Solo", "side": "mid", "x": 1000, "y": 700, "after": ["unlock_poison", "solo"], "capstone": true,  # The top of the middle: nothing leads on (D-0070).
		"text": "A Perfect on every note of a Crescendo: you parry and counter automatically for 8 seconds.",
		"effects": {"perfect_solo": true}},
	# --- Rhythm (right) ---
	"freestyle": {"name": "Freestyle", "side": "rhythm", "x": 1240, "y": 1290, "after": ["counter_attack"],
		"text": "The Good window for notes is 15 ms wider.", "effects": {"note_window_ms": 15.0}},
	"perfect_freestyle": {"name": "Perfect Freestyle", "side": "rhythm", "x": 1480, "y": 1290, "after": ["freestyle"],
		"text": "The Perfect window is 5 ms wider.", "effects": {"perfect_window_ms": 5.0}},
	"defensive_percussion": {"name": "Defensive Percussion", "side": "rhythm", "x": 1480, "y": 1070, "after": ["perfect_freestyle"],
		"text": "The parry window is 25 ms wider.", "effects": {"parry_window_ms": 25.0}},
	"solo": {"name": "Solo", "side": "rhythm", "x": 1340, "y": 850, "after": ["defensive_percussion"],
		"text": "Finish a Crescendo without dropping a note: 2 shields and 1 Restore charge.", "effects": {"solo": true}},
	"grace_notes": {"name": "Grace Notes", "side": "rhythm", "x": 1620, "y": 850, "after": ["defensive_percussion"],
		"text": "Each call gets an 8th-note accent. A hit strikes for 70% of a note, a Perfect for 130% extra.",
		"effects": {"grace_notes": true}},
	"the_right_instrument": {"name": "The Right Instrument", "side": "rhythm", "x": 1860, "y": 700, "after": ["grace_notes"],
		"text": "Perfect notes do something special per tower: Arrow pierces, Cannon blasts wider, Frost freezes 2 s, Poison lasts 6 s longer, Lightning jumps twice more, Light fires its towers three times.",
		"effects": {"right_instrument": true}},
	"improved_restore": {"name": "Improved Restore", "side": "rhythm", "x": 1620, "y": 590, "after": ["grace_notes"],
		"text": "Using Restore also starts a Crescendo.", "effects": {"improved_restore": true}},
	"melodic_healing": {"name": "Melodic Healing", "side": "rhythm", "x": 1340, "y": 450, "after": ["solo"],
		"text": "A Perfect on every note of a Crescendo heals the camp 1 health.", "effects": {"melodic_healing": true}},
	"slowing_song": {"name": "Slowing Song", "side": "rhythm", "x": 1480, "y": 320, "after": ["improved_restore", "melodic_healing"],
		"text": "Notes slow their target 5% (Perfects 15%), stacking 3 times. Doesn't stack with Frost.",
		"effects": {"slowing_song": true}},
	"improved_counter": {"name": "Improved Counter Attack", "side": "rhythm", "x": 1480, "y": 100, "after": ["slowing_song"], "capstone": true,
		"text": "Counters hit 50% harder, strike everything within 2 tiles, and the tap window grows from 150 to 250 ms.",
		"effects": {"counter_mult": 0.5, "counter_window_ms": 100.0, "counter_all": true}},
}

const SIDE_COLORS := {"towers": Color("fb923c"), "rhythm": Color("4ade80"), "mid": Color("38bdf8")}
const SHEET := Vector2(2000, 1440)


## Can this node be taken now? Not owned, a point to spend, and linked to one you own.
static func available(id: String, owned: Array, points: int) -> bool:
	if owned.has(id) or not NODES.has(id) or points <= 0:
		return false
	return reachable(id, owned)


## Linked to an owned node (or the root, which needs nothing).
static func reachable(id: String, owned: Array) -> bool:
	var after: Array = NODES[id]["after"]
	if after.is_empty():
		return true
	for a in after:
		if owned.has(a):
			return true
	return false


## Every link as [from, to], for drawing.
static func links() -> Array:
	var out := []
	for id in NODES:
		for a in NODES[id]["after"]:
			out.append([a, id])
	return out


static func name_of(id: String) -> String:
	return NODES[id]["name"] if NODES.has(id) else id
