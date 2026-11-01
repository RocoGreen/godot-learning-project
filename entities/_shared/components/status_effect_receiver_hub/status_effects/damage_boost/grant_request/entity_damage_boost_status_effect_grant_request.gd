class_name EntityDamageBoostStatusEffectGrantRequest
extends RefCounted


var how_much_in_percentage: int = 0:
		set(new_how_much_in_percentage):
			how_much_in_percentage = clampi(new_how_much_in_percentage, 0, 100);

var grant_source: EntityStatusEffectGrantSource;
var granter_entity: PhysicsBody3D;


func _init(
		parameter_how_much_in_percentage: int,
		parameter_grant_source: EntityStatusEffectGrantSource, 
		parameter_granter_entity: PhysicsBody3D,
) -> void:
	if parameter_how_much_in_percentage:
		how_much_in_percentage = parameter_how_much_in_percentage;

	if parameter_grant_source:
		grant_source = parameter_grant_source;

	if parameter_granter_entity:
		if EntityComponent.is_entity(parameter_granter_entity):
			granter_entity = parameter_granter_entity;


func is_valid() -> bool:
	if how_much_in_percentage <= 0:
		return false;

	if not grant_source:
		return false;

	if not granter_entity:
		return false;

	if not EntityComponent.is_entity(granter_entity):
		return false;

	return true;
