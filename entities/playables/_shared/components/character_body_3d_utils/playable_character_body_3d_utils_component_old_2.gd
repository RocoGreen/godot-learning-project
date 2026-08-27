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
#@export_group("Diagonal and Flying Movement Settings")
### How fast to move diagonally and fly in meters per second.
#@export var diagonal_and_flying_movement_speed: float = 20.0;
### How fast to decelerate in meters per second until velocity reaches 0.
#@export var diagonal_and_flying_movement_deceleration_speed: float = 50.0;
#
#@export_group("Running Related Settings")
### How fast to move diagonally and fly when running in meters per second.
#@export var diagonal_and_flying_movement_speed_when_running: float = 40.0;
#
#@export_group("Jumping Settings")
### How strong to jump (by doing a sudden velocity boost to y axis) in meters.
#@export var jumping_force: float = 8.0;
#
#var disable_requests_handler: EntityRequestsHandler = EntityRequestsHandler.new();
#
#var _disable_component_requests: Array[DisableComponentRequest] = [];
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
	#if not _disable_component_requests.is_empty(): return;
#
	#_handle_gravity(delta);
#
	#_handle_jumping();
#
	#_handle_running_toggle();
#
	#_handle_flying_toggle();
#
	#_handle_diagonal_and_flying_movement_by_input(delta);
#
	## Note: move_and_slide() automatically multiply the velocity by delta.
	#playable.move_and_slide();
#
#
#func _get_configuration_warnings() -> PackedStringArray:
	#return ConfigurationWarningLibrary.get_for_playable(playable);
#
#
#func add_disable_component_request(request: DisableComponentRequest) -> void:
	#_disable_component_requests.append(request);
#
#
#func remove_disable_component_request(request: DisableComponentRequest) -> void:
	#_disable_component_requests.erase(request);
#
#
#func _handle_gravity(delta: float) -> void:
	#if playable.is_on_floor(): return;
#
	## Note: According to Godot docs, the gravity from get_gravity() have to be 
	## multipled by delta because it runs on it's own clock. It is still frame
	## dependant though so to make it per second, a second multiplication with
	## delta have to be made.
	#playable.velocity += playable.get_gravity() * delta;
#
#
#func _handle_jumping() -> void:
	#if not Input.is_action_just_pressed(&"jump"): return;
	#if not playable.is_on_floor(): return;
#
	## Note: The jumping works here by applying a sudden velocity boost.
	#playable.velocity.y = jumping_force;
#
#
#func _handle_diagonal_and_flying_movement_by_input(delta: float) -> void:
	#var final_velocity: Vector3 = Vector3.ZERO;
#
	## For now, we give to final_velocity it's direction. 
	## For velocity, it's used to know where to go.
#
	#if not (Input.is_action_pressed(&"move_left") and Input.is_action_pressed(&"move_right")):
		#if Input.is_action_pressed(&"move_left"):
			#var left_direction_in_world: Vector3 = -playable.global_basis.x.normalized();
			#var input_action_strength: float = Input.get_action_strength(&"move_left");
#
			#final_velocity += lerp(Vector3.ZERO, left_direction_in_world, input_action_strength);
#
		#elif Input.is_action_pressed(&"move_right"):
			#var right_direction_in_world: Vector3 = playable.global_basis.x.normalized();
			#var pressed_action_strength: float = Input.get_action_strength(&"move_right");
#
			#final_velocity += lerp(Vector3.ZERO, right_direction_in_world, pressed_action_strength);
#
	#if not (Input.is_action_pressed(&"move_forward") and Input.is_action_pressed(&"move_backward")):
		#if Input.is_action_pressed(&"move_forward"):
			#var forward_direction_in_world: Vector3 = -playable.global_basis.z.normalized();
			#var input_action_strength: float = Input.get_action_strength(&"move_forward");
#
			#final_velocity += lerp(Vector3.ZERO, forward_direction_in_world, input_action_strength);
#
		#elif Input.is_action_pressed(&"move_backward"):
			#var backward_direction_in_world: Vector3 = playable.global_basis.z.normalized();
			#var input_action_strength: float = Input.get_action_strength(&"move_backward");
#
			#final_velocity += lerp(Vector3.ZERO, backward_direction_in_world, input_action_strength);
#
	## Now the direction is applied, let's apply the magnitude (for velocity, 
	## it's used to know how fast to move).
	#final_velocity *= _get_final_diagonal_and_flying_movement_speed();
#
	#if final_velocity != Vector3.ZERO:
		## Note: We only want diagonal movement here so we don't want to touch
		## playable velocity's y axis.
		#playable.velocity.x = final_velocity.x;
		#playable.velocity.z = final_velocity.z;
	#else:
		#_handle_diagonal_movement_deceleration(delta);
#
	#if _flying:
		#if Input.is_action_pressed(&"ascend"):
			#playable.velocity.y = _get_final_diagonal_and_flying_movement_speed();
#
		#elif Input.is_action_pressed(&"descend"):
			#playable.velocity.y = -_get_final_diagonal_and_flying_movement_speed();
#
		## If there is a request to move forward or backward,
		## it's logical to also count the y axis if flying.
		#elif final_velocity.z != 0.0:
			#playable.velocity.y = final_velocity.y;
#
		#else:
			#_handle_flying_movement_deceleration(delta);
#
#
#func _handle_diagonal_movement_deceleration(delta: float) -> void:
	## Multiplying by delta to make it per second.
	#var deceleration_speed: float = diagonal_and_flying_movement_deceleration_speed * delta;
#
	#playable.velocity.x = move_toward(playable.velocity.x, 0.0, deceleration_speed);
	#playable.velocity.z = move_toward(playable.velocity.z, 0.0, deceleration_speed);
#
#
#func _handle_flying_movement_deceleration(delta: float) -> void:
	## Multiplying by delta to make it per second.
	#var deceleration_speed: float = diagonal_and_flying_movement_deceleration_speed * delta;
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
#func _get_final_diagonal_and_flying_movement_speed() -> float:
	#if _running: 
		#return diagonal_and_flying_movement_speed_when_running;
	#else: 
		#return diagonal_and_flying_movement_speed;
#
#
#class DisableComponentRequest extends RefCounted:
	#pass;
