## Contrat commun aux exercices et aux actions du présent. Un refus n'a aucun effet.
extends RefCounted

var accepted: bool = false
var succeeded: bool = false
var event: String = ""
var message: String = ""
var route: String = ""
var cost: Dictionary = {}
var gains: Dictionary = {}
var corruption: float = 0.0
var next_state: Dictionary = {}
