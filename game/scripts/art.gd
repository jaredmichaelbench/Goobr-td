class_name Art
extends RefCounted
## Demo 1 art table (D-0044): which model stands for which thing, and at what size.
## Every model is a free CC0 KayKit pack by Kay Lousberg, kept in assets/kaykit/
## (licences beside them). One metre is one tile. Change a line here to swap a look.

const HEX := "res://assets/kaykit/hex/"
const CHARS := "res://assets/kaykit/chars/"

## Towers: model and footprint (metres across). Silhouette tells the type; the
## roof colour backs it up.
const TOWERS := {
	"kick": {"model": HEX + "building_tower_catapult_red.gltf", "fit": 0.95},
	"bass": {"model": HEX + "building_tower_B_blue.gltf", "fit": 0.95},
	"slow": {"model": HEX + "building_tower_base_blue.gltf", "fit": 0.9, "crystal": Color(0.6, 0.85, 1.0)},
	"poison": {"model": HEX + "building_tower_A_green.gltf", "fit": 0.9},
	"lightning": {"model": HEX + "building_tower_B_yellow.gltf", "fit": 0.95, "crystal": Color(0.8, 0.9, 1.0)},
	"light": {"model": HEX + "building_church_yellow.gltf", "fit": 0.95},
}
const WALL := HEX + "wall_straight.gltf"
const CASTLE := HEX + "building_castle_blue.gltf"
const MINE := HEX + "building_mine_red.gltf"
const ROCKS := [HEX + "mountain_A.gltf", HEX + "mountain_B.gltf", HEX + "mountain_C.gltf", HEX + "mountain_A_grass.gltf", HEX + "mountain_C_grass.gltf"]
const DECOR := [HEX + "trees_A_large.gltf", HEX + "trees_A_medium.gltf", HEX + "trees_B_large.gltf", HEX + "trees_B_medium.gltf", HEX + "hills_A_trees.gltf", HEX + "hills_B_trees.gltf", HEX + "hills_C_trees.gltf", HEX + "mountain_B_grass_trees.gltf", HEX + "mountain_A_grass_trees.gltf", HEX + "tree_single_A.gltf", HEX + "tree_single_B.gltf"]
const STONES := [HEX + "rock_single_A.gltf", HEX + "rock_single_B.gltf", HEX + "rock_single_C.gltf", HEX + "rock_single_D.gltf", HEX + "rock_single_E.gltf", HEX + "resource_stone.gltf"]
const TREES := [HEX + "tree_single_A.gltf", HEX + "tree_single_B.gltf"]
const PROPS := [HEX + "barrel.gltf", HEX + "crate_A_big.gltf", HEX + "tent.gltf", HEX + "resource_stone.gltf", HEX + "sack.gltf"]

## Creeps: skeletons. height = metres tall on the board; tint = overlay colour (alpha = strength).
const CREEPS := {
	"grunt": {"model": CHARS + "Skeleton_Minion.glb", "height": 1.55, "walk": "Walking_A"},
	"runner": {"model": CHARS + "Skeleton_Rogue.glb", "height": 1.05, "walk": "Running_A"},
	"brute": {"model": CHARS + "Skeleton_Warrior.glb", "height": 1.5, "walk": "Walking_C"},
	"swarm": {"model": CHARS + "Skeleton_Minion.glb", "height": 0.75, "walk": "Running_B", "tint": Color(1.0, 0.5, 0.7, 0.25)},
	"shade": {"model": CHARS + "Skeleton_Mage.glb", "height": 1.2, "walk": "Walking_B"},
	"jammer": {"model": CHARS + "Skeleton_Warrior.glb", "height": 1.6, "walk": "Walking_A", "tint": Color(0.9, 0.1, 0.15, 0.3)},
	"archer": {"model": CHARS + "Skeleton_Rogue.glb", "height": 1.55, "walk": "Walking_A", "tint": Color(0.9, 0.1, 0.15, 0.3)},
	"warden": {"model": CHARS + "Skeleton_Warrior.glb", "height": 1.6, "walk": "Walking_A", "tint": Color(0.3, 0.5, 1.0, 0.3)},
	"boss": {"model": CHARS + "Skeleton_Mage.glb", "height": 2.6, "walk": "Walking_D_Skeletons"},
	"boss2": {"model": CHARS + "Skeleton_Warrior.glb", "height": 2.8, "walk": "Walking_C"},
}
const CONDUCTOR := CHARS + "Mage.glb"
const LOOPED := ["Walking_A", "Walking_B", "Walking_C", "Walking_D_Skeletons", "Running_A", "Running_B", "Idle", "Idle_Combat", "Spellcasting", "Cheer", "2H_Melee_Idle"]

static var _cache := {}


static func scene(path: String) -> PackedScene:
	if not _cache.has(path):
		_cache[path] = load(path) if ResourceLoader.exists(path) else null
	return _cache[path]


## A model instance scaled so its footprint is `fit` metres across (or its height
## `height` metres), standing on y = 0 and centred on the origin. Null if missing.
static func make(path: String, fit := 0.0, height := 0.0) -> Node3D:
	var ps := scene(path)
	if ps == null:
		return null
	var model: Node3D = ps.instantiate()
	var box := aabb(model)
	var s := 1.0
	if fit > 0.0:
		s = fit / maxf(maxf(box.size.x, box.size.z), 0.01)
	elif height > 0.0:
		s = height / maxf(box.size.y, 0.01)
	model.scale = Vector3.ONE * s
	model.position = -Vector3(box.get_center().x, box.position.y, box.get_center().z) * s
	var holder := Node3D.new()
	holder.add_child(model)
	return holder


## The box around every mesh under a node, in the node's own space.
static func aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.get_aabb()
		var t := Transform3D.IDENTITY
		var p: Node = mi
		while p != null and p != n:
			if p is Node3D:
				t = p.transform * t
			p = p.get_parent()
		b = t * b
		box = b if first else box.merge(b)
		first = false
	return box


## Characters stand in T-pose in the file, so their box is wide; fit them by height.
static func character(kind: String) -> Node3D:
	var spec: Dictionary = CREEPS.get(kind, CREEPS["grunt"])
	var ps := scene(spec["model"])
	if ps == null:
		return null
	var model: Node3D = ps.instantiate()
	var box := aabb(model)
	var s: float = spec["height"] / maxf(box.size.y, 0.01)
	model.scale = Vector3.ONE * s
	var holder := Node3D.new()
	holder.add_child(model)
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if ap != null:
		for name in LOOPED:
			if ap.has_animation(name):
				ap.get_animation(name).loop_mode = Animation.LOOP_LINEAR
	return holder
