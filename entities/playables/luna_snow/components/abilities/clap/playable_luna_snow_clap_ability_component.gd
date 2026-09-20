@tool

class_name PlayableLunaSnowClapAbilityComponent
extends Node3D


signal healed_someone(amount: float);

@export_group("Dependencies")
@export var playable_luna_snow: PlayableLunaSnow:
	set(new_playable_luna_snow):
		playable_luna_snow = new_playable_luna_snow;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var playable_luna_snow_identity: EntityIdentity = EntityIdentity.new():
	set(new_playable_luna_snow_identity):
		if playable_luna_snow_identity and Engine.is_editor_hint():
			playable_luna_snow_identity.changed.disconnect(_on_playable_luna_snow_identity_changed);

		playable_luna_snow_identity = new_playable_luna_snow_identity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

			if playable_luna_snow_identity:
				playable_luna_snow_identity.changed.connect(_on_playable_luna_snow_identity_changed);

@export var camera_component: PlayableCameraComponent:
	set(new_camera_component):
		camera_component = new_camera_component;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var weapon_component: PlayableLunaSnowWeaponComponent;

@export_group("Settings")
@export var time_seconds_to_start: float = 2.0;
@export var duration_time_seconds: float = 8.0;
@export var recovery_time_seconds_for_next_clap: float = 1.0;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_start: StringName = &"ability_2";

@export_group("Settings Specific to Clap")
@export var healing_per_clap: float = 60.0;
@export var damage_per_clap: float = 50.0;
@export var clap_radius_meters: float = 0.5;
@export var clap_maximum_length_meters: float = 40.0;
@export var clap_vfx_display_duration_seconds: float = 0.1;

var _starting: bool = false;
var _active: bool = false;
var _in_recovery_for_next_clap: bool = false;

var _input_action_to_start_pressed_at_last_usage_ending: bool = false;

@onready var entities_detector_pivot_node_3d: Node3D = %EntitiesDetectorPivot;
@onready var entities_detector_shape_cast: ShapeCast3D = %EntitiesDetector;

@onready var obstacle_at_center_detector_ray_cast: RayCast3D = %ObstacleAtCenterDetector;

@onready var start_time_timer: Timer = %StartTime;
@onready var duration_time_timer: Timer = %DurationTime;
@onready var recovery_time_for_next_clap_timer: Timer = %RecoveryTimeForNextClap;
@onready var clap_vfx_visibility_time_timer: Timer = %ClapVFXVisibilityTime;

@onready var clap_vfx_pivot_node_3d: Node3D = %ClapVFXPivot;
@onready var clap_vfx_mesh_instance: MeshInstance3D = %ClapVFX;


func _init() -> void:
	if Engine.is_editor_hint() and playable_luna_snow_identity:
		playable_luna_snow_identity.changed.connect(_on_playable_luna_snow_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	entities_detector_shape_cast.add_exception(playable_luna_snow);

	start_time_timer.timeout.connect(_on_start_time_timer_timeout);
	duration_time_timer.timeout.connect(_on_duration_time_timer_timeout);
	recovery_time_for_next_clap_timer.timeout.connect(_on_recovery_time_for_next_clap_timer_timeout);
	clap_vfx_visibility_time_timer.timeout.connect(_on_clap_vfx_visibility_time_timer_timeout);


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;

	if _input_action_to_start_pressed_at_last_usage_ending:
		if not Input.is_action_pressed(input_action_to_start):
			_input_action_to_start_pressed_at_last_usage_ending = false;
		else:
			return;

	elif Input.is_action_pressed(input_action_to_start):
		if not _active:
			_start();

		elif not _starting and not _in_recovery_for_next_clap:
			_clap();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLibrary.get_for_playable(playable_luna_snow));

	warnings.append_array(ConfigurationWarningLibrary.get_for_camera_component(camera_component));

	warnings.append_array(
			ConfigurationWarningLibrary.get_for_entity_identity(playable_luna_snow_identity),
	);

	return warnings;


func _start() -> void:
	_active = true;

	_starting = true;
	start_time_timer.start(time_seconds_to_start);

	print("Luna Clap Ability Starting...");


func _clap() -> void:
	var where_clap_starts: Vector3 = _get_where_clap_starts();
	var where_clap_ends: Vector3 = _get_where_clap_ends();
	var clap_length_meters: float = where_clap_starts.distance_to(where_clap_ends);

	_setup_entities_detector_shape_cast_and_pivot_node_3d(
			where_clap_starts, 
			where_clap_ends,
			clap_length_meters,
	);

	entities_detector_shape_cast.force_shapecast_update();
	_display_clap_vfx(where_clap_starts, where_clap_ends, clap_length_meters);

	if entities_detector_shape_cast.get_collision_count() > 0:
		_heal_or_damage_entities_hit_by_clap();

	_in_recovery_for_next_clap = true;
	recovery_time_for_next_clap_timer.start(recovery_time_seconds_for_next_clap);

	print("You just clapped ! In recovery for next shot...");


func _setup_entities_detector_shape_cast_and_pivot_node_3d(
		where_clap_starts_this_frame: Vector3,
		where_clap_ends_this_frame: Vector3,
		clap_length_meters_of_this_frame: float,
) -> void:
	var detector_shape_cast: ShapeCast3D = entities_detector_shape_cast;
	var detector_shape_cast_shape: CylinderShape3D = detector_shape_cast.shape as CylinderShape3D;
	var pivot_node_3d: Node3D = entities_detector_pivot_node_3d;

	detector_shape_cast_shape.height = clap_length_meters_of_this_frame;
	detector_shape_cast_shape.radius = clap_radius_meters;

	pivot_node_3d.look_at_from_position(where_clap_starts_this_frame, where_clap_ends_this_frame);

	var pivot_forward_vector: Vector3 = -pivot_node_3d.global_basis.z.normalized();
	pivot_node_3d.global_position += pivot_forward_vector * (clap_length_meters_of_this_frame / 2.0);


