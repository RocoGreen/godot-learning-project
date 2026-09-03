@tool

class_name PlayableLunaSnowUltimateComponent
extends Area3D


signal healed_someone(amount: float);

enum _State {
	HEALING,
	DAMAGE_BOOSTING,
};

@export_group("Dependencies")
@export var luna_snow_identity: EntityIdentity = EntityIdentity.new():
	set(new_luna_snow_identity):
		if luna_snow_identity and Engine.is_editor_hint():
			luna_snow_identity.changed.disconnect(_on_luna_snow_identity_changed);

		luna_snow_identity = new_luna_snow_identity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

			if luna_snow_identity:
				luna_snow_identity.changed.connect(_on_luna_snow_identity_changed);

@export var dancefloor_position_anchor: Marker3D:
	set(new_dancefloor_position_anchor):
		dancefloor_position_anchor = new_dancefloor_position_anchor;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Settings")
@export var duration_seconds: float = 12.0;
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var input_action_to_use: StringName = &"ultimate";

@export_group("Healing & Damage Settings")
@export var burst_healing_amount_when_just_started: float = 200.0;
@export var healing_amount_per_second: float = 250.0;
@export_range(0, 100) var damage_boost_amount_percentage: int = 40;

var _active: bool = false;
var _just_started: bool = false;

var _state: _State = _State.HEALING:
	set(new_state):
		if _state == new_state:
			return;
		
		if new_state == _State.HEALING:
			_dancefloor_mesh_material.set_albedo(Color.PINK);
		
		elif new_state == _State.DAMAGE_BOOSTING:
			_dancefloor_mesh_material.set_albedo(Color.SKY_BLUE);
		
		_state = new_state;

var _entities_inside_ultimate: Array[PhysicsBody3D] = [];
var _damage_boosted_entities_requests: Dictionary[PhysicsBody3D, EntityDamageBoostRequest] = {};

var _input_action_to_start_pressed_at_last_usage_ending: bool = false;

@onready var _dancefloor: MeshInstance3D = %Dancefloor;
@onready var _dancefloor_mesh_material: StandardMaterial3D = _dancefloor.mesh.material;


func _init() -> void:
	if Engine.is_editor_hint() and luna_snow_identity:
		luna_snow_identity.changed.connect(_on_luna_snow_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	body_entered.connect(_on_body_entered);
	body_exited.connect(_on_body_exited);

	_dancefloor.top_level = true;


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if dancefloor_position_anchor:
			_update_dancefloor_position();
			_dancefloor.show();

		elif _dancefloor.visible:
			_dancefloor.hide();

	elif _active and dancefloor_position_anchor:
		_update_dancefloor_position();


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return;
	
	if _input_action_to_start_pressed_at_last_usage_ending:
		if Input.is_action_pressed(input_action_to_use):
			_input_action_to_start_pressed_at_last_usage_ending = false;
		else:
			return;

	elif _active:
		if _just_started:
			_just_started = false;
		
		if not GameState.in_game_input_disabled:
			if Input.is_action_just_pressed(input_action_to_use):
				_toggle_state();
		
		if _state == _State.HEALING:
			_heal_entities_inside_ultimate(delta);

	elif not GameState.in_game_input_disabled and Input.is_action_pressed(input_action_to_use):
		_start(delta);


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity_identity(luna_snow_identity));
	
	if not dancefloor_position_anchor:
		warnings.append(
				"`dancefloor_position_anchor` is not set.\n" +
				"Without it, the dancefloor won't show in editor or if in " + 
				"game, when the ultimate is active.\n" +
				"If not desired, please add a `Marker3D` as child of this " +
				"component and position it where you want the dance floor " +
				"to appear.\n" +
				"Then, assign it to the exported variable."
		);
	
	return warnings;


func _start(delta: float) -> void:
	_active = true;
	_just_started = true;
	
	if dancefloor_position_anchor:
		_update_dancefloor_position();
		_dancefloor.show();

	print(
			"Luna Snow Ultimate started !\n" + 
			"Press the input action again to toggle between healing and damage boost mode !"
	);

	_heal_entities_inside_ultimate(delta);

	await get_tree().create_timer(duration_seconds).timeout;

	_end_and_reset();


