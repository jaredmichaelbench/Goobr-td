extends SceneTree
# Demo 1 title screen: loads the menu, opens each overlay, saves screenshots. Arg: out folder.
var t; var f := 0; var out := ""
func _init():
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	t = load("res://menu.tscn").instantiate(); root.add_child(t)
func shot(name: String):
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT ", name)
func _process(_d):
	f += 1
	if f == 40: shot("t0_title")
	if f == 45: t._show_help()
	if f == 60: shot("t1_help")
	if f == 65: t._show_settings()
	if f == 80: shot("t2_settings")
	if f == 85: t._show_credits()
	if f == 100: shot("t3_credits")
	if f == 110: quit()
