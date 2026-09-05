## Identité technique stable d'un clan, indépendante de son libellé affiché.
class_name ClanIdentity
extends RefCounted


static func id_from_name(clan_name: String) -> String:
	var normalized_name := clan_name.strip_edges().to_lower()
	if normalized_name.is_empty():
		return ""
	return "clan_%s" % normalized_name.sha256_text().substr(0, 16)
