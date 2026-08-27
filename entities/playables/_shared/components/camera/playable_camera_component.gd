@tool

class_name PlayableCameraComponent
extends Marker3D


const _MAX_AIM_DISTANCE: float = 1000.0;

@export_group("Dependencies")
@export var playable: CharacterBody3D:
	set(new_playable):
		playable = new_playable;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Settings")
@export var following_smoothness: float = 0.5;

@onready var _camera: Camera3D = %Camera;
@onready var _camera_pivot: SpringArm3D = %CameraPivot;


func _ready() -> void:
	if Engine.is_editor_hint():
		_camera_pivot.set_as_top_level(false);
		_camera_pivot.global_transform = global_transform;

	else:
		_camera_pivot.add_excluded_object(playable.get_rid());


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;

	_camera_pivot.global_transform = _camera_pivot.global_transform.interpolate_with(
			global_transform,
			following_smoothness
	);


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLibrary.get_for_playable(playable);


## Note: The returned data (`Dictionary`) containing the results of the intersected ray 
## is the same as `PhysicsDirectSpaceState3D.intersect_ray()` method.
func ray_to_aim_direction(
		ray_collision_mask: int = CollisionMaskLibrary.get_entities_and_obstacles(),
		exclude_entity_from_ray: bool = true,
		ray_exclusions: Array[RID] = [],
) -> Dictionary:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().get_direct_space_state();

	var ray_start: Vector3 = _camera.get_global_position();
	var camera_forward_direction_in_world: Vector3 = -_camera.global_basis.z.normalized();
	var ray_end: Vector3 = ray_start + (camera_forward_direction_in_world * _MAX_AIM_DISTANCE);

	var ray_query := PhysicsRayQueryParameters3D.create(ray_start, ray_end);

	if exclude_entity_from_ray:
		ray_exclusions.append(playable.get_rid());

	ray_query.set_exclude(ray_exclusions);
	ray_query.set_collision_mask(ray_collision_mask);

	var ray_result: Dictionary = space_state.intersect_ray(ray_query);

	return ray_result;


func get_position_to_look_at_aim_direction() -> Vector3:
	var camera_forward_direction_in_world: Vector3 = -_camera.global_basis.z.normalized();
	
	return _camera.global_position + (camera_forward_direction_in_world * _MAX_AIM_DISTANCE);
