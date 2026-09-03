class_name CorruptionEffect
extends RefCounted

var source: String = ""
var power: float = 0.0
var tags: Array[String] = []
var ignore_resistance: bool = false


func _init(
	p_source: String = "",
	p_power: float = 0.0,
	p_tags: Array[String] = [],
	p_ignore_resistance: bool = false
) -> void:
	source = p_source
	power = p_power
	tags = p_tags.duplicate()
	ignore_resistance = p_ignore_resistance
