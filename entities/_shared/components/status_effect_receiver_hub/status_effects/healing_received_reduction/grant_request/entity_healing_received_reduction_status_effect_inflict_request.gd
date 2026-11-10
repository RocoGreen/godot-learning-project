class_name EntityHealingReceivedReductionStatusEffectInflictRequest
extends EntityStatusEffectInflictRequest


var how_much_in_percentage: int = 0:
	set(new_how_much_in_percentage):
		how_much_in_percentage = clampi(new_how_much_in_percentage, 0, 100);

var duration_seconds: float = 0.0:
	set(new_duration_seconds):
		duration_seconds = maxf(0.0, new_duration_seconds); 


func _init(
		parameter_how_much_in_percentage: int,

		parameter_inflict_source: EntityStatusEffectInflictSource, 
		parameter_inflicter_entity: PhysicsBody3D,

		parameter_duration_seconds: float = -1.0,
) -> void:
	super._init(parameter_inflict_source, parameter_inflicter_entity);

	if parameter_how_much_in_percentage:
		how_much_in_percentage = parameter_how_much_in_percentage;

	if parameter_duration_seconds > 0.0:
		duration_seconds = parameter_duration_seconds;


func is_valid() -> bool:
	if super.is_valid() == false:
		return false;

	if how_much_in_percentage <= 0:
		return false;

	return true;