func _get_where_clap_starts() -> Vector3:
	return weapon_component.bullet_start_position_anchor_marker_3d.global_position;


func _get_where_clap_ends() -> Vector3:
	var where_clap_starts: Vector3 = _get_where_clap_starts();
	var where_to_clap_at: Vector3 = camera_component.get_position_to_look_at_aim_direction(
			false,
			CollisionMaskLibrary.get_obstacles(),
	);

	obstacle_at_center_detector_ray_cast.look_at_from_position(where_clap_starts, where_to_clap_at);
	obstacle_at_center_detector_ray_cast.target_position.z = -clap_maximum_length_meters;

	obstacle_at_center_detector_ray_cast.force_raycast_update();

	if obstacle_at_center_detector_ray_cast.is_colliding():
		return obstacle_at_center_detector_ray_cast.get_collision_point();
	else:
		var clap_direction: Vector3 = where_clap_starts.direction_to(where_to_clap_at);
		return where_clap_starts + (clap_direction * clap_maximum_length_meters);


func _heal_or_damage_entities_hit_by_clap() -> void:
	for collider_index: int in range(entities_detector_shape_cast.get_collision_count()):
		var collider: Object = entities_detector_shape_cast.get_collider(collider_index);

		if not EntityComponent.is_object_an_entity(collider): return;

		var collider_entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(collider);
		var collider_entity_identity: EntityIdentity = EntityIdentity.from_entity(collider_entity);

		if not collider_entity_identity: return;

		if collider_entity_identity.team == playable_luna_snow_identity.team:
			_apply_healing_to_entity(collider_entity);
		else:
			_apply_damage_to_entity(collider_entity);


func _apply_healing_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	var final_healing_done: float = entity_health_component.heal(
			healing_per_clap,
			playable_luna_snow_identity,
	);

	if final_healing_done > 0.0:
		healed_someone.emit(final_healing_done);


func _apply_damage_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.damage(damage_per_clap, playable_luna_snow_identity);


func _display_clap_vfx(
		where_clap_starts_this_frame: Vector3, 
		where_clap_ends_this_frame: Vector3,
		clap_length_meters_of_this_frame: float,
) -> void:
	_setup_clap_vfx_mesh_instance_and_pivot_node_3d(
			where_clap_starts_this_frame,
			where_clap_ends_this_frame,
			clap_length_meters_of_this_frame,
	);

	clap_vfx_mesh_instance.show();

	clap_vfx_visibility_time_timer.start(clap_vfx_display_duration_seconds);


func _setup_clap_vfx_mesh_instance_and_pivot_node_3d(
		where_clap_starts_this_frame: Vector3, 
		where_clap_ends_this_frame: Vector3,
		clap_length_meters_of_this_frame: float,
) -> void:
	var mesh_instance: MeshInstance3D = clap_vfx_mesh_instance;
	var mesh_instance_mesh: CylinderMesh = mesh_instance.mesh as CylinderMesh;
	var pivot_node_3d: Node3D = clap_vfx_pivot_node_3d;

	mesh_instance_mesh.height = clap_length_meters_of_this_frame;
	mesh_instance_mesh.top_radius = clap_radius_meters;
	mesh_instance_mesh.bottom_radius = clap_radius_meters;

	pivot_node_3d.look_at_from_position(where_clap_starts_this_frame, where_clap_ends_this_frame);

	var pivot_forward_vector: Vector3 = -pivot_node_3d.global_basis.z.normalized();
	pivot_node_3d.global_position += pivot_forward_vector * (clap_length_meters_of_this_frame / 2.0);


func _end_and_reset() -> void:
	_active = false;
	_starting = false;
	_in_recovery_for_next_clap = false;

	if not start_time_timer.is_stopped():
		start_time_timer.stop();

	if not recovery_time_for_next_clap_timer.is_stopped():
		recovery_time_for_next_clap_timer.stop();

	if not duration_time_timer.is_stopped():
		duration_time_timer.stop();

	if not clap_vfx_visibility_time_timer.is_stopped():
		clap_vfx_visibility_time_timer.stop();

	if clap_vfx_mesh_instance.is_visible():
		clap_vfx_mesh_instance.hide();

	if Input.is_action_pressed(input_action_to_start):
		_input_action_to_start_pressed_at_last_usage_ending = true;

	print("Luna Clap Ability Ended and Resetted !");


func _on_start_time_timer_timeout() -> void:
	_starting = false;
	print("Luna Clap Ability Started ! Press the input action to clap if you're not already.");

	duration_time_timer.start(duration_time_seconds);


func _on_duration_time_timer_timeout() -> void:
	_end_and_reset();


func _on_recovery_time_for_next_clap_timer_timeout() -> void:
	_in_recovery_for_next_clap = false;
	print("Recovery over ! Press the input action if you're not already to clap once more !");


func _on_clap_vfx_visibility_time_timer_timeout() -> void:
	clap_vfx_mesh_instance.hide();


func _on_playable_luna_snow_identity_changed() -> void:
	update_configuration_warnings();
