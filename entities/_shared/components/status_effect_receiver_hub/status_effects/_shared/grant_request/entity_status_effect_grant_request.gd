class_name EntityStatusEffectGrantRequest
extends RefCounted


var grant_source: EntityStatusEffectGrantSource;
var granter_entity: PhysicsBody3D;


func _init(
		parameter_grant_source: EntityStatusEffectGrantSource, 
		parameter_granter_entity: PhysicsBody3D,
) -> void:
	if parameter_grant_source:
		grant_source = parameter_grant_source;

	if parameter_granter_entity:
		if EntityComponent.is_entity(parameter_granter_entity):
			granter_entity = parameter_granter_entity;


func is_valid() -> bool:
	if not grant_source:
		return false;

	if not granter_entity:
		return false;

	if not EntityComponent.is_entity(granter_entity):
		return false;

	return true;
