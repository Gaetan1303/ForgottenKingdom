## Contrats partagés par les systèmes de corruption, créatures et pactes.
class_name FKEnums
extends RefCounted

enum CorruptionStage { PURE, TAINTED, BREAKING, SUBMISSIVE, CORRUPTED, LOST }
enum TrainingType { NONE, SEDUCTION, ENDURANCE, OBEDIENCE, PLEASURE_GIVING, PLEASURE_RECEIVING, HUMILIATION, BREEDING, SUBMISSION, DOMINATION, EXHIBITION, RESTRICTION, ORAL, ANAL, PET_PLAY, SERVICE }
enum AssignmentType { IDLE, TRAINING, SERVICE_CLIENT, SERVICE_CREATURE, BREEDING, DISCIPLINE, CONFINEMENT, REST }
enum CreatureType { LESSER_DEMON, SUCCUBUS, INCUBUS, MIND_FLAYER, TENTACLE_BEAST, DEMON_NOBLE, CORRUPTED_HERO, BEASTMAN, SLIME, SHADOW_DEMON, VAMPIRE_LORD }
enum CreatureRole { CORRUPTER, TRAINER, BREEDER, DISCIPLINARIAN, GUARD, ENTERTAINER, EXTRACTOR, HUNTER }
enum CreatureCapability { CORRUPTION_AURA, DOMINATION_GAZE, TELEPATHY, SHAPESHIFTING, TENTACLE_BIND, POISON_STING, ILLUSION, PHEROMONES, MAGIC_BINDING }
enum PactType { NONE, SERVICE, BOND, SOUL_CONTRACT, BREEDING_PACT, COMBAT_ALLIANCE }
enum ExperienceType { VAGINAL, ANAL, ORAL, DOMINANT, SUBMISSIVE, GROUP, BONDAGE, EXHIBITION, FETISH, FIRST_TIME }


static func is_valid_training_type(value: int) -> bool:
	return value >= TrainingType.NONE and value <= TrainingType.SERVICE


static func is_valid_assignment_type(value: int) -> bool:
	return value >= AssignmentType.IDLE and value <= AssignmentType.REST


static func is_valid_pact_type(value: int) -> bool:
	return value >= PactType.NONE and value <= PactType.COMBAT_ALLIANCE
