@warning_ignore("empty_file")

#@tool
#
## Also abbreviated to PlayableCBUtilsComponent.
##class_name PlayableCharacterBody3DUtilsComponent
#extends Node
#
#
#@export_group("Dependencies")
#@export var playable: CharacterBody3D:
	#set(new_playable):
		#playable = new_playable;
#
		#if Engine.is_editor_hint():
			#update_configuration_warnings();
#
#@export_group("Movement And Flying Settings")
#@export var movement_and_flying_speed: float = 20.0;
#@export var movement_and_flying_acceleration_rate: float = 200.0;
#@export var movement_and_flying_deceleration_rate: float = 500.0;
#
#@export_group("Running Related Settings")
#@export var movement_and_flying_speed_when_running: float = 40.0;
#
#@export_group("Jumping Settings")
#@export var jumping_force: float = 8.0;
#
#var disable_requests_handler: EntityRequestsHandler = EntityRequestsHandler.new();
#
#var _running: bool = false;
#var _flying: bool = false;
#
#
#func _ready() -> void:
	#if Engine.is_editor_hint(): return;
#
	#AssertLibrary.assert_if_playable_not_found(playable);
#
#
#func _physics_process(delta: float) -> void:
	#if Engine.is_editor_hint(): return;
	#if not disable_requests_handler.get_requests().is_empty(): return;
#
	#_apply_gravity_to_velocity(delta);
#
	#_apply_jumping_to_velocity();
#
	#_handle_running_toggle();
#
	#_handle_flying_toggle();
#
	#_apply_movement_and_flying_by_input_to_velocity(delta);
#
	#playable.move_and_slide();
#
#
#func _get_configuration_warnings() -> PackedStringArray:
	#return ConfigurationWarningLibrary.get_for_playable(playable);
#
#
#func _apply_gravity_to_velocity(delta: float) -> void:
	#if playable.is_on_floor(): return;
#
	#playable.velocity += playable.get_gravity() * delta;
#
#
#func _apply_jumping_to_velocity() -> void:
	#if not playable.is_on_floor() or not Input.is_action_just_pressed(&"jump"): 
		#return;
#
	#playable.velocity.y = jumping_force;
#
#
#func _apply_movement_and_flying_by_input_to_velocity(delta: float) -> void:
	#var target_velocity: Vector3 = Vector3.ZERO;
#
	#if not (Input.is_action_pressed(&"move_left") and Input.is_action_pressed(&"move_right")):
		#if Input.is_action_pressed(&"move_left"):
			#var left_direction_in_world: Vector3 = -playable.global_basis.x.normalized();
			#var input_action_strength: float = Input.get_action_strength(&"move_left");
#
			#target_velocity += lerp(Vector3.ZERO, left_direction_in_world, input_action_strength);
#
		#elif Input.is_action_pressed(&"move_right"):
			#var right_direction_in_world: Vector3 = playable.global_basis.x.normalized();
			#var input_action_strength: float = Input.get_action_strength(&"move_right");
#
			#target_velocity += lerp(Vector3.ZERO, right_direction_in_world, input_action_strength);
#
	#if not (Input.is_action_pressed(&"move_forward") and Input.is_action_pressed(&"move_backward")):
		#if Input.is_action_pressed(&"move_forward"):
			#var forward_direction_in_world: Vector3 = -playable.global_basis.z.normalized();
			#var input_action_strength: float = Input.get_action_strength(&"move_forward");
#
			#target_velocity += lerp(Vector3.ZERO, forward_direction_in_world, input_action_strength);
#
		#elif Input.is_action_pressed(&"move_backward"):
			#var backward_direction_in_world: Vector3 = playable.global_basis.z.normalized();
			#var input_action_strength: float = Input.get_action_strength(&"move_backward");
#
			#target_velocity += lerp(Vector3.ZERO, backward_direction_in_world, input_action_strength);
#
	#var final_movement_and_flying_speed: float = _get_final_movement_and_flying_speed();
#
	#target_velocity *= final_movement_and_flying_speed;
#
	#if target_velocity:
		##playable.velocity.x = target_velocity.x;
		##playable.velocity.z = target_velocity.z;
		#_apply_movement_acceleration_to_velocity(target_velocity, delta);
	#else:
		#_apply_movement_deceleration_to_velocity(delta);
#
	#if _flying:
		#if Input.is_action_pressed(&"ascend"):
			##playable.velocity.y = final_movement_and_flying_speed;
			#_apply_flying_acceleration_to_velocity(final_movement_and_flying_speed, delta);
#
		#elif Input.is_action_pressed(&"descend"):
			##playable.velocity.y = -final_movement_and_flying_speed;
			#_apply_flying_acceleration_to_velocity(-final_movement_and_flying_speed, delta);
#
		#elif not target_velocity.z == 0.0:
			##playable.velocity.y = target_velocity.y;
			#_apply_flying_acceleration_to_velocity(target_velocity.y, delta);
#
		#else:
			#_apply_flying_deceleration_to_velocity(delta);
#
#
#func _apply_movement_acceleration_to_velocity(target_velocity: Vector3, delta: float) -> void:
	#var acceleration_rate: float = movement_and_flying_acceleration_rate * delta;
#
	#playable.velocity.x = move_toward(playable.velocity.x, target_velocity.x, acceleration_rate);
	#playable.velocity.z = move_toward(playable.velocity.z, target_velocity.z, acceleration_rate);
#
#
#func _apply_movement_deceleration_to_velocity(delta: float) -> void:
	#var deceleration_rate: float = movement_and_flying_deceleration_rate * delta;
#
	#playable.velocity.x = move_toward(playable.velocity.x, 0.0, deceleration_rate);
	#playable.velocity.z = move_toward(playable.velocity.z, 0.0, deceleration_rate);
#
#
#func _apply_movement_deceleration_to_velocity_x(delta: float) -> void:
	#var deceleration_rate: float = movement_and_flying_deceleration_rate * delta;
#
	#playable.velocity.x = move_toward(playable.velocity.x, 0.0, deceleration_rate);
#
#
#func _apply_movement_deceleration_to_velocity_z(delta: float) -> void:
	#var deceleration_rate: float = movement_and_flying_deceleration_rate * delta;
#
	#playable.velocity.z = move_toward(playable.velocity.z, 0.0, deceleration_rate);
#
#
#func _apply_flying_acceleration_to_velocity(target_speed: float, delta: float) -> void:
	#var acceleration_rate: float = movement_and_flying_acceleration_rate * delta;
#
	#playable.velocity.y = move_toward(playable.velocity.y, target_speed, acceleration_rate);
#
#
#func _apply_flying_deceleration_to_velocity(delta: float) -> void:
	#var deceleration_speed: float = movement_and_flying_deceleration_rate * delta;
#
	#playable.velocity.y = move_toward(playable.velocity.y, 0.0, deceleration_speed);
#
#
#func _handle_flying_toggle() -> void:
	#if not Input.is_action_just_pressed(&"toggle_flying_mode"): return;
#
	#if _flying:
		#_flying = false;
	#else:
		#_flying = true;
#
#
#func _handle_running_toggle() -> void:
	#if Input.is_action_pressed(&"run"):
		#_running = true;
	#else:
		#_running = false;
#
#
#func _get_final_movement_and_flying_speed() -> float:
	#if _running: 
		#return movement_and_flying_speed_when_running;
	#else: 
		#return movement_and_flying_speed;
