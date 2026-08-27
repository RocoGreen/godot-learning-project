@tool

extends Area3D


const DamageBoostRequest := EntityDamageBoostStatusReceiver.DamageBoostRequest;

enum _State {
	HEALING,
	DAMAGE_BOOSTING,
};

@export_group("Dependencies")
@export var entity_identity: EntityIdentity = EntityIdentity.new():
	set(new_entity_identity):
		if entity_identity and Engine.is_editor_hint():
			entity_identity.changed.disconnect(_on_entity_identity_changed);

		entity_identity = new_entity_identity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

			if entity_identity:
				entity_identity.changed.connect(_on_entity_identity_changed);

@export var dancefloor_position_anchor: Marker3D:
	set(new_dancefloor_position_anchor):
		dancefloor_position_anchor = new_dancefloor_position_anchor;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Healing & Damage Settings")
@export var cast_healing_amount: float = 200.0;
@export var healing_amount: float = 250.0;
@export_range(0, 100) var damage_boost_amount: int = 40;

@export_group("Input Actions Settings")
@export_custom(PROPERTY_HINT_INPUT_NAME, "") var ultimate_input_action: StringName = &"ultimate";

var _apply_cast_healing: bool = false;

var _state: _State = _State.HEALING:
	set(new_state):
		if _state == new_state:
			return;
		
		if new_state == _State.HEALING:
			_dancefloor_mesh_material.set_albedo(Color.PINK);
		
		elif new_state == _State.DAMAGE_BOOSTING:
			_dancefloor_mesh_material.set_albedo(Color.SKY_BLUE);
		
		_state = new_state;

var _targets_inside_ultimate: Array[PhysicsBody3D] = [];
var _targets_damage_boosted_requests: Dictionary[PhysicsBody3D, DamageBoostRequest] = {};

var _pressing_again_ultimate_input_action_required: bool = false;

@onready var _dancefloor: MeshInstance3D = %Dancefloor;
@onready var _dancefloor_mesh_material: StandardMaterial3D = _dancefloor.mesh.material;

@onready var _duration_timer: Timer = %DurationTimer;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	_dancefloor.top_level = true;


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if dancefloor_position_anchor:
			_update_dancefloor_position();
			_dancefloor.show();

		elif _dancefloor.visible:
			_dancefloor.hide();

	elif _is_active() and dancefloor_position_anchor:
		_update_dancefloor_position();


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return;
	
	if _pressing_again_ultimate_input_action_required:
		if Input.is_action_pressed(ultimate_input_action):
			_pressing_again_ultimate_input_action_required = false;
		else:
			return;
	
	elif _is_active():
		if Input.is_action_just_pressed(ultimate_input_action):
			_toggle_ability_state();
		
		_handle_ultimate(delta);
	
	elif Input.is_action_pressed(ultimate_input_action):
		_start_ultimate(delta);


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLibrary.get_for_entity_identity(entity_identity));
	
	if not dancefloor_position_anchor:
		warnings.append(
				"`dancefloor_position_anchor` is not set. Without it, the dancefloor " + 
				"won't show in editor or if in game, when the ultimate is active."
		);
	
	return warnings;


func _start_ultimate(delta: float) -> void:
	if dancefloor_position_anchor:
		_update_dancefloor_position();
		_dancefloor.show();
	
	print(
			"Luna Snow Ultimate Started ! " + 
			"Press ultimate input action to toggle between dmg boost and healing !"
	);
	
	_duration_timer.start();
	
	_apply_cast_healing = true;
	
	_handle_ultimate(delta);
	
	_apply_cast_healing = false;


func _handle_ultimate(delta: float) -> void:
	if _is_active() and _state == _State.HEALING:
		for target: PhysicsBody3D in _targets_inside_ultimate:
			_apply_healing_to_target(target, delta);


