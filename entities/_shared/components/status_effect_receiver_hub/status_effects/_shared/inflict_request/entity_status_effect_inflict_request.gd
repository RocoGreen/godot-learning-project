class_name EntityStatusEffectInflictRequest
extends RefCounted


var inflict_source: EntityStatusEffectInflictSource;
var inflicter_entity: PhysicsBody3D;


func _init(
		parameter_inflict_source: EntityStatusEffectInflictSource, 
		parameter_inflicter_entity: PhysicsBody3D,
) -> void:
	if parameter_inflict_source:
		inflict_source = parameter_inflict_source;

	if parameter_inflicter_entity:
		if EntityComponent.is_entity(parameter_inflicter_entity):
			inflicter_entity = parameter_inflicter_entity;


func is_valid() -> bool:
	if not inflict_source:
		return false;

	if not inflicter_entity:
		return false;

	if not EntityComponent.is_entity(inflicter_entity):
		return false;

	return true;
