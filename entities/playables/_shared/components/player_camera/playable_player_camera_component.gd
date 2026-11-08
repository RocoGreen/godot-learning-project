@tool
class_name PlayablePlayerCameraComponent
extends Marker3D
## [b]TODO[/b]: May have to check if the script is easy enough to be understood by others.


@export_group("Dependencies")
@export var playable: CharacterBody3D:
	set(new_playable):
		playable = new_playable;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Settings")
@export var following_smoothness: float = 0.5;

@onready var _camera_3d: Camera3D = %Camera;
@onready var _camera_pivot_spring_arm_3d: SpringArm3D = %CameraPivot;


func _ready() -> void:
	if Engine.is_editor_hint():
		_camera_pivot_spring_arm_3d.set_as_top_level(false);
		_camera_pivot_spring_arm_3d.global_transform = global_transform;

	else:
		_camera_pivot_spring_arm_3d.add_excluded_object(playable.get_rid());


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;

	_camera_pivot_spring_arm_3d.global_transform = \
			_camera_pivot_spring_arm_3d.global_transform.interpolate_with(
					global_transform,
					following_smoothness
			);


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLibrary.get_for_playable(playable);


## The [Dictionary] returned is the same as the one returned from the method
## [method PhysicsDirectSpaceState3D.intersect_ray].
func ray_to_hit_an_object_aimed_at(
		ray_collision_mask: int = CollisionMaskLibrary.get_entities_and_obstacles(),
		exclude_playable_from_ray: bool = true,
		ray_exclusions_by_object_rid: Array[RID] = [],
) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().get_direct_space_state();

	var ray_start: Vector3 = _camera_3d.get_global_position();
	var camera_forward_vector: Vector3 = -_camera_3d.global_basis.z.normalized();
	var ray_length: float = 1000.0;
	var ray_end: Vector3 = ray_start + (camera_forward_vector * ray_length);

	if exclude_playable_from_ray:
		ray_exclusions_by_object_rid.append(playable.get_rid());

	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			ray_start, 
			ray_end,
			ray_collision_mask,
			ray_exclusions_by_object_rid,
	);

	var ray_results: Dictionary = space_state.intersect_ray(ray_query);

	return ray_results;


func get_position_to_point_at_aim_direction(
		fallback_only: bool = false,
		ray_collision_mask: int = CollisionMaskLibrary.get_entities_and_obstacles(),
		exclude_entity_from_ray: bool = true,
		ray_exclusions_by_object_rid: Array[RID] = [],
) -> Vector3:
	var camera_forward_vector: Vector3 = -_camera_3d.global_basis.z.normalized();

	var position_to_point_at_aim_direction: Vector3 = \
			_camera_3d.global_position + (camera_forward_vector * 1000.0);

	if not fallback_only:
		var ray_to_hit_an_object_aimed_at_results: Dictionary = ray_to_hit_an_object_aimed_at(
				ray_collision_mask,
				exclude_entity_from_ray,
				ray_exclusions_by_object_rid,
		);

		if not ray_to_hit_an_object_aimed_at_results.is_empty():
			position_to_point_at_aim_direction = ray_to_hit_an_object_aimed_at_results.position;

	return position_to_point_at_aim_direction;


func get_entity_closest_to_view_center(
		maximum_angle_degrees: float = 180.0,
		exclude_playable: bool = true,
		excluded_entities: Array[PhysicsBody3D] = [],
) -> PhysicsBody3D:
	if maximum_angle_degrees < 0.0:
		maximum_angle_degrees = 0.0;

	if maximum_angle_degrees > 180.0:
		maximum_angle_degrees = 180.0;

	var closest_entity: PhysicsBody3D;
	var angle_between_view_center_and_closest_entity: float;

	var entities_in_view: Array[PhysicsBody3D] = \
			EntityVisibleOnScreenNotifierComponent.get_entities_visible_on_screen(get_tree());

	for entity_in_view: PhysicsBody3D in entities_in_view:
		if exclude_playable and entity_in_view == playable:
			continue;

		if excluded_entities.has(entity_in_view):
			continue;

		var entity_in_view_model_center_position_anchor: Marker3D = \
				EntityPositionAnchorHubComponent.get_entity_model_center_anchor(entity_in_view);

		if not entity_in_view_model_center_position_anchor:
			continue;

		var entity_model_center_global_position: Vector3 = \
				entity_in_view_model_center_position_anchor.global_position;

		var camera_forward_vector: Vector3 = -_camera_3d.global_basis.z.normalized();
		var angle_between_view_center_and_entity_in_view: float = \
				camera_forward_vector.dot(
						_camera_3d.global_position.direction_to(entity_model_center_global_position)
				);

		if angle_between_view_center_and_entity_in_view < cos(deg_to_rad(maximum_angle_degrees)):
			continue;

		if angle_between_view_center_and_entity_in_view < angle_between_view_center_and_closest_entity:
			continue;

		closest_entity = entity_in_view;
		angle_between_view_center_and_closest_entity = angle_between_view_center_and_entity_in_view;

	if closest_entity:
		return closest_entity;
	else:
		return null;
