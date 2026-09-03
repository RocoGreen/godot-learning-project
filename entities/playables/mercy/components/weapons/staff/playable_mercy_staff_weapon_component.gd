class_name PlayableMercyStaffWeaponComponent
extends Node3D


enum _Mode {
	HEALING,
	DAMAGE_BOOSTING,
};

@export_group("Dependencies")
@export var playable_mercy: CharacterBody3D;
@export var playable_mercy_identity: EntityIdentity;
@export var camera_component: PlayableCameraComponent;

@export_group("Settings")
@export var healing_amount_per_second: float = 60.0;
@export_range(0, 100) var damage_boost_amount_percentage: int = 40;
@export var target_entity_finder_maximum_range_meters: float = 40.0;

@export_group("Input Actions Settings")
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_heal := &"primary_fire";
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_damage_boost := &"secondary_fire";

var _target_entity: PhysicsBody3D;
var _target_entity_damage_boost_request: EntityDamageBoostStatusReceiver.DamageBoostRequest;

var _mode: _Mode = _Mode.HEALING;

var _vfx_start_position: Vector3;
var _vfx_end_position: Vector3;

@onready var target_entity_finder_ray_cast: RayCast3D = %TargetEntityFinder;

@onready var debug_draw: DebugDraw3D = %DebugDraw3D;


func _ready() -> void:
	target_entity_finder_ray_cast.add_exception(playable_mercy);


func _process(_delta: float) -> void:
	if not _target_entity: return;

	_update_vfx_positions();

	debug_draw.draw_line(
			debug_draw.to_local(_vfx_start_position),
			debug_draw.to_local(_vfx_end_position),
			Color.YELLOW if _mode == _Mode.HEALING else Color.SKY_BLUE,
			3.0
	);


func _physics_process(delta: float) -> void:
	if _target_entity:
		if (
				not Input.is_action_pressed(input_action_to_heal) \
				and \
				not Input.is_action_pressed(input_action_to_damage_boost)
		):
			_end_and_reset();

		elif Input.is_action_pressed(input_action_to_heal) and Input.is_action_just_pressed(input_action_to_damage_boost):
			_switch_from_healing_to_damage_boost_mode();

		elif Input.is_action_pressed(input_action_to_damage_boost) and Input.is_action_just_pressed(input_action_to_heal):
			_switch_from_damage_boost_to_healing_mode(delta);

		elif _mode == _Mode.HEALING:
			if Input.is_action_pressed(input_action_to_damage_boost) and not Input.is_action_pressed(input_action_to_heal):
				_switch_from_healing_to_damage_boost_mode();
			else:
				_heal_target_entity(delta);

		elif _mode == _Mode.DAMAGE_BOOSTING and Input.is_action_pressed(input_action_to_heal) and not Input.is_action_pressed(input_action_to_damage_boost):
			_switch_from_damage_boost_to_healing_mode(delta);

	else:
		if Input.is_action_pressed(input_action_to_heal) and _can_entity_player_aims_at_be_healed():
			_start_healing_entity_player_aims_at(delta);

		elif Input.is_action_pressed(input_action_to_damage_boost) and _can_entity_player_aims_at_be_damage_boosted():
			_start_damage_boosting_entity_player_aims_at();


func _find_target_entity_player_aims_at() -> PhysicsBody3D:
	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();
	
	if ray_to_get_what_player_aims_at_results.is_empty():
		return;

	var target_aimed_at_aim_point: Vector3 = ray_to_get_what_player_aims_at_results.position;

	target_entity_finder_ray_cast.look_at(target_aimed_at_aim_point);
	target_entity_finder_ray_cast.target_position.z = -target_entity_finder_maximum_range_meters;

	target_entity_finder_ray_cast.force_raycast_update();

	if target_entity_finder_ray_cast.is_colliding():
		var target_hit: PhysicsBody3D = target_entity_finder_ray_cast.get_collider();
		
		if target_hit.is_in_group(&"entities"):
			var target_entity_component: EntityComponent = EntityComponent.from_entity(target_hit);
			var target_position_anchor_hub := target_entity_component.position_anchor_hub_component;
			
			if not target_position_anchor_hub: 
				return null;
			
			if not target_position_anchor_hub.center_anchor:
				return null;
			
			return target_hit;
		else: 
			return null;

	else:
		return null;


