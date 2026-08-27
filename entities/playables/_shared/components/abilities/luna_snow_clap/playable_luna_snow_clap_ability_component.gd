@tool

extends Node3D


@export_group("Dependencies")
@export var entity: PhysicsBody3D:
	set(new_entity):
		entity = new_entity;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var entity_identity: EntityIdentity = EntityIdentity.new():
	set(new_entity_identity):
		if entity_identity and Engine.is_editor_hint():
			entity_identity.changed.disconnect(_on_entity_identity_changed);

		entity_identity = new_entity_identity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

			if entity_identity:
				entity_identity.changed.connect(_on_entity_identity_changed);

@export var camera_component: PlayableCameraComponent:
	set(new_camera_component):
		camera_component = new_camera_component;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Settings")
@export var healing_per_clap: float = 60.0;
@export var damage_per_clap: float = 50.0;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var ability_input_action: StringName = &"ability_2";

var _pressing_ability_input_action_again_required: bool = false;

@onready var center_obstacle_detector_ray_cast: RayCast3D = %CenterObstacleDetector;

@onready var target_detector_pivot_node_3d: Node3D = %TargetDetectorPivot;
@onready var target_detector_shape_cast: ShapeCast3D = %TargetDetector;

@onready var target_visible_on_center_checker_ray_cast: RayCast3D = %TargetVisibleOnCenterChecker;

@onready var duration_timer: Timer = %DurationTimer;
@onready var lag_between_shots_timer: Timer = %LagBetweenShotsTimer;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	target_detector_shape_cast.add_exception(entity);
	target_visible_on_center_checker_ray_cast.add_exception(entity);


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;

	if _pressing_ability_input_action_again_required:
		if not Input.is_action_pressed(ability_input_action):
			_pressing_ability_input_action_again_required = false;
		else:
			return;

	elif Input.is_action_pressed(ability_input_action):
		if duration_timer.is_stopped():
			_start_ability();

		elif lag_between_shots_timer.is_stopped():
			_handle_ability();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();
	
	warnings.append_array(ConfigurationWarningLibrary.get_for_entity(entity));

	warnings.append_array(ConfigurationWarningLibrary.get_for_camera_component(camera_component));

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity_identity(entity_identity));

	return warnings;


func _start_ability() -> void:
	duration_timer.start();
	lag_between_shots_timer.start();

	print("- Luna Clap Ability Started and currently in lag !");


func _handle_ability() -> void:
	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();

	var where_to_clap_at: Vector3 = Vector3.ZERO;
	if ray_to_get_what_player_aims_at_results.has("position"):
		where_to_clap_at = ray_to_get_what_player_aims_at_results.get("position");
	else:
		where_to_clap_at = camera_component.get_position_to_look_at_aim_direction();

	center_obstacle_detector_ray_cast.look_at(where_to_clap_at);
	center_obstacle_detector_ray_cast.force_raycast_update();

	var clap_length: float = 40.0;

	if center_obstacle_detector_ray_cast.is_colliding():
		where_to_clap_at = center_obstacle_detector_ray_cast.get_collision_point();

		clap_length = global_position.distance_to(
				center_obstacle_detector_ray_cast.get_collision_point()
		);

	target_detector_pivot_node_3d.look_at(where_to_clap_at);
	target_detector_shape_cast.force_shapecast_update();

	for collider_index: int in range(target_detector_shape_cast.get_collision_count()):
		var target: PhysicsBody3D = target_detector_shape_cast.get_collider(collider_index);

		if global_position.distance_to(target.global_position) > clap_length:
			continue;

		var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
		var target_identity: EntityIdentity = target_entity_component.identity;

		if target_identity.team == entity_identity.team:
			_apply_healing_to_target(target);
		else:
			_apply_damage_to_target(target);

	lag_between_shots_timer.start();


#func _is_target_visible_on_center(target: PhysicsBody3D) -> bool:
	#target_visible_on_center_checker_ray_cast.look_at(target.global_position);
	#target_visible_on_center_checker_ray_cast.force_raycast_update();
#
	#var target_visible_on_center: bool = false;
#
	#while target_visible_on_center_checker_ray_cast.is_colliding():
		#var collider: PhysicsBody3D = target_visible_on_center_checker_ray_cast.get_collider();
#
		#if collider == target:
			#target_visible_on_center = true;
			#break;
#
		#elif not collider.is_in_group(&"entities"):
			#break;
#
		#target_visible_on_center_checker_ray_cast.add_exception(collider);
		#target_visible_on_center_checker_ray_cast.force_raycast_update();
#
	#target_visible_on_center_checker_ray_cast.clear_exceptions();
	#target_visible_on_center_checker_ray_cast.add_exception(entity);
#
	#return target_visible_on_center;


func _apply_healing_to_target(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;

	if not target_health: 
		return;

	target_health.heal(healing_per_clap, entity_identity);


func _apply_damage_to_target(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;

	if not target_health: 
		return;

	target_health.damage(damage_per_clap, entity_identity);


func _on_lag_between_shots_timer_timeout() -> void:
	print("- Lag ended ! You can shoot (again) !");


func _on_duration_timer_timeout() -> void:
	lag_between_shots_timer.stop();

	if Input.is_action_pressed(ability_input_action): 
		_pressing_ability_input_action_again_required = true;

	print("- Luna Clap Ability ended !");


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();
