## Factory — returns the correct animated card for a given class_id.
## Follows Dependency Inversion: the slide depends on this abstraction, not concrete cards.
class_name ClassCardFactory


static func create(class_id: String, icon: String = "") -> BaseClassCard:
	var card: BaseClassCard
	match class_id:
		"demon_blade":        card = DemonBladeCard.new()
		"hellcaster":         card = HellcasterCard.new()
		"shadowfang":         card = ShadowfangCard.new()
		"soulwarden":         card = SoulwardenCard.new()
		"hellranger":         card = HellrangerCard.new()
		"abyss_paladin":      card = AbyssPaladinCard.new()
		"pactbound":          card = PactboundCard.new()
		"echo_bard":          card = EchoBardCard.new()
		"berserker_demon":    card = BerserkerDemonCard.new()
		"void_monk":          card = VoidMonkCard.new()
		"wild_druid":         card = WildDruidCard.new()
		"blood_sorcerer":     card = BloodSorcererCard.new()
		"infernal_artificer": card = InfernalArtificerCard.new()
		"warlord":            card = WarlordCard.new()
		_:                    card = BaseClassCard.new()
	card.icon_path = icon
	card.class_id_key = class_id
	return card
