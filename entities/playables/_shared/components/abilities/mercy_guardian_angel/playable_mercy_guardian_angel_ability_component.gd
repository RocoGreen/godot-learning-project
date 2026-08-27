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

@export var camera_component: PlayableCameraComponent:
	set(new_camera_component):
		camera_component = new_camera_component;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Optional Dependencies")
@export var character_body_3d_utils_component: PlayableCharacterBody3DUtilsComponent:
	set(new_character_body_3d_utils_component):
		character_body_3d_utils_component = new_character_body_3d_utils_component;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Target Finder Settings")
@export var target_finder_maximum_range: float = 100.0;

@export_group("Flying To Target Settings")
@export var flying_to_target_travel_speed: float = 30.0;
@export var stop_flying_to_target_when_distance_to_it_reaches: float = 1.0;

@export_group("Slingshot Settings")
@export var slingshot_force: float = 50.0;
@export var stop_slingshot_when_speed_reaches: float = 2.0;

@export_group("Super Jump Settings")
@export var super_jump_force: float = 50.0;
@export var stop_super_jump_when_speed_reaches: float = 2.0;

@export_group("Input Actions Settings")
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var ability_input_action: StringName = &"ability_1";

var _pressing_again_ability_input_action_required: bool = false;

var _active: bool = false;

var _finding_a_target: bool = false;
var _target_global_position: Vector3 = Vector3.ZERO;

var _flying_to_target: bool = false;
var _character_body_3d_utils_component_full_disable_request: \
		PlayableCharacterBody3DUtilsComponent.FullDisableRequest;

var _slingshotting: bool = false;
var _super_jumping: bool = false;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return;

	if _pressing_again_ability_input_action_required:
		if Input.is_action_pressed(ability_input_action):
			return;
		else:
			_pressing_again_ability_input_action_required = false;

	var ability_got_reset: bool = _handle_reset_conditions();

	if ability_got_reset: 
		return;

	var something_got_started: bool = _handle_starters();

	if something_got_started: 
		return;

	_handle_handlers(delta);


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity(entity));

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity_identity(entity_identity));

	if character_body_3d_utils_component:
		warnings.append_array(
				ConfigurationWarningLibrary.get_for_cb_3d_utils_component(
						character_body_3d_utils_component
				)
		);

	warnings.append_array(ConfigurationWarningLibrary.get_for_camera_component(camera_component));

	return warnings;


func _handle_reset_conditions() -> bool:
	var ability_got_reset: bool = false;

	if _active and Input.is_action_just_pressed(ability_input_action):
		_reset();
		ability_got_reset = true;

	elif _finding_a_target and not Input.is_action_pressed(ability_input_action):
		_reset();
		ability_got_reset = true;

	return ability_got_reset;


func _handle_starters() -> bool:
	var something_got_started: bool = false;

	if _flying_to_target:
		if Input.is_action_just_pressed(&"jump"):
			_flying_to_target = false;

			_start_slingshot();
			something_got_started = true;

		elif Input.is_action_just_pressed(&"crouch"):
			_flying_to_target = false;

			_start_super_jump();
			something_got_started = true;

	elif Input.is_action_just_pressed(ability_input_action):
		_active = true;

		_start_target_finding();
		something_got_started = true;

	return something_got_started;


func _handle_handlers(delta: float) -> void:
	if _finding_a_target:
		_handle_target_finding();

	elif _flying_to_target:
		_handle_flying_to_target();

	elif _slingshotting:
		_handle_slingshot(delta);

	elif _super_jumping:
		_handle_super_jump(delta);


func _start_target_finding() -> void:
	_finding_a_target = true;
	_handle_target_finding();


func _handle_target_finding() -> void:
	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();

	if ray_to_get_what_player_aims_at_results.is_empty():
		return;

	var target: PhysicsBody3D = ray_to_get_what_player_aims_at_results.get("collider") as PhysicsBody3D;
	var target_aimed_at_aim_point: Vector3 = ray_to_get_what_player_aims_at_results.get("position");
	
	if not target.is_in_group(&"entities"): 
		return;

	if entity.global_position.distance_to(target_aimed_at_aim_point) > target_finder_maximum_range:
		return;

	_finding_a_target = false;

	var new_target_global_position_to_fly_to: Vector3 = target_aimed_at_aim_point;
	_start_flying(new_target_global_position_to_fly_to);


func _start_flying(target_global_position_to_fly_to: Vector3) -> void:
	_target_global_position = target_global_position_to_fly_to;

	if character_body_3d_utils_component:
		_character_body_3d_utils_component_full_disable_request = \
				PlayableCharacterBody3DUtilsComponent.FullDisableRequest.new();

		character_body_3d_utils_component.add_full_disable_request(
				_character_body_3d_utils_component_full_disable_request
		);

	_handle_flying_to_target();
	_flying_to_target = true;


func _handle_flying_to_target() -> void:
	if entity.global_position.distance_to(_target_global_position) <= \
			stop_flying_to_target_when_distance_to_it_reaches:
		_reset();

	else:
		var flying_speed: float = flying_to_target_travel_speed;
		
		entity.velocity = entity.global_position.direction_to(_target_global_position) * flying_speed;
		entity.move_and_slide();


func _start_slingshot() -> void:
	var entity_forward_vector: Vector3 = -entity.global_basis.z.normalized();

	entity.velocity = entity_forward_vector * slingshot_force;
	entity.move_and_slide();

	_slingshotting = true;


func _handle_slingshot(delta: float) -> void:
	entity.velocity = entity.velocity.move_toward(Vector3.ZERO, slingshot_force * delta);
	entity.move_and_slide();

	if entity.velocity.length() <= stop_slingshot_when_speed_reaches:
		_reset();


func _start_super_jump() -> void:
	entity.velocity = Vector3.ZERO;
	entity.velocity.y = super_jump_force;

	entity.move_and_slide();
	_super_jumping = true;


func _handle_super_jump(delta: float) -> void:
	entity.velocity = entity.velocity.move_toward(Vector3.ZERO, super_jump_force * delta);
	entity.move_and_slide();

	if entity.velocity.length() <= stop_super_jump_when_speed_reaches:
		_reset();


func _reset() -> void:
	_active = false;

	_finding_a_target = false;
	_target_global_position = Vector3.ZERO;

	_flying_to_target = false;

	if _character_body_3d_utils_component_full_disable_request:
		character_body_3d_utils_component.remove_full_disable_request(
				_character_body_3d_utils_component_full_disable_request
		);
		_character_body_3d_utils_component_full_disable_request = null;

	_slingshotting = false;
	_super_jumping = false;

	if Input.is_action_pressed(ability_input_action):
		_pressing_again_ability_input_action_required = true;


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();
