extends SceneTree
# B1+B2: the campaign screens and the new enemies as screenshots. Starts at Night 3
# through the night picker (4 points to spend), shows the start panel, the talent
# tree, the test arena's enemies and markers, the Foreman, the morning, the card
# and the results with the campaign buttons. Arg: out folder.
var m; var run; var f := 0; var out := ""
func _init():
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	M7Run.quick = false
	Campaign.begin(2)
	run = load("res://run3d.tscn").instantiate(); root.add_child(run)
func shot(name: String):
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT ", name)
func _process(_d):
	f += 1
	if m == null: m = run.sim
	match f:
		10:
			print("night ", Campaign.night_number(), " points ", m.points, " counter ", m.gstats.get("counter", false), " unlocked ", m.unlocked)
			shot("b1_start")
		11: m.toggle_tree()
		20:
			for id in ["counter_attack", "freestyle", "perfect_freestyle"]:
				print("take ", id, " ", m.take_night_talent(id))
			print("points ", m.points, " owned ", m.night_owned, " counter ", m.gstats.get("counter", false))
		30: shot("b1_tree")
		31: m.toggle_tree()
		35:
			m.start_wave()
			m.health = 99
		40:
			# A small maze by the mine, then the fork and mastery for Arrows.
			m.gold = 3000
			var route = m.grid.route()
			var walls := 0; var towers := 0
			for r in route.slice(2, 12):
				for d in [Vector2i(0, 1), Vector2i(0, -1)]:
					var c: Vector2i = r + d
					if walls < 4 and m.try_place(c, "wall"): walls += 1
					elif towers < 3 and m.try_place(c, "kick"): towers += 1
			print("built walls ", walls, " towers ", towers)
			print("fork ", m.upgrade_type("kick", 1), " ", m.rank_label("kick"), "  mastery ", m.upgrade_type("kick"), " ", m.rank_label("kick"), " gold ", m.gold)
		60:
			for k in ["door", "busker", "digger", "moth", "undertaker", "last_orders"]:
				m._arena_spawn(k)
		400:
			print("creeps ", m.creeps.map(func(c): return c.get("kind", "?")))
			print("marks ", m.b2_marks().map(func(x): return x["label"]))
			shot("b2_arena")
		401:
			m.health = 99
			m._arena_spawn("foreman")
		700:
			print("boss ", m.boss_name(), " alive ", m.boss_alive())
			shot("b2_foreman")
		701:
			m.health = 99
			print("b2 stats ", m.b2_stats)
			m.m7_stats["xp"] = 219.0
			m._finish()
		800:
			print("morning points ", m.points)
			shot("b1_morning")
		801: m.begin_card()
		815:
			print("drafting ", m.drafting, " cards ", m.draft_cards.map(func(c): return "%s %s" % [c["name"], c["night_rarity"]]))
			shot("b1_card")
		816:
			if m.drafting: m._pick(0)
			if m.state == "playing": m.state = "won"
		830:
			print("results next ", m.hud.res_next.visible, " retry ", m.hud.res_retry.visible, " new ", m.hud.res_new.visible)
			shot("b1_results_won")
		831: m.state = "lost"; m.hud._res_shown = false
		845:
			print("lost: next ", m.hud.res_next.visible, " retry ", m.hud.res_retry.visible)
			shot("b1_results_lost")
			quit()
