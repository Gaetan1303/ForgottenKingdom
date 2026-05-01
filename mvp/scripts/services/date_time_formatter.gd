## scripts/services/date_time_formatter.gd
## Utility service (SRP): format unix timestamps in a runtime-compatible way.
extends RefCounted
class_name DateTimeFormatter


static func format_local_datetime(unix_ts: int) -> String:
	if unix_ts <= 0:
		return "-"
	var dt := _get_datetime_dict(unix_ts)
	if dt.is_empty():
		# Fallback for older/incompatible runtimes.
		return str(unix_ts)
	return "%04d-%02d-%02d %02d:%02d" % [
		int(dt.get("year", 0)),
		int(dt.get("month", 0)),
		int(dt.get("day", 0)),
		int(dt.get("hour", 0)),
		int(dt.get("minute", 0)),
	]


static func _get_datetime_dict(unix_ts: int) -> Dictionary:
	if Time.has_method("get_datetime_dict_from_unix_time"):
		var value: Variant = Time.call("get_datetime_dict_from_unix_time", unix_ts)
		if value is Dictionary:
			return value as Dictionary
	return {}
