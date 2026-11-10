class_name EntityDamageReceivedReductionStatusEffectGrantRequest
extends EntityStatusEffectGrantRequest


var how_much_in_percentage: int = 0:
	set(new_how_much_in_percentage):
		how_much_in_percentage = clampi(new_how_much_in_percentage, 0, 100);

var duration_seconds: float = 0.0:
	set(new_duration_seconds):
		duration_seconds = maxf(0.0, new_duration_seconds);


func _init(
		parameter_how_much_in_percentage: int,

		parameter_grant_source: EntityStatusEffectGrantSource, 
		parameter_granter_entity: PhysicsBody3D,

		parameter_duration_seconds: float = -1.0,
) -> void:
	super._init(parameter_grant_source, parameter_granter_entity);

	if parameter_how_much_in_percentage:
		how_much_in_percentage = parameter_how_much_in_percentage;

	if parameter_duration_seconds >= 0.0:
		duration_seconds = parameter_duration_seconds;


func is_valid() -> bool:
	if super.is_valid() == false:
		return false;

	if how_much_in_percentage <= 0:
		return false;

	if duration_seconds < 0.0:
		return false;

	return true;
