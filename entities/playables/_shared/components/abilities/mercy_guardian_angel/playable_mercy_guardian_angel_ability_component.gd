@tool

extends Node


@export_group("Dependencies")
@export var entity: CharacterBody3D:
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

@export var cb_3d_utils_component: EntityCharacterBody3DUtilsComponent:
	set(new_cb_3d_utils_component):
		cb_3d_utils_component = new_cb_3d_utils_component;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var camera_component: EntityCameraComponent:
	set(new_camera_component):
		camera_component = new_camera_component;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("GA Settings")
@export var GA_max_range: float = 100.0;
@export var GA_speed: float = 30.0;
@export var GA_stop_distance: float = 1.0;

@export_group("Slingshot Settings")
@export var slingshot_force: float = 50.0;
@export var stop_slingshot_velocity: float = 2.0;

@export_group("Superjump Settings")
@export var superjump_force: float = 50.0;
@export var stop_superjump_velocity: float = 2.0;


var _active: bool = false;
var _finding_a_target: bool = false;
var _flying_towards_target: bool = false;
var _slingshotting: bool = false;
var _superjumping: bool = false;

var _cb_3d_utils_component_disable_request: Request;

var _pressing_again_input_action_required: bool = false;

var _target_global_position: Vector3 = Vector3.ZERO;

var _entity_forward_vector_before_flying: Vector3 = Vector3.ZERO;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	AssertLib.assert_if_cb_3d_entity_not_found(entity);

	AssertLib.assert_if_entity_identity_not_found(entity_identity);

	AssertLib.assert_if_cb_3d_utils_component_not_found(cb_3d_utils_component);

	AssertLib.assert_if_camera_component_not_found(camera_component);


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return;

	if _pressing_again_input_action_required:
		if Input.is_action_pressed(&"ability_1"):
			return;
		else:
			_pressing_again_input_action_required = false;

	var resetted: bool = _handle_resetters();

	if resetted: 
		return;

	var something_started: bool = _handle_starters();

	if something_started: 
		return;

	_handle_handlers(delta);


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLib.get_for_entity(entity));

	warnings.append_array(ConfigurationWarningLib.get_for_entity_identity(entity_identity));

	warnings.append_array(ConfigurationWarningLib.get_for_cb_3d_utils_component(cb_3d_utils_component));

	warnings.append_array(ConfigurationWarningLib.get_for_camera_component(camera_component));

	return warnings;


func _handle_resetters() -> bool:
	var resetted: bool = true;
	
	if _active and Input.is_action_just_pressed(&"ability_1"):
		_reset();
	
	elif _finding_a_target and not Input.is_action_pressed(&"ability_1"):
		_reset();
	
	else:
		resetted = false;
	
	return resetted;


func _handle_starters() -> bool:
	var something_started: bool = false;
	
	if _flying_towards_target:
		if Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"crouch"):
			_flying_towards_target = false;
			something_started = true;
			
		if Input.is_action_just_pressed(&"jump"):
			_start_slingshot();
		
		elif Input.is_action_just_pressed(&"crouch"):
			_start_superjump();
	
	elif Input.is_action_just_pressed(&"ability_1"):
		_active = true;
		something_started = true;
		
		_start_target_finding();
	
	return something_started;


func _handle_handlers(delta: float) -> bool:
	var an_handler_got_executed: bool = true;
	
	if _finding_a_target:
		_handle_target_finding();
	
	elif _flying_towards_target:
		_handle_flying();
	
	elif _slingshotting:
		_handle_slingshot(delta);
	
	elif _superjumping:
		_handle_superjump(delta);
	
	else:
		an_handler_got_executed = false;
	
	return an_handler_got_executed;


func _start_target_finding() -> void:
	_finding_a_target = true;
	
	_handle_target_finding();


