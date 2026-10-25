class_name PlayableCloakAndDaggerDaggerStormAbilityComponent
extends Node3D


@export_group("Dependencies")
@export var playable_cloak_and_dagger: PlayableCloakAndDagger;
@export var playable_cloak_and_dagger_identity: PlayableCloakAndDaggerIdentity;

@export var camera_component: PlayableCameraComponent;
## [b]NOTE[/b]: If not obvious, this [Marker3D] is used to know where 
## [PlayableCloakAndDaggerDaggerStormAbilityValleyOfDaggers] should spawn by
## using it's [member Node3D.global_position]. 
@export var position_to_spawn_valley_of_daggers_anchor_marker_3d: Marker3D;

@export_group("Valley of Daggers Settings")
@export var valley_of_daggers_travel_speed_in_meters_per_second: float = 50.0;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") 
var input_action_to_launch_valley_of_daggers: StringName = &"secondary_fire";

@export_group("Spell Field Settings")
@export var spell_field_burst_heal_amount_on_spawn: float = 60.0;
@export var spell_field_healing_amount_per_second: float = 50.0;
@export var spell_field_duration_seconds: float = 6.0;
@export var spell_field_spherical_hitbox_radius_meters: float = 5.0;

var _valley_of_daggers_currently_traveling: PlayableCloakAndDaggerDaggerStormAbilityValleyOfDaggers;
var _spell_field_currently_spawned: PlayableCloakAndDaggerDaggerStormAbilitySpellField;


func _physics_process(_delta: float) -> void:
	if not playable_cloak_and_dagger.is_dagger_currently_played(): return;
	if not Input.is_action_just_pressed(input_action_to_launch_valley_of_daggers): return;
	if _valley_of_daggers_currently_traveling or _spell_field_currently_spawned: return;

	_create_then_launch_valley_of_daggers();


func _create_then_launch_valley_of_daggers() -> void:
	var valley_of_daggers := PlayableCloakAndDaggerDaggerStormAbilityValleyOfDaggers.create(
			playable_cloak_and_dagger,
	);

	valley_of_daggers.collided.connect(_on_valley_of_daggers_collided);

	add_child(valley_of_daggers);

	var where_to_launch_at: Vector3 = camera_component.get_position_to_look_at_aim_direction();

	valley_of_daggers.launch(
			_get_global_position_to_spawn_valley_of_daggers(),
			where_to_launch_at,
			valley_of_daggers_travel_speed_in_meters_per_second,
	);

	_valley_of_daggers_currently_traveling = valley_of_daggers;


func _create_then_spawn_spell_field(global_position_to_spawn: Vector3) -> void:
	var spell_field := PlayableCloakAndDaggerDaggerStormAbilitySpellField.create(
			spell_field_burst_heal_amount_on_spawn,
			spell_field_healing_amount_per_second,
			spell_field_duration_seconds,
			spell_field_spherical_hitbox_radius_meters,
			playable_cloak_and_dagger_identity,
	);

	add_child(spell_field);

	spell_field.spawn(global_position_to_spawn);

	_spell_field_currently_spawned = spell_field;


func _get_global_position_to_spawn_valley_of_daggers() -> Vector3:
	return position_to_spawn_valley_of_daggers_anchor_marker_3d.global_position;


func _on_valley_of_daggers_collided(_collision: KinematicCollision3D) -> void:
	_create_then_spawn_spell_field(_valley_of_daggers_currently_traveling.global_position);
