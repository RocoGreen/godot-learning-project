class_name EntityHealthDamageRequest
extends RefCounted


var amount: float;
var damage_any_entity: bool = false;

var source: EntityHealthDamageSource;
var attacker_entity_identity: EntityIdentity;


func _init(
		parameter_amount: float, 
		parameter_source: EntityHealthDamageSource,
		parameter_attacker_entity_identity: EntityIdentity,
		parameter_damage_any_entity: bool,
) -> void:
	if parameter_amount:
		amount = parameter_amount;

	if parameter_source:
		source = parameter_source;

	if parameter_attacker_entity_identity:
		attacker_entity_identity = parameter_attacker_entity_identity;

	if parameter_damage_any_entity:
		damage_any_entity = parameter_damage_any_entity;


func is_valid() -> bool:
	if amount <= 0.0:
		return false;

	if not source:
		return false;

	if not attacker_entity_identity:
		return false;

	return true;
