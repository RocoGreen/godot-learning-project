@tool

class_name PlayableCameraComponent
extends Marker3D
## [b]TODO[/b]: May have to check if the script is easy enough to be understood by others.


const _MAXIMUM_AIM_DISTANCE_TO_COVER_ANY_MAP: float = 1000.0;

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
	var camera_forward_vector: Vector3 = -_camera.global_basis.z.normalized();
	var ray_length: float = _MAXIMUM_AIM_DISTANCE_TO_COVER_ANY_MAP;
	var ray_end: Vector3 = ray_start + (camera_forward_vector * ray_length);

	if exclude_entity_from_ray:
		ray_exclusions.append(playable.get_rid());

	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			ray_start, 
			ray_end,
			ray_collision_mask,
			ray_exclusions,
	);

	var ray_results: Dictionary = space_state.intersect_ray(ray_query);

	return ray_results;


## Returns a position to look at where the player is aiming at. The position returned is in global
## space. See below to understand how to use it.
## [br][br]
## To get that position, this method will cast a ray that'll start from camera's 
## global position and travel towards the camera's forward direction with a max length enough to
## cover any map of the game (1000.0 meters). That same ray will by default mask (collision mask)
## anything the player can physically aim at in the game which is perfect because it's collision
## point (if it hits anything) can then be used to reliably look at the direction the player aims at.
## [br][br]
## Though, if the ray doesn't hit anything, a fallback position is used that is heuristic enough
## in long range. And well since the ray's max length is supposed to cover the whole map to begin
## with, this make the whole method reliable to be used to look at where the player aims at.
## Perfect for knowing where the bullet should travel at for example.
## [br][br]
## [b]TODO[/b]: I decided to not finish the explanation of the method. Please rework the
## documentation for it.
func get_position_to_look_at_aim_direction(
		fallback_only: bool = false,
		ray_collision_mask: int = CollisionMaskLibrary.get_entities_and_obstacles(),
		exclude_entity_from_ray: bool = true,
		ray_exclusions: Array[RID] = [],
) -> Vector3:
	var camera_forward_vector: Vector3 = -_camera.global_basis.z.normalized();
	var maximum_aim_distance: float = _MAXIMUM_AIM_DISTANCE_TO_COVER_ANY_MAP;

	var position_to_look_at_aim_direction: Vector3 = \
		_camera.global_position + (camera_forward_vector * maximum_aim_distance);

	if not fallback_only:
		var ray_to_get_what_player_aims_at_results: Dictionary = ray_to_aim_direction(
				ray_collision_mask,
				exclude_entity_from_ray,
				ray_exclusions,
		);

		if ray_to_get_what_player_aims_at_results.has("position"):
			position_to_look_at_aim_direction = ray_to_get_what_player_aims_at_results.position;

	return position_to_look_at_aim_direction;
