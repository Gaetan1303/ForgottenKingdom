class_name CorruptionStage
extends RefCounted

## Stades métier de corruption. Les bornes sont centralisées ici afin que
## l'UI, la sauvegarde et les règles de gameplay ne dupliquent pas les seuils.
enum Type {
	PURE,
	TAINTED,
	BREAKING,
	SUBMISSIVE,
	CORRUPTED,
	LOST,
}

const MIN_LEVEL := 0.0
const MAX_LEVEL := 100.0

static func from_level(level: float) -> Type:
	var normalized := clampf(level, MIN_LEVEL, MAX_LEVEL)
	if normalized < 20.0:
		return Type.PURE
	if normalized < 40.0:
		return Type.TAINTED
	if normalized < 60.0:
		return Type.BREAKING
	if normalized < 80.0:
		return Type.SUBMISSIVE
	if normalized < 95.0:
		return Type.CORRUPTED
	return Type.LOST


static func label(stage: Type) -> String:
	match stage:
		Type.PURE:
			return "pure"
		Type.TAINTED:
			return "tainted"
		Type.BREAKING:
			return "breaking"
		Type.SUBMISSIVE:
			return "submissive"
		Type.CORRUPTED:
			return "corrupted"
		Type.LOST:
			return "lost"
	return "pure"


static func from_label(value: String) -> Type:
	match value.strip_edges().to_lower():
		"tainted":
			return Type.TAINTED
		"breaking":
			return Type.BREAKING
		"submissive":
			return Type.SUBMISSIVE
		"corrupted":
			return Type.CORRUPTED
		"lost":
			return Type.LOST
	return Type.PURE
