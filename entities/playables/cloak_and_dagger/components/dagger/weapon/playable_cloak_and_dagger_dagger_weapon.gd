class_name PlayableCloakAndDaggerDaggerWeapon
extends Node3D


@export_group("Dependencies")
@export var playable_cloak_and_dagger: PlayableCloakAndDagger;
@export var playable_cloak_and_dagger_identity: PlayableCloakAndDaggerIdentity;
@export var camera_component: PlayableCameraComponent;

@export_group("Weapon Settings")
@export var fire_rate_per_second: float = 2.27;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_fire: StringName = &"primary_fire";

@export_group("Dagger Settings")
@export var dagger_healing_amount_per_entity_hit: float = 15.0;
@export var dagger_damage_amount_per_entity_hit: float = 18.0;
@export var dagger_travel_speed_in_meters_per_second: float = 20.0;

@export_subgroup("Impact Explosion")
@export var dagger_impact_explosion_healing_amount: float = 20.0;
@export var dagger_impact_explosion_spherical_hitbox_radius_meters: float = 8.0;

var _in_recovery_for_next_shot: bool = false;


func _ready() -> void:
	%RayCast3DToCheckIfCameraSeesEntityModelCenter.add_exception(playable_cloak_and_dagger);


func _physics_process(_delta: float) -> void:
	if not playable_cloak_and_dagger.is_dagger_currently_played(): return;
	if not Input.is_action_pressed(input_action_to_fire): return;
	if _in_recovery_for_next_shot: return;

	_create_then_launch_dagger_towards_entity_player_aims_at();
	
	_in_recovery_for_next_shot = true;
	await get_tree().create_timer(0.5).timeout;
	_in_recovery_for_next_shot = false;


func _create_then_launch_dagger_towards_entity_player_aims_at() -> void:
	var entity_aimed_at_center_position_anchor: Marker3D = \
			_get_entity_to_launch_dagger_at();

	if not entity_aimed_at_center_position_anchor: return;

	var dagger := PlayableCloakAndDaggerDaggerWeaponDagger.create(
			playable_cloak_and_dagger.global_position,
			camera_component.get_position_to_look_at_aim_direction(),
			dagger_healing_amount_per_entity_hit,
			dagger_impact_explosion_healing_amount,
			dagger_travel_speed_in_meters_per_second,
			entity_aimed_at_center_position_anchor,
			playable_cloak_and_dagger,
			playable_cloak_and_dagger_identity,
	);

	add_child(dagger);

	dagger.launch();


func _get_entity_player_aims_at_center_position_anchor() -> Marker3D:
	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();

	if ray_to_get_what_player_aims_at_results.is_empty():
		return null;

	var what_is_aimed_at: Object = ray_to_get_what_player_aims_at_results.get("collider");

	if not EntityComponent.is_object_an_entity(what_is_aimed_at): 
		return null;

	var entity_aimed_at: PhysicsBody3D = EntityComponent.cast_object_to_entity(what_is_aimed_at);

	var entity_aimed_at_position_anchor_hub_component: EntityPositionAnchorHubComponent = \
			EntityPositionAnchorHubComponent.from_entity(entity_aimed_at);

	if not entity_aimed_at_position_anchor_hub_component:
		return null;

	var entity_aimed_at_center_position_anchor: Marker3D = \
			entity_aimed_at_position_anchor_hub_component.center_anchor;

	if not entity_aimed_at_center_position_anchor:
		return null;

	return entity_aimed_at_center_position_anchor;


func _get_entity_to_launch_dagger_at() -> Marker3D:
	var entities_visible_on_screen: Array[PhysicsBody3D] = \
			EntityVisibleOnScreenNotifierComponent.get_entities_visible_on_screen(get_tree());

	var entity_to_launch_at: PhysicsBody3D;
	var entity_to_launch_at_model_center_position_anchor_marker_3d: Marker3D;
	var angle_between_player_crosshair_and_entity_to_launch_at_model_center: float;

	for candidate_entity: PhysicsBody3D in entities_visible_on_screen:
		if candidate_entity == playable_cloak_and_dagger:
			continue;

		var candidate_entity_position_anchor_hub_component: EntityPositionAnchorHubComponent = \
				EntityPositionAnchorHubComponent.from_entity(candidate_entity);

		if not candidate_entity_position_anchor_hub_component:
			continue;

		var player_camera: Camera3D = camera_component._camera;
		var player_camera_global_position: Vector3 = player_camera.global_position;
		var player_camera_forward_vector: Vector3 = -player_camera.global_basis.z.normalized();
		
		var candidate_entity_model_center_global_position: Vector3 = \
				candidate_entity_position_anchor_hub_component.center_anchor.global_position;

		var angle_between_player_crosshair_and_candidate_entity_model_center: float = \
				player_camera_forward_vector.dot(
					player_camera_global_position.direction_to(
							candidate_entity_model_center_global_position,
					)
				);

		var candidate_entity_model_center_is_too_far_from_player_crosshair: bool = \
				angle_between_player_crosshair_and_candidate_entity_model_center < 0.97;

		if candidate_entity_model_center_is_too_far_from_player_crosshair:
			continue;

		if entity_to_launch_at:
			if (
					angle_between_player_crosshair_and_candidate_entity_model_center \
					<= \
					angle_between_player_crosshair_and_entity_to_launch_at_model_center
			):
				continue;

		entity_to_launch_at = candidate_entity;

		entity_to_launch_at_model_center_position_anchor_marker_3d = \
				candidate_entity_position_anchor_hub_component.center_anchor;

		angle_between_player_crosshair_and_entity_to_launch_at_model_center = \
				angle_between_player_crosshair_and_candidate_entity_model_center;

	if not entity_to_launch_at:
		return null;

	%RayCast3DToCheckIfCameraSeesEntityModelCenter.look_at_from_position(
			playable_cloak_and_dagger.global_position,
			entity_to_launch_at_model_center_position_anchor_marker_3d.global_position,
	);

	%RayCast3DToCheckIfCameraSeesEntityModelCenter.force_raycast_update();

	var camera_sees_entity_model_center: bool = false;

	while(%RayCast3DToCheckIfCameraSeesEntityModelCenter.is_colliding()):
		var ray_collider: Object = %RayCast3DToCheckIfCameraSeesEntityModelCenter.get_collider();

		if ray_collider is not PhysicsBody3D:
			break;

		if not EntityComponent.is_object_an_entity(ray_collider):
			break;

		if ray_collider == entity_to_launch_at:
			camera_sees_entity_model_center = true;
			break;

		%RayCast3DToCheckIfCameraSeesEntityModelCenter.add_exception(ray_collider);
		%RayCast3DToCheckIfCameraSeesEntityModelCenter.force_raycast_update();

	%RayCast3DToCheckIfCameraSeesEntityModelCenter.clear_exceptions();
	%RayCast3DToCheckIfCameraSeesEntityModelCenter.add_exception(playable_cloak_and_dagger);

	if camera_sees_entity_model_center:
		return entity_to_launch_at_model_center_position_anchor_marker_3d;
	else:
		return null;
