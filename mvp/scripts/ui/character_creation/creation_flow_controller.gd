## Handles slide navigation rules and state transitions.
class_name CharacterCreationFlowController
extends RefCounted

enum Step {
	BASIC_INFO,
	CLASS_AND_STATS,
	FEATS_AND_ABILITIES,
	ITEMS_AND_EQUIPMENT,
	REVIEW_AND_CONFIRM,
}

const TOTAL_STEPS := 5

var current_step: int = Step.BASIC_INFO


func reset() -> void:
	current_step = Step.BASIC_INFO


func can_go_previous() -> bool:
	return current_step > Step.BASIC_INFO


func can_go_next() -> bool:
	return current_step < TOTAL_STEPS - 1


func go_previous() -> int:
	if can_go_previous():
		current_step -= 1
	return current_step


func go_next() -> int:
	if can_go_next():
		current_step += 1
	return current_step


func go_to(step_index: int) -> int:
	current_step = clampi(step_index, 0, TOTAL_STEPS - 1)
	return current_step


func is_last_step() -> bool:
	return current_step == TOTAL_STEPS - 1
