class_name PlayableMercyStaffWeaponComponent
extends Node3D


enum _Mode {
	HEALING,
	DAMAGE_BOOSTING,
};

@export_group("Dependencies")
@export var playable_mercy: PlayableMercy;
@export var playable_mercy_identity: PlayableMercyIdentity;

@export_subgroup("Components")
@export var camera_component: PlayableCameraComponent;
@export var pistol_weapon_component: PlayableMercyPistolWeaponComponent;
@export var ultimate_component: PlayableMercyUltimateComponent;

@export_group("Weapon Settings")
@export var default_weapon_held: bool = true;
@export var time_seconds_to_swap_to_weapon: float = 0.2;

@export_group("Beam Settings")
@export var beam_maximum_range_meters: float = 15.0;
@export_range(0, 100) var beam_maximum_range_meters_increase_percentage_when_ulting: int = 100;
@export var beam_linger_effect_duration_seconds: float = 1.3;

@export_subgroup("Healing Beam")
@export var healing_amount_per_second: float = 55.0;
@export var healing_amount_per_second_when_ulting: float = 65.0;

@export_subgroup("Damage Boost Beam")
@export_range(0, 100) var damage_boost_amount_percentage: int = 40;

@export_group("Input Actions Settings")
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_heal := &"primary_fire";
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_damage_boost := &"secondary_fire";

var _held: bool = false;
var _swapped_to_weapon_this_frame: bool = false;
var _swapping_to_weapon: bool = false;

var _active: bool = false;
var _beam_target: PhysicsBody3D: get = get_beam_target;
var _beam_target_damage_boost_request: EntityDamageBoostStatusReceiver.DamageBoostRequest;

var _mode: _Mode = _Mode.HEALING;

@onready var debug_draw: DebugDraw3D = %DebugDraw3D;

@onready var beam_target_finder_ray_cast: RayCast3D = %BeamTargetFinder;
@onready var beam_linger_effect_timer: Timer = %BeamLingerEffectTimer;

@onready var time_to_swap_to_weapon_timer: Timer = %TimeToSwapToWeaponTimer;

@onready var mesh_instance: MeshInstance3D = %MeshInstance;


func _ready() -> void:
	_held = default_weapon_held;

	if not _held:
		mesh_instance.hide();

	beam_target_finder_ray_cast.add_exception(playable_mercy);


func _process(_delta: float) -> void:
	if not _active: return;

	_display_beam_debug_vfx();


func _physics_process(delta: float) -> void:
	if _swapped_to_weapon_this_frame:
		_swapped_to_weapon_this_frame = false;

	elif _held and Input.is_action_just_pressed(&"swap_weapon"):
		swap_to_pistol_weapon();
		return;

	if not _held or _swapping_to_weapon: return;

	var input_action_to_heal_pressed: bool = Input.is_action_pressed(input_action_to_heal);
	var input_action_to_damage_boost_pressed := Input.is_action_pressed(input_action_to_damage_boost);

	if _active:
		if not input_action_to_heal_pressed and not input_action_to_damage_boost_pressed:
			_end_and_reset();
			return;

		elif _is_switch_from_healing_to_damage_boost_beam_requested():
			_start_damage_boost_beam_to_entity(_beam_target);

		elif _is_switch_from_damage_boost_to_healing_beam_requested():
			_start_healing_beam_to_entity(_beam_target, delta);

		elif _mode == _Mode.HEALING:
			_heal_beam_target(delta);

		if _is_entity_center_position_visible_and_in_range(_beam_target):
			if not beam_linger_effect_timer.is_stopped():
				beam_linger_effect_timer.stop();

		elif beam_linger_effect_timer.is_stopped():
			beam_linger_effect_timer.start(beam_linger_effect_duration_seconds);

	else:
		if Input.is_action_pressed(input_action_to_heal):
			_start_healing_beam_to_entity_player_aims_at(delta);

		elif Input.is_action_pressed(input_action_to_damage_boost):
			_start_damage_boost_beam_to_entity_player_aims_at();


func swap_to_this_weapon() -> void:
	_held = true;
	mesh_instance.show();

	_swapped_to_weapon_this_frame = true;

	time_to_swap_to_weapon_timer.start(time_seconds_to_swap_to_weapon);
	_swapping_to_weapon = true;


func swap_to_pistol_weapon() -> void:
	if _active:
		_end_and_reset();

	_held = false;
	mesh_instance.hide();

	if not time_to_swap_to_weapon_timer.is_stopped():
		time_to_swap_to_weapon_timer.stop();

	pistol_weapon_component.swap_to_this_weapon();


func get_beam_target() -> PhysicsBody3D:
	return _beam_target;


func _start_healing_beam_to_entity_player_aims_at(delta: float) -> void:
	var entity_aimed_at: PhysicsBody3D = _get_entity_player_aims_at();

	if not entity_aimed_at: return;
	if not _is_entity_center_position_visible_and_in_range(entity_aimed_at): return;

	_start_healing_beam_to_entity(entity_aimed_at, delta);


func _start_healing_beam_to_entity(entity: PhysicsBody3D, delta: float) -> void:
	if _active and _mode == _Mode.DAMAGE_BOOSTING and _beam_target_damage_boost_request:
		_end_damage_boost_to_beam_target();

	if not _active:
		_active = true;

	_beam_target = entity;
	_mode = _Mode.HEALING;

	_heal_beam_target(delta);


func _heal_beam_target(delta: float) -> void:
	var beam_target_health_component := EntityHealthComponent.from_entity(_beam_target);

	if not beam_target_health_component: return;

	var final_healing_amount_per_second: float = healing_amount_per_second;

	if ultimate_component.is_active():
		final_healing_amount_per_second = healing_amount_per_second_when_ulting;

	final_healing_amount_per_second *= delta;

	beam_target_health_component.heal(final_healing_amount_per_second, playable_mercy_identity);


