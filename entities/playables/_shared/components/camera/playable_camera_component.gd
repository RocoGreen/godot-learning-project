@tool

class_name PlayableCameraComponent
extends Marker3D


@export_group("Dependencies")
@export var entity: PhysicsBody3D:
	set(new_entity):
		entity = new_entity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Settings")
@export var following_smoothness: float = 0.5;

@onready var _camera: Camera3D = %Camera;
@onready var _camera_pivot: SpringArm3D = %CameraPivot;


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	AssertLib.assert_if_entity_not_found(entity);

	_camera_pivot.set_as_top_level(true);
	_camera_pivot.add_excluded_object(entity.get_rid());


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;

	_camera_pivot.global_transform = _camera_pivot.global_transform.interpolate_with(
			global_transform,
			following_smoothness
	);


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLib.get_for_entity(entity);


## Note: The returned data (`Dictionary`) containing the results of the intersected ray 
## is the same as `PhysicsDirectSpaceState3D.intersect_ray()` method.
func ray_from_camera_forward(
		ray_collision_mask: int = CollisionMaskLib.get_entities_and_obstacles(),
		exclude_entity_from_ray: bool = true,
		ray_exclusions: Array[RID] = [],
) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().get_direct_space_state();

	var ray_start: Vector3 = _camera.get_global_position();
	var camera_forward_direction: Vector3 = -_camera.global_basis.z.normalized();
	var ray_end: Vector3 = ray_start + (camera_forward_direction * 1000.0);

	var ray_query := PhysicsRayQueryParameters3D.create(ray_start, ray_end);

	if exclude_entity_from_ray:
		ray_exclusions.append(entity.get_rid());

	ray_query.set_exclude(ray_exclusions);
	ray_query.set_collision_mask(ray_collision_mask);

	var ray_result: Dictionary = space_state.intersect_ray(ray_query);

	return ray_result;


func get_camera_aim_point_by_ray_else_fallback(
		ray_collision_mask: int = CollisionMaskLib.get_entities_and_obstacles(),
		exclude_entity_from_ray: bool = true,
		ray_exclusions: Array[RID] = [],
) -> Vector3:
	var ray_from_camera_forward_result: Dictionary = ray_from_camera_forward(
			ray_collision_mask,
			exclude_entity_from_ray,
			ray_exclusions,
	);

	var camera_aim_point: Vector3;

	if ray_from_camera_forward_result.has("position"):
		camera_aim_point = ray_from_camera_forward_result.get("position");
	else:
		camera_aim_point = get_fallback_camera_aim_point();

	return camera_aim_point;


func get_camera_aim_point_by_ray(
		ray_collision_mask: int = CollisionMaskLib.get_entities_and_obstacles(),
		exclude_entity_from_ray: bool = true,
		ray_exclusions: Array[RID] = [],
) -> Vector3:
	var ray_from_camera_forward_result: Dictionary = ray_from_camera_forward(
			ray_collision_mask,
			exclude_entity_from_ray,
			ray_exclusions,
	);

	var camera_aim_point: Vector3 = Vector3.ZERO;
	
	if ray_from_camera_forward_result.has("position"):
		camera_aim_point = ray_from_camera_forward_result.get("position");

	return camera_aim_point;


func get_fallback_camera_aim_point() -> Vector3:
	var camera_forward_direction: Vector3 = -_camera.global_basis.z.normalized();

	return _camera.global_position + (camera_forward_direction * 1000.0);
