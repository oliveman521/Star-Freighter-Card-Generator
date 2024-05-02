@tool
extends Control

@export_enum("Mine", "RP", "Investigate", "Storage", "Housing", "Terra", "Energy", "Other") var color_type: String = "Other":
	set(new_val):
		color_type = new_val
		queue_redraw()
# Called when the node enters the scene tree for the first time.
func _draw() -> void:
	self_modulate = Card.COLOR_MAP[color_type]