func _start_damage_boost_beam_to_entity_player_aims_at() -> void:
	var entity_aimed_at: PhysicsBody3D = _get_entity_player_aims_at();

	if not entity_aimed_at: return;
	if not _is_entity_center_position_visible_and_in_range(entity_aimed_at): return;

	_start_damage_boost_beam_to_entity(entity_aimed_at);


func _start_damage_boost_beam_to_entity(entity: PhysicsBody3D) -> void:
	if not _active:
		_active = true;

	_beam_target = entity;
	_mode = _Mode.DAMAGE_BOOSTING;

	var entity_damage_boost_status_receiver := EntityDamageBoostStatusReceiver.from_entity(entity);

	if not entity_damage_boost_status_receiver: return;

	var damage_boost_request := EntityDamageBoostStatusReceiver.DamageBoostRequest.new(
			damage_boost_amount_percentage,
			playable_mercy_identity
	);

	entity_damage_boost_status_receiver.add_damage_boost_request(damage_boost_request);
	_beam_target_damage_boost_request = damage_boost_request;


func _end_damage_boost_to_beam_target() -> void:
	var beam_target_damage_boost_status_receiver := EntityDamageBoostStatusReceiver.from_entity(
			_beam_target
	);

	if beam_target_damage_boost_status_receiver:
		beam_target_damage_boost_status_receiver.remove_damage_boost_request(
				_beam_target_damage_boost_request
		);

	_beam_target_damage_boost_request = null;


func _display_beam_debug_vfx() -> void:
	var beam_target_center_position: Vector3 = \
			EntityPositionAnchorHubComponent.get_center_position_of_entity(_beam_target);

	if not beam_target_center_position: return; 

	debug_draw.draw_line(
			debug_draw.to_local(beam_target_finder_ray_cast.global_position),
			debug_draw.to_local(beam_target_center_position),
			Color.YELLOW if _mode == _Mode.HEALING else Color.SKY_BLUE,
			3.0
	);


func _end_and_reset() -> void:
	if _active and _mode == _Mode.DAMAGE_BOOSTING and _beam_target_damage_boost_request:
		_end_damage_boost_to_beam_target();

	_active = false;
	_beam_target = null;


func _get_entity_player_aims_at() -> PhysicsBody3D:
	var ray_to_get_what_is_aimed_at_results: Dictionary = camera_component.ray_to_aim_direction();

	if ray_to_get_what_is_aimed_at_results.is_empty(): 
		return null;
	
	var what_is_aimed_at: Object = ray_to_get_what_is_aimed_at_results.get("collider");

	if not EntityComponent.is_object_an_entity(what_is_aimed_at):
		return null;

	var entity_aimed_at: PhysicsBody3D = EntityComponent.cast_object_to_entity(what_is_aimed_at);

	return entity_aimed_at;


func _is_entity_center_position_visible_and_in_range(entity: PhysicsBody3D) -> bool:
	var entity_center_position: Vector3 = \
			EntityPositionAnchorHubComponent.get_center_position_of_entity(entity);

	if not entity_center_position:
		return false;

	beam_target_finder_ray_cast.look_at(entity_center_position);
	
	var final_beam_maximum_range_meters: float = beam_maximum_range_meters;
	
	if ultimate_component.is_active():
		final_beam_maximum_range_meters += _percentage_of_float(
				beam_maximum_range_meters_increase_percentage_when_ulting,
				final_beam_maximum_range_meters,
		);

	beam_target_finder_ray_cast.target_position.z = -final_beam_maximum_range_meters;

	beam_target_finder_ray_cast.force_raycast_update();

	var entity_center_position_is_visible_and_in_range: bool = false;

	while(beam_target_finder_ray_cast.is_colliding()):
		var beam_target_finder_ray_cast_collider: Object = beam_target_finder_ray_cast.get_collider();

		if not EntityComponent.is_object_an_entity(beam_target_finder_ray_cast_collider):
			break;

		elif beam_target_finder_ray_cast_collider == entity:
			entity_center_position_is_visible_and_in_range = true;
			break;

		beam_target_finder_ray_cast.add_exception(beam_target_finder_ray_cast_collider);
		beam_target_finder_ray_cast.force_raycast_update();

	beam_target_finder_ray_cast.clear_exceptions();
	beam_target_finder_ray_cast.add_exception(playable_mercy);

	return entity_center_position_is_visible_and_in_range;


func _is_switch_from_healing_to_damage_boost_beam_requested() -> bool:
	if Input.is_action_pressed(input_action_to_heal): 
		if Input.is_action_just_pressed(input_action_to_damage_boost):
			return true;

	if _mode == _Mode.HEALING and Input.is_action_pressed(input_action_to_damage_boost):
		if not Input.is_action_pressed(input_action_to_heal):
			return true;

	return false;


func _is_switch_from_damage_boost_to_healing_beam_requested() -> bool:
	if Input.is_action_pressed(input_action_to_damage_boost): 
		if Input.is_action_just_pressed(input_action_to_heal):
			return true;

	if _mode == _Mode.DAMAGE_BOOSTING and Input.is_action_pressed(input_action_to_heal):
		if not Input.is_action_pressed(input_action_to_damage_boost):
			return true;

	return false;


func _percentage_of_float(percentage: int, of: float) -> float:
	return (float(percentage) * of) / 100.0;


func _on_beam_linger_effect_timer_timeout() -> void:
	_end_and_reset();


func _on_time_to_swap_to_weapon_timer_timeout() -> void:
	_swapping_to_weapon = false;
