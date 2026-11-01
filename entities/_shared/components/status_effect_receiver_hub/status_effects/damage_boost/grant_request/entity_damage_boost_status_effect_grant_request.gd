class_name EntityDamageBoostStatusEffectGrantRequest
extends RefCounted


var how_much_in_percentage: int = 0:
		set(new_how_much_in_percentage):
			how_much_in_percentage = clampi(new_how_much_in_percentage, 0, 100);

var grant_source: EntityStatusEffectGrantSource;
var granter_entity_identity: EntityIdentity;


func _init(
		parameter_how_much_in_percentage: int,
		parameter_grant_source: EntityStatusEffectGrantSource, 
		parameter_granter_entity_identity: EntityIdentity,
) -> void:
	if parameter_how_much_in_percentage:
		how_much_in_percentage = parameter_how_much_in_percentage;

	if parameter_grant_source:
		grant_source = parameter_grant_source;

	if parameter_granter_entity_identity:
		granter_entity_identity = parameter_granter_entity_identity;
