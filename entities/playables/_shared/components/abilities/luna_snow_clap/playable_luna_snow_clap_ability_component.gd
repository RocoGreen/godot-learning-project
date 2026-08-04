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
@export var healing_amount: float = 60.0;
@export var damage_amount: float = 50.0;

var _duration_remaining_seconds: float = 0.0;
var _pressing_ability_input_action_again_required: bool = false;
var _ability_input_action: StringName = &"ability_2";

@onready var target_detector_pivot: Node3D = %TargetDetectorPivot;
@onready var target_detector: ShapeCast3D = %TargetDetector;

@onready var center_target_detector: RayCast3D = %CenterTargetDetector;

@onready var duration_timer: Timer = %DurationTimer;
@onready var lag_timer: Timer = %LagTimer;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	AssertLib.assert_if_cb_3d_entity_not_found(entity);
	AssertLib.assert_if_entity_identity_not_found(entity_identity);
	AssertLib.assert_if_camera_component_not_found(camera_component);

	# We do not want the `Entity` to be able to heal/damage themselves with the ability so let's 
	# add it to the detectors' exceptions.
	target_detector.add_exception(entity);
	center_target_detector.add_exception(entity);


#func _process(_delta: float) -> void:
	#if Engine.is_editor_hint(): return;
	#if duration_timer.is_stopped(): return;
	#
	#if _duration_remaining_seconds == snappedf(duration_timer.time_left, 0.1): return;
	#
	#_duration_remaining_seconds = snappedf(duration_timer.time_left, 0.1);
	#print("- Luna Clap Duration Remaining : %s second(s)" % _duration_remaining_seconds);


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;
	
	if _pressing_ability_input_action_again_required:
		if not Input.is_action_pressed(_ability_input_action):
			_pressing_ability_input_action_again_required = false;
		else:
			return;
	
	elif Input.is_action_pressed(_ability_input_action):
		if duration_timer.is_stopped():
			_start_ability();
		
		elif lag_timer.is_stopped():
			_handle_ability();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();
	
	warnings.append_array(ConfigurationWarningLib.get_for_entity(entity));

	warnings.append_array(ConfigurationWarningLib.get_for_camera_component(camera_component));

	warnings.append_array(ConfigurationWarningLib.get_for_entity_identity(entity_identity));
	
	return warnings;


func _start_ability() -> void:
	duration_timer.start();
	lag_timer.start();
	
	print("- Luna Clap Ability Started and currently in lag !");


func _handle_ability() -> void:
	target_detector_pivot.look_at(camera_component.get_camera_aim_point_by_ray_else_virtual());
	target_detector.force_shapecast_update();
	
	for collision_index: int in range(target_detector.get_collision_count()):
		var target: PhysicsBody3D = target_detector.get_collider(collision_index);
		
		#print("Luna clap TargetDetector detected: ", target);
		
		if target.is_in_group(&"entities"):
			if not _is_target_detected_at_center(target):
				continue;
			
			elif target.is_in_group(&"allies"):
				_apply_healing_to_target(target);
			
			elif target.is_in_group(&"enemies"):
				_apply_damage_to_target(target);
	
	print("_");
	lag_timer.start();


func _is_target_detected_at_center(target: PhysicsBody3D) -> bool:
	center_target_detector.look_at(camera_component.get_camera_aim_point_by_ray_else_virtual());
	center_target_detector.force_raycast_update();
	
	var target_detected_at_center: bool = false;
	
	while(center_target_detector.is_colliding()):
		var center_target: PhysicsBody3D = center_target_detector.get_collider();
		
		#print("Luna clap CenterTargetDetector detected: ", center_target);
		
		if not center_target.is_in_group(&"entities"):
			break;
		
		elif center_target.get_rid() == target.get_rid():
			target_detected_at_center = true;
			break;
		
		center_target_detector.add_exception(center_target);
		center_target_detector.force_raycast_update();

	center_target_detector.clear_exceptions();
	center_target_detector.add_exception(entity);
	
	return target_detected_at_center;


func _apply_healing_to_target(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity_or_assert(target);
	var target_health: EntityHealthComponent = target_entity_component.exp_health_component;
	
	if not target_health: return;
	
	target_health.heal(healing_amount, entity_identity);
	#print('- Luna clap just healed : "%s" !' % target_entity_component.identity.name);


func _apply_damage_to_target(target: PhysicsBody3D) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity_or_assert(target);
	var target_health: EntityHealthComponent = target_entity_component.exp_health_component;
	
	if not target_health: return;
	
	target_health.damage(damage_amount, entity_identity);
	#print('- Luna clap just damaged : "%s" !' % target_entity_component.identity.name);


func _on_lag_timer_timeout() -> void:
	print("- Lag ended ! You can shoot (again) !");


func _on_duration_timer_timeout() -> void:
	_duration_remaining_seconds = 0.0;
	lag_timer.stop();
	
	if Input.is_action_pressed(_ability_input_action): 
		_pressing_ability_input_action_again_required = true;
	
	print("- Luna Clap Ability ended !");


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();
