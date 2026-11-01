class_name EntityHealthHealingRequest
extends RefCounted


var amount: float;
var heal_any_entity: bool = false;

var source: EntityHealthHealingSource;
var healer_entity: PhysicsBody3D;


func _init(
		parameter_amount: float, 
		parameter_source: EntityHealthHealingSource,
		parameter_healer_entity: PhysicsBody3D,
		parameter_heal_any_entity: bool,
) -> void:
	if parameter_amount:
		amount = parameter_amount;

	if parameter_source:
		source = parameter_source;

	if parameter_healer_entity:
		if EntityComponent.is_entity(parameter_healer_entity):
			healer_entity = parameter_healer_entity;

	if parameter_heal_any_entity:
		heal_any_entity = parameter_heal_any_entity;


func is_valid() -> bool:
	if amount <= 0.0:
		return false;

	if not source:
		return false;

	if not healer_entity:
		return false;

	if not EntityComponent.is_entity(healer_entity):
		return false;

	return true;
