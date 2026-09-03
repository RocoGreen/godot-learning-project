@warning_ignore("empty_file")

#@tool
#
#class_name PlayableLunaSnowClapAbilityComponent
#extends ShapeCast3D
#
#
#signal healed_someone(amount: float);
#
#@export_group("Dependencies")
#@export var playable: PhysicsBody3D:
	#set(new_playable):
		#playable = new_playable;
		#
		#if Engine.is_editor_hint():
			#update_configuration_warnings();
#
#@export var luna_snow_identity: EntityIdentity = EntityIdentity.new():
	#set(new_luna_snow_identity):
		#if luna_snow_identity and Engine.is_editor_hint():
			#luna_snow_identity.changed.disconnect(_on_luna_snow_identity_changed);
#
		#luna_snow_identity = new_luna_snow_identity;
#
		#if Engine.is_editor_hint():
			#update_configuration_warnings();
#
			#if luna_snow_identity:
				#luna_snow_identity.changed.connect(_on_luna_snow_identity_changed);
#
#@export var camera_component: PlayableCameraComponent:
	#set(new_camera_component):
		#camera_component = new_camera_component;
		#
		#if Engine.is_editor_hint():
			#update_configuration_warnings();
#
#@export var weapon_component: PlayableLunaSnowWeaponComponent;
#
#@export_group("Settings")
#@export var time_seconds_to_start: float = 2.0;
#@export var duration_time_seconds: float = 8.0;
#@export var time_seconds_to_wait_before_next_clap: float = 1.0;
#@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_start: StringName = &"ability_2";
#
#@export_group("Settings Specific to Clap")
#@export var healing_per_clap: float = 60.0;
#@export var damage_per_clap: float = 50.0;
#@export var clap_max_length_meters: float = 40.0;
### Note: Clap VFX shows the visual reprensation of a clap. 
#@export var clap_vfx_display_duration_seconds: float = 1.0;
#
#var _starting: bool = false;
#var _active: bool = false;
#var _waiting_before_next_clap: bool = false;
#
#var _input_action_to_start_pressed_at_last_usage_ending: bool = false;
#
## Note: Clap VFX shows the visual reprensation of a clap. 
## And the start and end positions are only updated when wanting to show the vfx.
#var _show_clap_vfx: bool = false;
#var _start_clap_vfx_position: Vector3;
#var _end_clap_vfx_position: Vector3;
#
## This RayCast3D is used to detect if there is an obstacle at the clap's center if we try to clap
## towards where the direction the player is aiming at.
#@onready var obstacle_at_center_detector_ray_cast: RayCast3D = %ObstacleAtCenterDetector;
#
#@onready var debug_draw: DebugDraw3D = %DebugDraw3D;
#
#
#func _init() -> void:
	#if Engine.is_editor_hint() and luna_snow_identity:
		#luna_snow_identity.changed.connect(_on_luna_snow_identity_changed);
#
#
#func _ready() -> void:
	#if Engine.is_editor_hint(): return;
#
	#add_exception(playable);
#
#
#func _process(_delta: float) -> void:
	#if not _show_clap_vfx: return;
#
	#debug_draw.draw_line(
			#debug_draw.to_local(_start_clap_vfx_position),
			#debug_draw.to_local(_end_clap_vfx_position),
			#Color.CADET_BLUE,
			#10.0
	#);
#
#
#func _physics_process(_delta: float) -> void:
	#if Engine.is_editor_hint(): return;
#
	#if _input_action_to_start_pressed_at_last_usage_ending:
		#if not Input.is_action_pressed(input_action_to_start):
			#_input_action_to_start_pressed_at_last_usage_ending = false;
		#else:
			#return;
#
	#elif GameState.in_game_input_disabled:
		#return;
#
	#elif Input.is_action_pressed(input_action_to_start):
		#if not _active:
			#_start();
#
		#elif not _waiting_before_next_clap:
			#_clap();
			##_handle_ability();
#
#
#func _get_configuration_warnings() -> PackedStringArray:
	#var warnings: PackedStringArray = PackedStringArray();
	#
	#warnings.append_array(ConfigurationWarningLibrary.get_for_playable(playable));
#
	#warnings.append_array(ConfigurationWarningLibrary.get_for_camera_component(camera_component));
#
	#warnings.append_array(ConfigurationWarningLibrary.get_for_entity_identity(luna_snow_identity));
#
	#return warnings;
