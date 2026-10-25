extends Node3D


@export_group("Dependencies")
@export var playable_cloak_and_dagger: PlayableCloakAndDagger;
@export var playable_cloak_and_dagger_identity: PlayableCloakAndDaggerIdentity;

@export var camera_component: PlayableCameraComponent;
@export var veil_deploy_start_position_anchor_marker_3d: Marker3D;

@export_group("Veil Deployment Settings")
@export var time_seconds_to_start_veil_deployment: float = 1.0;

@export_custom(PROPERTY_HINT_INPUT_NAME, "") 
var input_action_to_deploy_veil: StringName = &"ability_2"; 

@export_group("Veil Settings")
@export_subgroup("Veil Traveling Settings")
@export var veil_travel_speed_in_meters_per_second: float = 20.0;
@export var veil_travel_distance_meters: float = 25.0;

@export_subgroup("Veil Healing And Amplification")
@export var veil_healing_per_entity_hit: float = 50.0;
@export_range(0, 100) var veil_healing_amplification_percentage: int = 20;
@export var veil_healing_amplification_duration_seconds: float = 4.0;

@export_subgroup("Veil Size")
@export var veil_width_size_meters: float = 6.0;
@export var veil_height_size_meters: float = 4.5;

var _veil_currently_traveling: PlayableCloakAndDaggerDaggerLightExplosionAbilityVeil;

@onready var time_to_start_deployment_timer: Timer = %TimeToStartDeploymentTimer;


func _physics_process(_delta: float) -> void:
	if not playable_cloak_and_dagger.is_dagger_currently_played(): return;

	if not Input.is_action_just_pressed(input_action_to_deploy_veil): return;
	if not time_to_start_deployment_timer.is_stopped(): return;

	if _veil_currently_traveling:
		_veil_currently_traveling.queue_free();

	time_to_start_deployment_timer.start(time_seconds_to_start_veil_deployment);


func _create_veil_and_get_it() -> PlayableCloakAndDaggerDaggerLightExplosionAbilityVeil:
	var veil := PlayableCloakAndDaggerDaggerLightExplosionAbilityVeil.create(
			veil_healing_per_entity_hit,
			veil_healing_amplification_percentage,
			veil_healing_amplification_duration_seconds,
			veil_width_size_meters,
			veil_height_size_meters,
			playable_cloak_and_dagger,
			playable_cloak_and_dagger_identity,
	);

	return veil;


func _deploy_veil() -> void:
	var veil: PlayableCloakAndDaggerDaggerLightExplosionAbilityVeil = _create_veil_and_get_it();

	# Note: The veil needs to be added as a child before using it's launch() method.
	add_child(veil);

	# Global position to deploy at.
	var where_to_deploy_at: Vector3 = camera_component.get_position_to_look_at_aim_direction();

	$MeshInstance3D.global_position = where_to_deploy_at;
	$MeshInstance3D.show();

	veil.launch(
			veil_deploy_start_position_anchor_marker_3d.global_position,
			where_to_deploy_at,
			veil_travel_speed_in_meters_per_second,
			false,
			0.0,
			veil_travel_distance_meters,
	);

	_veil_currently_traveling = veil;


func _on_time_to_start_deployment_timer_timeout() -> void:
	_deploy_veil();
