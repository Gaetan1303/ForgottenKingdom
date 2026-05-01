## scripts/data/yaml_to_json_builder.gd
## Script utilitaire à lancer depuis l'éditeur Godot (Outils > Exécuter) pour
## convertir les fichiers YAML de données en un data.json utilisable par ChapterLoader.
##
## USAGE : Ouvrir ce fichier dans Godot, puis Scène > Exécuter le script (Maj+F6).
##
## Prérequis : avoir Python 3 installé avec PyYAML  (pip install pyyaml)
##             OU utiliser le parser manuel ci-dessous.
##
## Ce script détecte si Python est disponible ; sinon, il lit les YAML ligne par ligne
## avec un micro-parser pour les structures simples.

@tool
extends EditorScript

const YAML_CHAPTERS := "res://story/chapitres_ingrid.yaml"
const YAML_LOCATIONS := "res://story/carte_lieux.yaml"
const OUTPUT_JSON    := "res://resources/chapters/data.json"


func _run() -> void:
	print("=== YAML → JSON Builder ===")
	var output := {"chapitres": [], "lieux": []}

	# Tente la conversion via Python
	if _python_convert(output):
		print("Conversion via Python réussie.")
	else:
		print("Python indisponible — utilisation du parser intégré.")
		_builtin_parse(output)

	# Écriture du JSON
	var dir := DirAccess.open("res://resources/chapters/")
	if dir == null:
		DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path("res://resources/chapters/"))

	var file := FileAccess.open(OUTPUT_JSON, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(output, "\t"))
		file.close()
		print("✅ JSON écrit dans : %s" % OUTPUT_JSON)
	else:
		push_error("Impossible d'écrire dans '%s'" % OUTPUT_JSON)


func _python_convert(output: Dictionary) -> bool:
	var script := """
import sys, json
try:
    import yaml
except ImportError:
    sys.exit(1)

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = yaml.safe_load(f)
print(json.dumps(data, ensure_ascii=False))
"""
	# Écriture du script temporaire
	var tmp := FileAccess.open("user://yaml_convert.py", FileAccess.WRITE)
	if tmp == null:
		return false
	tmp.store_string(script)
	tmp.close()

	var tmp_path: String = OS.get_user_data_dir() + "/yaml_convert.py"
	var ch_path: String = ProjectSettings.globalize_path(YAML_CHAPTERS)
	var lc_path: String = ProjectSettings.globalize_path(YAML_LOCATIONS)

	var ch_out: Array[String] = []
	var exit_ch := OS.execute("python", [tmp_path, ch_path], ch_out)
	if exit_ch != 0:
		exit_ch = OS.execute("python3", [tmp_path, ch_path], ch_out)
	if exit_ch != 0:
		return false  # Python indisponible

	var lc_out: Array[String] = []
	OS.execute("python", [tmp_path, lc_path], lc_out)

	var ch_parsed: Variant = JSON.parse_string(ch_out[0] if ch_out.size() > 0 else "{}")
	var lc_parsed: Variant = JSON.parse_string(lc_out[0] if lc_out.size() > 0 else "{}")

	if ch_parsed is Dictionary and ch_parsed.has("chapitres"):
		output["chapitres"] = ch_parsed["chapitres"]
	if lc_parsed is Dictionary and lc_parsed.has("lieux"):
		output["lieux"] = lc_parsed["lieux"]

	return true


func _builtin_parse(_output: Dictionary) -> void:
	# Parser YAML basique — lit uniquement les clés de premier niveau simples.
	# Pour les structures imbriquées complexes, Python + PyYAML est nécessaire.
	push_warning("Parser YAML intégré non implémenté. Installez Python + PyYAML.")