func _handle_target_finding() -> void:
	var ray_from_camera_forward_results: Dictionary = camera_component.ray_from_camera_forward();

	var target := ray_from_camera_forward_results.get("collider") as PhysicsBody3D;

	if not target: return;
	if not target.is_in_group(&"entities"): return;

	var ray_from_camera_forward_point: Vector3 = ray_from_camera_forward_results.get("position");

	if entity.global_position.distance_to(ray_from_camera_forward_point) > GA_max_range: 
		return;

	_finding_a_target = false;

	var new_target_global_position_to_fly_to: Vector3 = ray_from_camera_forward_point;
	_start_flying(new_target_global_position_to_fly_to);


func _start_flying(target_global_position_to_fly_to: Vector3) -> void:
	_target_global_position = target_global_position_to_fly_to;
	_entity_forward_vector_before_flying = -entity.global_basis.z.normalized();
	
	_cb_3d_utils_component_disable_request = Request.new(entity_identity);
	cb_3d_utils_component.disable_requests.add(_cb_3d_utils_component_disable_request);
	
	_flying_towards_target = true;
	
	_handle_flying();


func _handle_flying() -> void:
	if entity.global_position.distance_to(_target_global_position) <= GA_stop_distance:
		_reset();
	else:
		entity.velocity = entity.global_position.direction_to(_target_global_position) * GA_speed;
		entity.move_and_slide();


func _start_slingshot() -> void:
	entity.velocity = -entity.global_basis.z.normalized() * slingshot_force;
	entity.move_and_slide();
	
	_slingshotting = true;


func _handle_slingshot(delta: float) -> void:
	_move_entity_velocity_towards_zero(slingshot_force, delta, stop_slingshot_velocity);


func _start_slingshot_ow1() -> void:
	entity.velocity = _entity_forward_vector_before_flying * slingshot_force;
	
	#var input_direction_x: float = 0.0;
	#
	#if not Input.is_action_pressed(&"move_left") and not Input.is_action_pressed(&"move_right"):
		#if Input.is_action_pressed(&"move_left"):
			#input_direction_x = -Input.get_action_strength(&"move_left");
		#
		#elif Input.is_action_pressed(&"move_right"):
			#input_direction_x = Input.get_action_strength(&"move_right");
	#
	#if input_direction_x != 0.0:
		#entity.velocity += ( entity.global_basis.x.normalized() * input_direction_x ) * 20.0;
	
	var movement_inputs_direction_x: float = InputUtils.get_basic_movement_inputs_direction().x;
	
	if movement_inputs_direction_x != 0.0:
		entity.velocity += (entity.global_basis.x.normalized() * movement_inputs_direction_x) * 20.0;
	
	entity.move_and_slide();
	
	_slingshotting = true;


func _handle_slingshot_ow1(delta: float) -> void:
	_move_entity_velocity_towards_zero(slingshot_force, delta, stop_slingshot_velocity);


func _start_superjump() -> void:
	entity.velocity = Vector3.ZERO;
	entity.velocity.y = superjump_force;
	
	entity.move_and_slide();
	
	_superjumping = true;


func _handle_superjump(delta: float) -> void:
	_move_entity_velocity_towards_zero(superjump_force, delta, stop_superjump_velocity);


func _move_entity_velocity_towards_zero(force: float, delta: float, stop_velocity: float) -> void:
	entity.velocity = entity.velocity.move_toward(Vector3.ZERO, force * delta);
	entity.move_and_slide();
	
	if entity.velocity.length() <= stop_velocity:
		_reset();


func _reset() -> void:
	_active = false;
	_finding_a_target = false;
	_flying_towards_target = false;
	_slingshotting = false;
	_superjumping = false;
	
	_target_global_position = Vector3.ZERO;
	
	if _cb_3d_utils_component_disable_request:
		cb_3d_utils_component.disable_requests.remove(_cb_3d_utils_component_disable_request);
		_cb_3d_utils_component_disable_request = null;
	
	if Input.is_action_pressed(&"ability_1"):
		_pressing_again_input_action_required = true;


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();
