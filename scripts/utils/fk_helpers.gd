## Utility helpers used across the project
class_name FKHelpers
extends RefCounted

static func join_array(arr: Array, sep: String = ", ") -> String:
	if arr == null or arr.size() == 0:
		return ""
	var out := ""
	for i in range(arr.size()):
		out += str(arr[i])
		if i < arr.size() - 1:
			out += sep
	return out