func _can_entity_player_aims_at_be_healed() -> bool:
	var entity: PhysicsBody3D = _find_target_entity_player_aims_at();

	if not entity:
		return false;

	if _can_this_entity_be_healed(entity):
		return true;
	else:
		return false;


func _can_this_entity_be_healed(entity: PhysicsBody3D) -> bool:
	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var entity_health_component := entity_entity_component.health_component;

	if entity_health_component:
		return true;
	else:
		return false;


func _start_healing_entity_player_aims_at(delta: float) -> void:
	var entity_aimed_at: PhysicsBody3D = _find_target_entity_player_aims_at();

	_start_healing_this_entity(entity_aimed_at, delta);


func _start_healing_this_entity(entity: PhysicsBody3D, delta: float) -> void:
	_mode = _Mode.HEALING;
	_target_entity = entity;

	_heal_target_entity(delta);


func _heal_target_entity(delta: float) -> void:
	var target_entity_entity_component: EntityComponent = EntityComponent.from_entity(_target_entity);
	var target_entity_health_component := target_entity_entity_component.health_component;

	target_entity_health_component.heal(healing_amount_per_second * delta, playable_mercy_identity);


func _can_entity_player_aims_at_be_damage_boosted() -> bool:
	var entity: PhysicsBody3D = _find_target_entity_player_aims_at();

	if not entity:
		return false;

	if _can_this_entity_be_damage_boosted(entity):
		return true;
	else:
		return false;


func _can_this_entity_be_damage_boosted(entity: PhysicsBody3D) -> bool:
	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var entity_status_receiver_hub := entity_entity_component.status_receiver_hub_component;

	if entity_status_receiver_hub:
		return true;
	else:
		return false;


func _start_damage_boosting_entity_player_aims_at() -> void:
	var entity_aimed_at: PhysicsBody3D = _find_target_entity_player_aims_at();

	_start_damage_boosting_this_entity(entity_aimed_at);


func _start_damage_boosting_this_entity(entity: PhysicsBody3D) -> void:
	if _target_entity_damage_boost_request:
		_end_damage_boost_to_target_entity();
	
	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var entity_status_receiver_hub := entity_entity_component.status_receiver_hub_component;
	
	var damage_boost_request := EntityDamageBoostStatusReceiver.DamageBoostRequest.new(
		damage_boost_amount_percentage,
		playable_mercy_identity
	);
	entity_status_receiver_hub.damage_boost_receiver.add_damage_boost_request(damage_boost_request);
	_target_entity_damage_boost_request = damage_boost_request;

	_target_entity = entity;
	_mode = _Mode.DAMAGE_BOOSTING;


func _end_damage_boost_to_target_entity() -> void:
	var entity_entity_component: EntityComponent = EntityComponent.from_entity(_target_entity);
	var entity_status_receiver_hub := entity_entity_component.status_receiver_hub_component;

	entity_status_receiver_hub.damage_boost_receiver.remove_damage_boost_request(
			_target_entity_damage_boost_request
	);
	
	_target_entity_damage_boost_request = null;


func _switch_from_healing_to_damage_boost_mode() -> void:
	if _can_this_entity_be_damage_boosted(_target_entity):
		_start_damage_boosting_this_entity(_target_entity);

	elif _can_entity_player_aims_at_be_damage_boosted():
		_start_damage_boosting_entity_player_aims_at();

	else:
		_end_and_reset();


func _switch_from_damage_boost_to_healing_mode(delta: float) -> void:
	_end_damage_boost_to_target_entity();

	if _can_this_entity_be_healed(_target_entity):
		_start_healing_this_entity(_target_entity, delta);

	elif _can_entity_player_aims_at_be_healed():
		_start_healing_entity_player_aims_at(delta);

	else:
		_end_and_reset();


func _update_vfx_positions() -> void:
	_vfx_start_position = target_entity_finder_ray_cast.global_position;

	var target_entity_entity_component: EntityComponent = EntityComponent.from_entity(_target_entity);
	var target_entity_position_anchor_hub := target_entity_entity_component.position_anchor_hub_component;

	_vfx_end_position = target_entity_position_anchor_hub.center_anchor.global_position;


func _end_and_reset() -> void:
	if _target_entity_damage_boost_request:
		_end_damage_boost_to_target_entity();

	_target_entity = null;