func _end_and_reset() -> void:
	_active = false;
	_just_started = false;

	_remove_all_damage_boosted_entities();

	_dancefloor.hide();

	_state = _State.HEALING;

	if Input.is_action_pressed(input_action_to_use):
		_input_action_to_start_pressed_at_last_usage_ending = true;

	print("Luna Snow Ultimate ended.");


func _update_dancefloor_position() -> void:
	_dancefloor.set_global_position(dancefloor_position_anchor.global_position);


func _toggle_state() -> void:
	if _state == _State.HEALING:
		_apply_damage_boost_to_entities_inside_ultimate();

		_state = _State.DAMAGE_BOOSTING;

	elif _state == _State.DAMAGE_BOOSTING:
		_remove_all_damage_boosted_entities();

		_state = _State.HEALING;


func _heal_entities_inside_ultimate(delta: float) -> void:
	for target: PhysicsBody3D in _entities_inside_ultimate:
		_apply_healing_to_entity(target, delta);


func _apply_healing_to_entity(entity: PhysicsBody3D, delta: float) -> void:
	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var target_health: EntityHealthComponent = entity_entity_component.health_component;

	if not target_health: return;

	var healing_to_do: float = healing_amount_per_second * delta;

	if _just_started: 
		healing_to_do = burst_healing_amount_when_just_started;

	var final_healing_done: float = target_health.heal(healing_to_do, luna_snow_identity);

	if final_healing_done > 0.0:
		healed_someone.emit(final_healing_done);


func _apply_damage_boost_to_entity(entity: PhysicsBody3D) -> void:
	if _damage_boosted_entities_requests.has(entity): return;

	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var target_status_receiver_hub := entity_entity_component.status_receiver_hub_component;

	if not target_status_receiver_hub: return;

	var damage_boost_request: EntityDamageBoostRequest = EntityDamageBoostRequest.new(
			damage_boost_amount_percentage, 
			luna_snow_identity
	);
	target_status_receiver_hub.damage_boost_receiver.add_damage_boost_request(damage_boost_request);
	_damage_boosted_entities_requests.set(entity, damage_boost_request);


func _apply_damage_boost_to_entities_inside_ultimate() -> void:
	for entity_inside_ultimate: PhysicsBody3D in _entities_inside_ultimate:
		_apply_damage_boost_to_entity(entity_inside_ultimate);


func _remove_damage_boost_to_entity(entity: PhysicsBody3D) -> void:
	if not _damage_boosted_entities_requests.has(entity): return;

	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var target_status_receiver_hub := entity_entity_component.status_receiver_hub_component;

	if not target_status_receiver_hub: return;

	target_status_receiver_hub.damage_boost_receiver.remove_damage_boost_request(
			_damage_boosted_entities_requests.get(entity)
	);

	_damage_boosted_entities_requests.erase(entity);


func _remove_all_damage_boosted_entities() -> void:
	for damage_boosted_entity: PhysicsBody3D in _damage_boosted_entities_requests.keys():
		_remove_damage_boost_to_entity(damage_boosted_entity);


func _on_body_entered(body: Node3D) -> void:
	var entity: PhysicsBody3D = body as PhysicsBody3D;

	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var target_identity: EntityIdentity = entity_entity_component.identity;

	if not target_identity.team == luna_snow_identity.team: return;

	_entities_inside_ultimate.append(entity);

	if not _active: return; 
	if _state != _State.DAMAGE_BOOSTING: return;

	_apply_damage_boost_to_entity(entity);


func _on_body_exited(body: Node3D) -> void:
	var entity: PhysicsBody3D = body as PhysicsBody3D;

	var entity_entity_component: EntityComponent = EntityComponent.from_entity(entity);
	var entity_identity: EntityIdentity = entity_entity_component.identity;

	if not entity_identity.team == luna_snow_identity.team: return;

	_entities_inside_ultimate.erase(entity);

	if not _active: return; 
	if _state != _State.DAMAGE_BOOSTING: return;

	_remove_damage_boost_to_entity(entity);


func _on_luna_snow_identity_changed() -> void:
	update_configuration_warnings();
