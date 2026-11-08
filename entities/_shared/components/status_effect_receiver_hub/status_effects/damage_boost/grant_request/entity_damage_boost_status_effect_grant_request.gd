class_name EntityDamageBoostStatusEffectGrantRequest
extends EntityStatusEffectGrantRequest


var how_much_in_percentage: int = 0:
		set(new_how_much_in_percentage):
			how_much_in_percentage = clampi(new_how_much_in_percentage, 0, 100);


func _init(
		parameter_how_much_in_percentage: int,

		parameter_grant_source: EntityStatusEffectGrantSource, 
		parameter_granter_entity: PhysicsBody3D,
) -> void:
	super(parameter_grant_source, parameter_granter_entity);

	if parameter_how_much_in_percentage:
		how_much_in_percentage = parameter_how_much_in_percentage;


func is_valid() -> bool:
	if super() == false:
		return false;

	if how_much_in_percentage <= 0:
		return false;

	return true;
