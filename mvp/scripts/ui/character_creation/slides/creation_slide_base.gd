## Base class for character creation slides.
class_name CreationSlideBase
extends Control

signal slide_data_submitted(payload)
signal slide_next_requested
signal slide_previous_requested

var manager: Node = null


func bind_manager(manager_node: Node) -> void:
	manager = manager_node


func enter_slide(_data: Resource) -> void:
	pass


func exit_slide() -> void:
	pass


func collect_payload() -> Dictionary:
	return {}


func submit_current_data() -> void:
	emit_signal("slide_data_submitted", collect_payload())


func request_next() -> void:
	submit_current_data()
	emit_signal("slide_next_requested")


func request_previous() -> void:
	# Conserver les choix de la diapositive avant tout retour en arrière.
	submit_current_data()
	emit_signal("slide_previous_requested")
