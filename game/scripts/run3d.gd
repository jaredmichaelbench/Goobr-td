extends Node3D
## Demo 1 run scene (M9): the rules (RunSim), the 3D board (View3D) and the floating
## marks (Indicators). The HUD comes with the sim. M7Run.quick picks 10 or 20 waves.

var sim: RunSim
var view: View3D
var marks: Indicators


func _ready() -> void:
	sim = RunSim.new()
	sim.name = "Sim"
	add_child(sim)
	view = View3D.new()
	view.name = "View"
	view.setup(sim)
	add_child(view)
	sim.view = view
	var layer := CanvasLayer.new()
	layer.layer = 2
	add_child(layer)
	marks = Indicators.new()
	marks.sim = sim
	marks.view = view
	layer.add_child(marks)
