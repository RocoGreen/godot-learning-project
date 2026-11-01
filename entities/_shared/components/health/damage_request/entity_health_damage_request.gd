class_name EntityHealthDamageRequest
extends RefCounted


var amount: float;
var damage_any_entity: bool = false;

var source: EntityHealthDamageSource;
var attacker_entity: PhysicsBody3D;


func _init(
		parameter_amount: float, 
		parameter_source: EntityHealthDamageSource,
		parameter_attacker_entity: PhysicsBody3D,
		parameter_damage_any_entity: bool,
) -> void:
	if parameter_amount:
		amount = parameter_amount;

	if parameter_source:
		source = parameter_source;

	if parameter_attacker_entity:
		if EntityComponent.is_entity(parameter_attacker_entity):
			attacker_entity = parameter_attacker_entity;

	if parameter_damage_any_entity:
		damage_any_entity = parameter_damage_any_entity;


func is_valid() -> bool:
	if amount <= 0.0:
		return false;

	if not source:
		return false;

	if not attacker_entity:
		return false;

	if not EntityComponent.is_entity(attacker_entity):
		return false;

	return true;
