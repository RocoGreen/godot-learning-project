@tool

class_name PlayableLunaSnowClapAbilityComponent
extends ShapeCast3D


signal healed_someone(amount: float);

@export_group("Dependencies")
@export var playable: PhysicsBody3D:
	set(new_playable):
		playable = new_playable;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var luna_snow_identity: EntityIdentity = EntityIdentity.new():
	set(new_luna_snow_identity):
		if luna_snow_identity and Engine.is_editor_hint():
			luna_snow_identity.changed.disconnect(_on_luna_snow_identity_changed);

		luna_snow_identity = new_luna_snow_identity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

			if luna_snow_identity:
				luna_snow_identity.changed.connect(_on_luna_snow_identity_changed);

@export var camera_component: PlayableCameraComponent:
	set(new_camera_component):
		camera_component = new_camera_component;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var weapon_component: PlayableLunaSnowWeaponComponent;

@export_group("Settings")
@export var time_seconds_to_start: float = 2.0;
@export var duration_time_seconds: float = 8.0;
@export var time_seconds_to_wait_before_next_clap: float = 1.0;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_start: StringName = &"ability_2";

@export_group("Settings Specific to Clap")
@export var healing_per_clap: float = 60.0;
@export var damage_per_clap: float = 50.0;
@export var clap_max_length_meters: float = 40.0;
@export var clap_vfx_display_duration_seconds: float = 0.1;

var _starting: bool = false;
var _active: bool = false;
var _waiting_before_next_clap: bool = false;

var _input_action_to_start_pressed_at_last_usage_ending: bool = false;

@onready var obstacle_at_center_detector_ray_cast: RayCast3D = %ObstacleAtCenterDetector;

@onready var clap_vfx_mesh_instance: MeshInstance3D = %ClapVFX;


func _init() -> void:
	if Engine.is_editor_hint() and luna_snow_identity:
		luna_snow_identity.changed.connect(_on_luna_snow_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	add_exception(playable);


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;

	if _input_action_to_start_pressed_at_last_usage_ending:
		if not Input.is_action_pressed(input_action_to_start):
			_input_action_to_start_pressed_at_last_usage_ending = false;
		else:
			return;

	elif GameState.in_game_input_disabled:
		return;

	elif Input.is_action_pressed(input_action_to_start):
		if not _active:
			_start();

		elif not _starting and not _waiting_before_next_clap:
			_clap();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLibrary.get_for_playable(playable));

	warnings.append_array(ConfigurationWarningLibrary.get_for_camera_component(camera_component));

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity_identity(luna_snow_identity));

	return warnings;


func _start() -> void:
	_active = true;

	_starting = true;
	print("Luna Clap Ability Starting...");

	await get_tree().create_timer(time_seconds_to_start).timeout;

	_starting = false;
	print("Luna Clap Ability Started ! Press the input action to clap if you're not already.");

	await get_tree().create_timer(duration_time_seconds).timeout;

	_end_and_reset();


func _clap() -> void:
	var where_clap_starts: Vector3 = _get_where_clap_starts();
	var where_clap_ends: Vector3 = _get_where_clap_ends();
	var clap_length: float = where_clap_starts.distance_to(where_clap_ends);

	look_at_from_position(where_clap_starts, where_clap_ends);

	shape = shape as BoxShape3D;
	shape.size.z = clap_length;

	target_position.z = -(clap_length / 2.0);

	force_shapecast_update();
	_display_clap_vfx(where_clap_starts, where_clap_ends);

	for collider_index: int in range(get_collision_count()):
		var target: PhysicsBody3D = get_collider(collider_index) as PhysicsBody3D;

		var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
		var target_identity: EntityIdentity = target_entity_component.identity;

		if target_identity.team == luna_snow_identity.team:
			_apply_healing_to_target_entity(target);
		else:
			_apply_damage_to_target_entity(target);

	_waiting_before_next_clap = true;
	print("You just clapped ! In recovery for next shot...");

	await get_tree().create_timer(time_seconds_to_wait_before_next_clap).timeout;

	if _active:
		_waiting_before_next_clap = false;
		print("Recovery over ! Press the input action if you're not already to clap once more !");


func _end_and_reset() -> void:
	_active = false;
	_starting = false;
	_waiting_before_next_clap = false;
	clap_vfx_mesh_instance.hide();

	if Input.is_action_pressed(input_action_to_start):
		_input_action_to_start_pressed_at_last_usage_ending = true;

	print("Luna Clap Ability Ended !");


func _get_where_clap_starts() -> Vector3:
	return weapon_component.bullet_start_transform_anchor_marker_3d.global_position;


func _get_where_clap_ends() -> Vector3:
	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();

	var where_to_clap_at: Vector3;
	if ray_to_get_what_player_aims_at_results.has("position"):
		where_to_clap_at = ray_to_get_what_player_aims_at_results.get("position");
	else:
		where_to_clap_at = camera_component.get_position_to_look_at_aim_direction();

	var where_clap_starts: Vector3 = _get_where_clap_starts();
	obstacle_at_center_detector_ray_cast.look_at_from_position(where_clap_starts, where_to_clap_at);
	obstacle_at_center_detector_ray_cast.target_position.z = -clap_max_length_meters;

	obstacle_at_center_detector_ray_cast.force_raycast_update();

	var where_clap_ends: Vector3;
	if obstacle_at_center_detector_ray_cast.is_colliding():
		where_clap_ends = obstacle_at_center_detector_ray_cast.get_collision_point();
	else:
		var clap_direction: Vector3 = where_clap_starts.direction_to(where_to_clap_at);
		where_clap_ends = where_clap_starts + (clap_direction * clap_max_length_meters);

	return where_clap_ends;


func _apply_healing_to_target_entity(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;

	if not target_health: return;

	var final_healing_done: float = target_health.heal(healing_per_clap, luna_snow_identity);

	if final_healing_done > 0.0:
		healed_someone.emit(final_healing_done);


func _apply_damage_to_target_entity(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;

	if not target_health: return;

	target_health.damage(damage_per_clap, luna_snow_identity);


func _display_clap_vfx(start_position: Vector3, end_position: Vector3) -> void:
	var clap_length: float = start_position.distance_to(end_position);

	clap_vfx_mesh_instance.mesh = clap_vfx_mesh_instance.mesh as BoxMesh;
	clap_vfx_mesh_instance.mesh.size.z = clap_length;

	clap_vfx_mesh_instance.look_at_from_position(start_position, end_position);
	# Of clap_vfx_mesh_instance.
	var forward_vector: Vector3 = -clap_vfx_mesh_instance.global_basis.z.normalized();
	clap_vfx_mesh_instance.global_position += forward_vector * (clap_length / 2.0);

	clap_vfx_mesh_instance.show();

	await get_tree().create_timer(clap_vfx_display_duration_seconds).timeout;

	if _active:
		clap_vfx_mesh_instance.hide();


func _on_luna_snow_identity_changed() -> void:
	update_configuration_warnings();
