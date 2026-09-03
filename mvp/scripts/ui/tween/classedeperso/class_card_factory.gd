## Factory — returns the correct animated card for a given class_id.
## Explicit preloads keep card creation independent from the editor class cache.
class_name ClassCardFactory
extends RefCounted

const BaseClassCardClass = preload("res://scripts/ui/tween/classedeperso/base_class_card.gd")
const DemonBladeCardClass = preload("res://scripts/ui/tween/classedeperso/demon_blade_card.gd")
const HellcasterCardClass = preload("res://scripts/ui/tween/classedeperso/hellcaster_card.gd")
const ShadowfangCardClass = preload("res://scripts/ui/tween/classedeperso/shadowfang_card.gd")
const SoulwardenCardClass = preload("res://scripts/ui/tween/classedeperso/soulwarden_card.gd")
const HellrangerCardClass = preload("res://scripts/ui/tween/classedeperso/hellranger_card.gd")
const AbyssPaladinCardClass = preload("res://scripts/ui/tween/classedeperso/abyss_paladin_card.gd")
const PactboundCardClass = preload("res://scripts/ui/tween/classedeperso/pactbound_card.gd")
const EchoBardCardClass = preload("res://scripts/ui/tween/classedeperso/echo_bard_card.gd")
const BerserkerDemonCardClass = preload("res://scripts/ui/tween/classedeperso/berserker_demon_card.gd")
const VoidMonkCardClass = preload("res://scripts/ui/tween/classedeperso/void_monk_card.gd")
const WildDruidCardClass = preload("res://scripts/ui/tween/classedeperso/wild_druid_card.gd")
const BloodSorcererCardClass = preload("res://scripts/ui/tween/classedeperso/blood_sorcerer_card.gd")
const InfernalArtificerCardClass = preload("res://scripts/ui/tween/classedeperso/infernal_artificer_card.gd")
const WarlordCardClass = preload("res://scripts/ui/tween/classedeperso/warlord_card.gd")

static func create(class_id: String, icon: String = "") -> Button:
	var card: Button
	match class_id:
		"demon_blade":        card = DemonBladeCardClass.new()
		"hellcaster":         card = HellcasterCardClass.new()
		"shadowfang":         card = ShadowfangCardClass.new()
		"soulwarden":         card = SoulwardenCardClass.new()
		"hellranger":         card = HellrangerCardClass.new()
		"abyss_paladin":      card = AbyssPaladinCardClass.new()
		"pactbound":          card = PactboundCardClass.new()
		"echo_bard":          card = EchoBardCardClass.new()
		"berserker_demon":    card = BerserkerDemonCardClass.new()
		"void_monk":          card = VoidMonkCardClass.new()
		"wild_druid":         card = WildDruidCardClass.new()
		"blood_sorcerer":     card = BloodSorcererCardClass.new()
		"infernal_artificer": card = InfernalArtificerCardClass.new()
		"warlord":            card = WarlordCardClass.new()
		_:                    card = BaseClassCardClass.new()
	card.set("icon_path", icon)
	card.set("class_id_key", class_id)
	return card