#
#
#func _start() -> void:
	#_starting = true;
	#print("Luna Clap Ability Starting...");
#
	#await get_tree().create_timer(time_seconds_to_start).timeout;
#
	#_starting = false;
	#_active = true;
	#print("Luna Clap Ability Started ! Press the input action to clap if you're not already.");
#
	#await get_tree().create_timer(duration_time_seconds).timeout;
#
	## Ending and resetting the ability.
	#_end_and_reset();
#
#
#func _clap() -> void:
	## The clap's start position in global space.
	#var where_clap_starts: Vector3 = _get_where_clap_starts();
	## The clap's end position in global space.
	#var where_clap_ends: Vector3 = _get_where_clap_ends();
	#var clap_length: float = where_clap_starts.distance_to(where_clap_ends);
#
	## look_at_from_position() works in global space.
	#look_at_from_position(where_clap_starts, where_clap_ends);
#
	#shape = shape as BoxShape3D;
	#shape.size.z = clap_length;
#
	#target_position.z = -(clap_length / 2.0);
#
	#force_shapecast_update();
	#_display_clap_vfx(where_clap_starts, where_clap_ends);
#
	#for collider_index: int in range(get_collision_count()):
		#var target: PhysicsBody3D = get_collider(collider_index) as PhysicsBody3D;
#
		#var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
		#var target_identity: EntityIdentity = target_entity_component.identity;
#
		#if target_identity.team == luna_snow_identity.team:
			#_apply_healing_to_target_entity(target);
		#else:
			#_apply_damage_to_target_entity(target);
#
	#_waiting_before_next_clap = true;
	#print("You just clapped ! In recovery for next shot...");
#
	#await get_tree().create_timer(time_seconds_to_wait_before_next_clap).timeout;
#
	#if _active:
		#_waiting_before_next_clap = false;
		#print("Recovery over ! Press the input action if you're not already to clap once more !");
#
#
##func _handle_ability() -> void:
	##var clap_start_position: Vector3 = _get_clap_start_position();
	##var position_to_clap_at: Vector3;
	##var clap_length: float = clap_max_length_meters;
##
	### First, let's get a position to point (look at) at the same direction the player is aiming at. 
##
	##var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();
##
	##if ray_to_get_what_player_aims_at_results.has("position"):
		### This ray point actually is the aim point of what the player is aiming at (technically at
		### what we want to detect if it's aimed at) but we only need to get a position to look at
		### where the player is aiming at and it can very much be used for that purpose plus accurate.
		##position_to_clap_at = ray_to_get_what_player_aims_at_results.get("position");
	##else:
		### This is the position to use if the player isn't aiming at anything in the world.
		### It's heuristic enough to be used reliably so let's do it !
		##position_to_clap_at = camera_component.get_position_to_look_at_aim_direction();
##
	### Usually, when you have a position to point at the same direction the player is aiming at,
	### you directly want if for example, a hitscan weapon, to create a ray from your weapon muzzle
	### to it then check what you hit. 
	### If it hits an obstacle, you just don't do anything because the bullet is considered blocked. 
	### If it hits an entity and they're not on the same team as the attacker, they get damaged by 
	### the bullet.
	### But the clap pierces through entities and blocked from going full range by the first obstacle 
	### it hits. 
	### So, we want to detect if there is an obstacle in it's center. To determine it's full range.
	### And since it will obviously change where to clap in the end, update the position to clap at.
	### To do this, we use a ray like you see below.
	### By the way, if it doesn't hit anything then we consider the clap full range.
##
	### Using look_at_from_position() with target_position.z to limit the ray cast to the 
	### maximum clap length instead of just changing target_position to directly be at the position 
	### to clap at.
	##obstacle_at_center_detector_ray_cast.look_at_from_position(clap_start_position, position_to_clap_at);
	##obstacle_at_center_detector_ray_cast.target_position.z = -clap_length;
##
	##obstacle_at_center_detector_ray_cast.force_raycast_update();
##
	##if obstacle_at_center_detector_ray_cast.is_colliding():
		### If the ray hits, it obviously changes where to clap in the end so let's update the 
		### variable.
		##position_to_clap_at = obstacle_at_center_detector_ray_cast.get_collision_point();
##
		### If the ray hits, it means the clap have a length that isn't equal to maximum one so let's
		### update the variable. 
		##clap_length = clap_start_position.distance_to(
				##obstacle_at_center_detector_ray_cast.get_collision_point()
		##);
##
	### We have everything we need. Now, it's time to clap.
