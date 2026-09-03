extends CharacterBody3D


@export var test_character_1_identity: EntityIdentity;
@export var health_component: EntityHealthComponent;


var _already_awaiting_for_self_regen_timeout: bool = false;
var _self_regen_active: bool = false;


func _process(delta: float) -> void:
	if _self_regen_active and health_component.current_health >= health_component.max_health:
		_self_regen_active = false;

	elif health_component.current_health < health_component.max_health:
		if _self_regen_active:
			health_component.heal(50.0 * delta, test_character_1_identity);

		elif _already_awaiting_for_self_regen_timeout:
			return;

		else:
			await get_tree().create_timer(2.0).timeout;

			_already_awaiting_for_self_regen_timeout = false;
			_self_regen_active = true;
