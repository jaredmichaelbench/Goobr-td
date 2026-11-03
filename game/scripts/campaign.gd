class_name Campaign
## The five-night campaign (B1, D-0067): nights in a row, and what carries from
## one to the next. What you earn about yourself carries over (health, XP and
## level, talents and their points, cards); what you build stays at the old camp
## (towers, walls, gold, type upgrades). Each night is its own level file; the
## scene reloads between nights and NightRun reads the carried state back.
##
## Everything lives in static variables so it survives the scene reload. A
## snapshot is kept at the start of every night, so a lost night can be retried
## with what you had when it started (testing, D-0056).

const NIGHTS := [
	"res://levels/night_life.cfg",
	"res://levels/night_2.cfg",
	"res://levels/night_3.cfg",
	"res://levels/night_4.cfg",
	"res://levels/night_5.cfg",
]
## Talent points handed out on each night's morning (D-0058): 1 after Night 1
## (it buys Counter Attack), then 3 after Nights 2 to 4. 10 in a run.
const POINTS_AFTER := [1, 3, 3, 3, 0]

static var active := false  # A campaign is running (set by the title screen).
static var index := 0  # Which night is playing, 0 to 4.
static var carry := {}  # The state carried into the current night (see capture()).
static var start_of_night := {}  # carry as it was when this night began, for Retry.
static var history: Array = []  # One summary per finished night, for the run log.


## A fresh run from Night 1 (or from any night, for testing: the night picker).
static func begin(from_night := 0) -> void:
	active = true
	index = clampi(from_night, 0, NIGHTS.size() - 1)
	carry = {}
	history = []
	if index > 0:
		carry = test_carry(index)
	start_of_night = carry.duplicate(true)
	LevelRun.active = true
	LevelRun.level_path = NIGHTS[index]


## Jumping straight to a later night (night picker): the points and level you'd
## roughly have by then, nothing spent, so the tree can be tried before Start.
static func test_carry(night: int) -> Dictionary:
	var pts := 0
	for i in night:
		pts += POINTS_AFTER[i]
	return {"health": 20, "level": 1 + night * 3, "xp": 0.0, "points": pts, "talents": [], "cards": [], "card_taken": {}, "orange_taken": false, "test_start": true}


static func is_last() -> bool:
	return index >= NIGHTS.size() - 1


static func night_number() -> int:
	return index + 1


## What carries out of a night that was just survived (or is being left).
static func capture(game) -> Dictionary:
	return {
		"health": game.health,
		"level": game.level,
		"xp": game.xp,
		"points": game.points,
		"talents": game.night_owned.duplicate(),
		"cards": game.card_picks.duplicate(true),
		"card_taken": game.card_taken.duplicate(),
		"orange_taken": game.orange_taken,
		"accum_crit": game.accum_crit,
	}


## Morning is done: carry the run into the next night and reload.
static func advance(game) -> void:
	history.append(game.night_summary())
	carry = capture(game)
	index += 1
	start_of_night = carry.duplicate(true)
	LevelRun.level_path = NIGHTS[index]
	game.get_tree().reload_current_scene()


## The camp fell (or the player wants the night again): the same night, with
## what you had when it started.
static func retry(game) -> void:
	carry = start_of_night.duplicate(true)
	game.get_tree().reload_current_scene()


static func stop() -> void:
	active = false
	index = 0
	carry = {}
	start_of_night = {}
	history = []
	LevelRun.level_path = NIGHTS[0]