##
	##look_at_from_position(clap_start_position, position_to_clap_at);
##
	### ShapeCast3D works by instead, casting a ray, the shape. Literally. 
##
	##shape = shape as BoxShape3D;
	##shape.size.z = clap_length;
##
	##target_position.z = -(clap_length / 2.0);
##
	##force_shapecast_update();
	##_draw_clap_debug_line(position_to_clap_at);
##
	##for collider_index: int in range(get_collision_count()):
		##var target: PhysicsBody3D = get_collider(collider_index) as PhysicsBody3D;
##
		##var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
		##var target_identity: EntityIdentity = target_entity_component.identity;
##
		##if target_identity.team == luna_snow_identity.team:
			##_apply_healing_to_target_entity(target);
		##else:
			##_apply_damage_to_target_entity(target);
##
	##lag_between_shots_timer.start();
#
#
#func _end_and_reset() -> void:
	#_active = false;
	#_waiting_before_next_clap = false;
#
	#if Input.is_action_pressed(input_action_to_start):
		#_input_action_to_start_pressed_at_last_usage_ending = true;
#
	#print("Luna Clap Ability Ended !");
#
#
### Get the clap's start position (in global space).
#func _get_where_clap_starts() -> Vector3:
	#return weapon_component.bullet_start_transform_anchor_marker_3d.global_position;
#
#
### Get the clap's end position (in global space). 
#func _get_where_clap_ends() -> Vector3:
	#var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();
#
	## The position in global space that'll be used to look at the same direction the player is 
	## aiming at.
	#var where_to_clap_at: Vector3;
	#if ray_to_get_what_player_aims_at_results.has("position"):
		#where_to_clap_at = ray_to_get_what_player_aims_at_results.get("position");
	#else:
		#where_to_clap_at = camera_component.get_position_to_look_at_aim_direction();
#
	## The clap's start position in global space.
	#var where_clap_starts: Vector3 = _get_where_clap_starts();
	#obstacle_at_center_detector_ray_cast.look_at_from_position(where_clap_starts, where_to_clap_at);
	#obstacle_at_center_detector_ray_cast.target_position.z = -clap_max_length_meters;
#
	#obstacle_at_center_detector_ray_cast.force_raycast_update();
#
	## The clap's end position in global space.
	#var where_clap_ends: Vector3;
	#if obstacle_at_center_detector_ray_cast.is_colliding():
		#where_clap_ends = obstacle_at_center_detector_ray_cast.get_collision_point();
	#else:
		## The clap direction from the position (in global space) it starts.
		#var clap_direction: Vector3 = where_clap_starts.direction_to(where_to_clap_at);
		#where_clap_ends = where_clap_starts + (clap_direction * clap_max_length_meters);
#
	#return where_clap_ends;
#
#
##func _is_obstacle_detected_from_clap_start_to_position(to_position: Vector3) -> void:
	##var where_clap_starts: Vector3 = _get_where_clap_starts();
	##obstacle_at_center_detector_ray_cast.look_at_from_position(where_clap_starts, to_position);
	##obstacle_at_center_detector_ray_cast.target_position.z = -clap_max_length_meters;
##
	##obstacle_at_center_detector_ray_cast.force_raycast_update();
##
	##return obstacle_at_center_detector_ray_cast.is_colliding();
#
#
#func _apply_healing_to_target_entity(target: PhysicsBody3D) -> void:
	#var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	#var target_health: EntityHealthComponent = target_entity_component.health_component;
#
	#if not target_health: return;
#
	#var final_healing_done: float = target_health.heal(healing_per_clap, luna_snow_identity);
#
	#if final_healing_done > 0.0:
		#healed_someone.emit(final_healing_done);
#
#
#func _apply_damage_to_target_entity(target: PhysicsBody3D) -> void:
	#var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	#var target_health: EntityHealthComponent = target_entity_component.health_component;
#
	#if not target_health: return;
#
	#target_health.damage(damage_per_clap, luna_snow_identity);
#
#
#func _display_clap_vfx(start_position: Vector3, end_position: Vector3) -> void:
	#_show_clap_vfx = true;
	#_start_clap_vfx_position = start_position;
	#_end_clap_vfx_position = end_position;
#
	#await get_tree().create_timer(clap_vfx_display_duration_seconds).timeout;
#
	#_show_clap_vfx = false;
#
#
#func _on_luna_snow_identity_changed() -> void:
	#update_configuration_warnings();
