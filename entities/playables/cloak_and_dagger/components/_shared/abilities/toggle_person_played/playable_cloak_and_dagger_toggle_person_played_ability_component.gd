class_name PlayableCloakAndDaggerTogglePersonPlayedAbilityComponent
extends Node


@export_group("Dependencies")
@export var playable_cloak_and_dagger: PlayableCloakAndDagger;

@export_group("Settings")
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_toggle: StringName = &"ability_1";


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed(input_action_to_toggle): return;

	playable_cloak_and_dagger.toggle_person_played();
