## Objectifs narratifs dérivés des accomplissements réels ; aucune file de fenêtres.
extends RefCounted

const STEPS := [
	{"id": "govern", "objective": "Nous sommes encore vivants — choisir la première urgence.", "hint": "Kael : « Le grenier, le mur nord ou les galeries. Nous ne pourrons pas tout régler aujourd’hui. »"},
	{"id": "social", "objective": "Prendre soin de ce qui reste — partager un repas avec Kael.", "hint": "Kael propose de manger avant de reprendre le travail. Il n’y a que vous deux."},
	{"id": "assignment", "objective": "Confier une tâche à une personne du refuge.", "hint": "Comparez ses aptitudes et son état avant de lui confier une réparation ou une sortie."},
	{"id": "salvage", "objective": "Explorer les anciennes galeries et rapporter les outils.", "hint": "Kael a dégagé un escalier. Préparez votre sortie avec elle ; une affectation doit être résolue avant le départ."},
	{"id": "rebuild", "objective": "Remettre l’atelier en service avec les matériaux rapportés.", "hint": "Kael reconnaît ces outils. Réservez 8 bois et 6 fer pour l’atelier."},
	{"id": "soul", "objective": "Examiner la relique dans l’atelier.", "hint": "La Cicatrice de Sang réagit. Kael vous demande de ne pas toucher le métal sans réfléchir."},
]

static func current(state: Dictionary) -> Dictionary:
	var milestones: Array = state.get("milestones", [])
	for step in STEPS:
		if step.id not in milestones:
			return step
	return {"id": "open_world", "objective": "Restaurer la Brèche-Sèche. Découvrir pourquoi votre Maison a été détruite.", "hint": ""}

static func hint(state: Dictionary, key: String, text: String) -> String:
	if int(state.get("help_mode", 0)) != 0:
		return ""
	var seen: Array = state.get("hints_seen", [])
	if key in seen:
		return ""
	seen.append(key)
	state["hints_seen"] = seen
	return text
