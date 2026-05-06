## Slide 5: review and final confirmation.
class_name Slide05ReviewConfirm
extends CreationSlideBase


func collect_payload() -> Dictionary:
	var accepted := false
	var checkbox := get_node_or_null("ConfirmCheckBox") as CheckBox
	if checkbox:
		accepted = checkbox.button_pressed
	return {
		"confirmation_accepted": accepted,
	}


func enter_slide(data: Resource) -> void:
	if data == null:
		return
	var summary := get_node_or_null("SummaryLabel") as RichTextLabel
	if summary == null:
		return
	if data.has_method("to_dict"):
		summary.text = JSON.stringify(data.to_dict(), "\t")
