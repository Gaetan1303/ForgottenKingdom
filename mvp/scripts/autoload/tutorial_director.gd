## autoload/tutorial_director.gd
## Director data-driven du tutoriel: suit les étapes, pousse des messages, puis lance l'histoire.
extends Node

const SAVE_KEY_STEP := "tutorial_step"
const SAVE_KEY_COMPLETED := "tutorial_completed"
const SAVE_KEY_STORY_STARTED := "tutorial_story_started"

var _steps: Array[Dictionary] = [
	{
		"id": "tuto_recruter",
		"type": "action",
		"action_id": "recruter",
		"hint": "Tutoriel: commencez par Recruter pour renforcer vos troupes.",
		"done": "Excellent. Vos forces augmentent.",
	},
	{
		"id": "tuto_espionner",
		"type": "action",
		"action_id": "espionner",
		"hint": "Tutoriel: utilisez Espionner pour reveler une maison.",
		"done": "Bien joue. Les informations ennemies sont cruciales.",
	},
	{
		"id": "tuto_diplomatie",
		"type": "action",
		"action_id": "diplomatie",
		"hint": "Tutoriel: tentez Diplomatie pour ouvrir des alliances.",
		"done": "Parfait. Le pouvoir passe aussi par la politique.",
	},
	{
		"id": "tuto_passage_nuit",
		"type": "phase",
		"moment": "nuit",
		"hint": "Tutoriel: cliquez sur Fin de tour pour passer a la Nuit.",
		"done": "La nuit ouvre des options discretes et des passifs.",
	},
	{
		"id": "tuto_recruter_pnj",
		"type": "action",
		"action_id": "recruter_pnj",
		"hint": "Tutoriel: de nuit, recrutez un PNJ de domaine.",
		"done": "Excellent. Les PNJ specialisent votre clan.",
	},
	{
		"id": "tuto_tour2",
		"type": "tour",
		"tour_min": 2,
		"hint": "Tutoriel: terminez la nuit pour commencer le Tour 2.",
		"done": "Tutoriel termine. L'histoire d'Ingrid commence.",
	},
]

var _queue: Array[String] = []
var _story_launch_pending: bool = false


func _ready() -> void:
	if is_completed():
		return
	# Message d'entree du tutoriel
	if get_current_step_index() == 0:
		_queue.append(get_current_hint())


func is_completed() -> bool:
	return bool(SaveSystem.get_value(SAVE_KEY_COMPLETED, false))


func get_current_step_index() -> int:
	if is_completed():
		return _steps.size()
	return clampi(int(SaveSystem.get_value(SAVE_KEY_STEP, 0)), 0, _steps.size())


func get_current_step() -> Dictionary:
	var idx := get_current_step_index()
	if idx < 0 or idx >= _steps.size():
		return {}
	return _steps[idx]


func get_current_hint() -> String:
	var step := get_current_step()
	return str(step.get("hint", ""))


func consume_next_message() -> String:
	if _queue.is_empty():
		return ""
	return _queue.pop_front()


func consume_story_launch_request() -> bool:
	if not _story_launch_pending:
		return false
	_story_launch_pending = false
	return true


func on_action_committed(action_id: String) -> void:
	if is_completed():
		return
	var step := get_current_step()
	if str(step.get("type", "")) != "action":
		return
	if str(step.get("action_id", "")) != action_id:
		return
	_complete_current_step()


func on_phase_changed(moment: String, current_tour: int) -> void:
	if is_completed():
		return
	var step := get_current_step()
	var stype := str(step.get("type", ""))
	if stype == "phase":
		if str(step.get("moment", "")) == moment:
			_complete_current_step()
		return
	if stype == "tour":
		if current_tour >= int(step.get("tour_min", 999)):
			_complete_current_step()


func _complete_current_step() -> void:
	var idx := get_current_step_index()
	if idx < 0 or idx >= _steps.size():
		return
	var step := _steps[idx]
	var done_txt := str(step.get("done", ""))
	if not done_txt.is_empty():
		_queue.append(done_txt)

	var next_idx := idx + 1
	SaveSystem.set_value(SAVE_KEY_STEP, next_idx)
	if next_idx < _steps.size():
		var hint := str(_steps[next_idx].get("hint", ""))
		if not hint.is_empty():
			_queue.append(hint)
		SaveSystem.save()
		return

	# Fin du tutoriel
	SaveSystem.set_value(SAVE_KEY_COMPLETED, true)
	SaveSystem.save()
	if not bool(SaveSystem.get_value(SAVE_KEY_STORY_STARTED, false)):
		SaveSystem.set_value(SAVE_KEY_STORY_STARTED, true)
		SaveSystem.save()
		_story_launch_pending = true
