@tool

# Also abbreviated to EntityCBUtilsComponent.
class_name EntityCharacterBody3DUtilsComponent
extends Node


@export_group("Dependencies")
@export var entity: CharacterBody3D:
	set(new_entity):
		entity = new_entity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Basic Movement And Flying Settings")
@export var move_and_flying_speed: float = 10.0;

@export_group("Running Settings")
@export var move_and_flying_speed_when_running: float = 20.0;

@export_group("Jumping Settings")
@export var jumping_force: float = 8.0;

var disable_requests: RequestsHandler = RequestsHandler.new();

var _running: bool = false;
var _flying: bool = false;

var _frame_basic_movement_direction: Vector3 = Vector3.ZERO;
var _flying_movement_requested_this_frame: bool = false;


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	AssertLib.assert_if_cb_3d_entity_not_found(entity);


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return;
	if not disable_requests.is_empty(): return;

	_handle_gravity(delta);

	_handle_jumping();

	_handle_running();

	_handle_basic_movement();

	_handle_flying_toggle();

	_handle_flying();

	_handle_deceleration();

	_frame_basic_movement_direction = Vector3.ZERO;
	_flying_movement_requested_this_frame = false;

	entity.move_and_slide();


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLib.get_for_entity(entity);


func _handle_gravity(delta: float) -> void:
	if entity.is_on_floor(): return;

	# get_gravity() must be multiplied by delta since it runs on it's own clock. 
	# Wouldn't work correctly without the multiplication anyway.
	entity.velocity += entity.get_gravity() * delta;


func _handle_jumping() -> void:
	# No jumping while in air allowed.
	if not entity.is_on_floor() or not Input.is_action_just_pressed(&"jump"): 
		return;

	entity.velocity.y = jumping_force;


func _handle_running() -> void:
	# Running works by constantly pressing it's input action, not by toggle.
	if Input.is_action_pressed(&"run"):
		_running = true;
	else:
		_running = false;


func _handle_basic_movement() -> void:
	var basic_movement_inputs_direction: Vector2 = InputUtils.get_basic_movement_inputs_direction();

	var final_x_direction: Vector3 = entity.global_basis.x * basic_movement_inputs_direction.x;
	var final_z_direction: Vector3 = entity.global_basis.z * basic_movement_inputs_direction.y;

	var final_direction: Vector3 = (final_x_direction + final_z_direction).normalized();

	if final_direction:
		var move_speed: float = _get_final_move_and_flying_speed();

		entity.velocity.x = final_direction.x * move_speed;
		entity.velocity.z = final_direction.z * move_speed;

	# Saved for the rest of handlers.
	_frame_basic_movement_direction = final_direction;


func _handle_flying_toggle() -> void:
	if Input.is_action_just_pressed(&"toggle_flying_mode"):
		if _flying:
			_flying = false;
		else:
			_flying = true;


func _handle_flying() -> void:
	if not _flying: return;

	var flying_movement_requested: bool = true;
	var flying_speed: float = _get_final_move_and_flying_speed();

	if Input.is_action_pressed(&"ascend"):
		entity.velocity.y = flying_speed;

	elif Input.is_action_pressed(&"descend"):
		entity.velocity.y = -flying_speed;

	elif _frame_basic_movement_direction.z != 0.0:
		entity.velocity.y = _frame_basic_movement_direction.y * flying_speed;

	else:
		flying_movement_requested = false;

	_flying_movement_requested_this_frame = flying_movement_requested;


func _handle_deceleration() -> void:
	var final_move_and_flying_speed: float = _get_final_move_and_flying_speed();

	if not _frame_basic_movement_direction:
		entity.velocity.x = move_toward(entity.velocity.x, 0.0, final_move_and_flying_speed);
		entity.velocity.z = move_toward(entity.velocity.z, 0.0, final_move_and_flying_speed);

	if _flying and not _flying_movement_requested_this_frame:
		entity.velocity.y = move_toward(entity.velocity.y, 0.0, final_move_and_flying_speed);


func _get_final_move_and_flying_speed() -> float:
	if _running: 
		return move_and_flying_speed_when_running;
	else: 
		return move_and_flying_speed;
