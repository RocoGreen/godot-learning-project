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
		ray_collision_mask: int,
		exclude_playable_from_ray: bool = true,
		ray_exclusions_by_object_rid: Array[RID] = [],
) -> Dictionary:
	if not ray_collision_mask:
		return {};

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

	var ray_info: Dictionary = space_state.intersect_ray(ray_query);
	
	if not ray_info.is_empty():
		return ray_info;
	else:
		return {};


## The [Dictionary] returned is the same as the one returned from the method
## [method PhysicsDirectSpaceState3D.intersect_ray].
func ray_to_hit_an_unobstructed_entity_aimed_at(
		exclude_playable_from_ray: bool = true,
		excluded_entities_by_rid_from_ray: Array[RID] = [],
) -> Dictionary:
	var ray_to_hit_an_object_aimed_at_info: Dictionary = ray_to_hit_an_object_aimed_at(
			CollisionMaskLibrary.get_entities_and_obstacles(),
			exclude_playable_from_ray,
			excluded_entities_by_rid_from_ray,
	);

	if ray_to_hit_an_object_aimed_at_info.is_empty(): 
		return {};

	var ray_collider: Object = ray_to_hit_an_object_aimed_at_info.get("collider");

	if not EntityComponent.is_object_an_entity(ray_collider):
		return {};

	return ray_to_hit_an_object_aimed_at_info;


func get_position_to_point_at_aim_direction() -> Vector3:
	var camera_forward_vector: Vector3 = -_camera_3d.global_basis.z.normalized();
	return _camera_3d.global_position + (camera_forward_vector * 1000.0);