func _end_ultimate() -> void:
	_remove_all_damage_boosted_targets();
	
	_dancefloor.hide();
	
	_state = _State.HEALING;
	
	if Input.is_action_pressed(ultimate_input_action):
		_pressing_again_ultimate_input_action_required = true;
	
	print("Luna Snow Ultimate Ended !");


func _update_dancefloor_position() -> void:
	_dancefloor.set_global_position(dancefloor_position_anchor.global_position);


func _is_active() -> bool:
	if _duration_timer.is_stopped():
		return false;
	else:
		return true;


func _toggle_ability_state() -> void:
	if _state == _State.HEALING:
		_apply_damage_boost_to_targets_inside_ultimate();
		
		_state = _State.DAMAGE_BOOSTING;

	elif _state == _State.DAMAGE_BOOSTING:
		_remove_all_damage_boosted_targets();
		
		_state = _State.HEALING;


func _apply_healing_to_target(target: PhysicsBody3D, delta: float) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;
	
	if not target_health: return;
	
	var healing_to_do: float = healing_amount * delta;

	if _apply_cast_healing: 
		healing_to_do = cast_healing_amount;
	
	target_health.heal(healing_to_do, entity_identity);


func _apply_damage_boost_to_target(target: PhysicsBody3D) -> void:
	if _targets_damage_boosted_requests.has(target): return;

	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_status_receiver_hub := target_entity_component.status_receiver_hub_component;
	
	if not target_status_receiver_hub: 
		return;

	var target_damage_boost_status_receiver := target_status_receiver_hub.damage_boost_receiver;

	var damage_boost_request: DamageBoostRequest = DamageBoostRequest.new();

	target_damage_boost_status_receiver.add_damage_boost_request(damage_boost_request);
	_targets_damage_boosted_requests.set(target, damage_boost_request);


func _apply_damage_boost_to_targets_inside_ultimate() -> void:
	for target: PhysicsBody3D in _targets_inside_ultimate:
		_apply_damage_boost_to_target(target);


func _remove_damage_boost_to_target(target: PhysicsBody3D) -> void:
	var damage_boost_request: DamageBoostRequest = _targets_damage_boosted_requests.get(target);

	if not damage_boost_request: return;

	_targets_damage_boosted_requests.erase(target);

	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_status_receiver_hub := target_entity_component.status_receiver_hub_component;
	
	if not target_status_receiver_hub: return;

	var target_damage_boost_status_receiver := target_status_receiver_hub.damage_boost_receiver;
	target_damage_boost_status_receiver.remove_damage_boost_request(damage_boost_request);


func _remove_all_damage_boosted_targets() -> void:
	for target: PhysicsBody3D in _targets_damage_boosted_requests.keys():
		_remove_damage_boost_to_target(target);


func _on_body_entered(body: Node3D) -> void:
	var target: PhysicsBody3D = body as PhysicsBody3D;

	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_identity: EntityIdentity = target_entity_component.identity;

	if not target_identity.team == entity_identity.team: return;

	_targets_inside_ultimate.append(target);

	if _is_active() and _state == _State.DAMAGE_BOOSTING:
		_apply_damage_boost_to_target(target);


func _on_body_exited(body: Node3D) -> void:
	var target: PhysicsBody3D = body as PhysicsBody3D;

	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_identity: EntityIdentity = target_entity_component.identity;

	if not target_identity.team == entity_identity.team: return;

	_targets_inside_ultimate.erase(target);

	if _is_active() and _state == _State.DAMAGE_BOOSTING:
		_remove_damage_boost_to_target(target);


func _on_duration_timer_timeout() -> void:
	_end_ultimate();


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();


class DamageBoostedTarget extends RefCounted:
	var request: DamageBoostRequest;
	var entity: PhysicsBody3D;

	@warning_ignore("shadowed_variable")
	func _init(request: DamageBoostRequest, entity: PhysicsBody3D) -> void:
		self.request = request;
		self.entity = entity;
