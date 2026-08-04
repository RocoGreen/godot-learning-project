@tool

extends Area3D


enum _State {
	HEAL,
	DAMAGE_BOOST,
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

@export_group("Settings")
@export var cast_healing_amount: float = 200.0;
@export var healing_amount: float = 250.0;
@export_range(0, 100) var damage_boost_amount: int = 40;

var _apply_cast_healing: bool = false;

var _state: _State = _State.HEAL:
	set(new_state):
		if _state == new_state:
			return;
		
		if new_state == _State.HEAL:
			_dancefloor_mesh_material.set_albedo(Color.PINK);
		
		elif new_state == _State.DAMAGE_BOOST:
			_dancefloor_mesh_material.set_albedo(Color.SKY_BLUE);
		
		_state = new_state;

var _targets_inside_ultimate: Dictionary[RID, PhysicsBody3D] = {};
var _damage_boosted_targets: Dictionary[RID, DamageBoostedTarget] = {};

var _pressing_again_ultimate_input_action_required: bool = false;

@onready var _dancefloor: MeshInstance3D = %Dancefloor;
@onready var _dancefloor_mesh_material: StandardMaterial3D = _dancefloor.mesh.material;

@onready var _duration_timer: Timer = %DurationTimer;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	AssertLib.assert_if_entity_identity_not_found(entity_identity);

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
		if Input.is_action_pressed(&"ultimate"):
			_pressing_again_ultimate_input_action_required = false;
		else:
			return;
	
	elif _is_active():
		if Input.is_action_just_pressed(&"ultimate"):
			_toggle_ability_state();
		
		_handle_ultimate(delta);
	
	elif Input.is_action_pressed(&"ultimate"):
		_start_ultimate(delta);


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLib.get_for_entity_identity(entity_identity));
	
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
	if _state == _State.HEAL:
		for target: PhysicsBody3D in _targets_inside_ultimate.values():
			_apply_healing_to_target(target, delta);


func _end_ultimate() -> void:
	_remove_all_damage_boosted_targets();
	
	_dancefloor.hide();
	
	_state = _State.HEAL;
	
	if Input.is_action_pressed(&"ultimate"):
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
	if _state == _State.HEAL:
		_apply_damage_boost_to_targets_inside_ultimate();
		
		_state = _State.DAMAGE_BOOST;

	elif _state == _State.DAMAGE_BOOST:
		_remove_all_damage_boosted_targets();
		
		_state = _State.HEAL;


func _apply_healing_to_target(target: PhysicsBody3D, delta: float) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity_or_assert(target);
	var target_health_component: EntityHealthComponent = target_entity_component.exp_health_component;
	
	if not target_health_component: return;
	
	var healing_to_do: float = cast_healing_amount if _apply_cast_healing else healing_amount * delta;
	target_health_component.heal(healing_to_do, entity_identity);


func _apply_damage_boost_to_target(target: PhysicsBody3D) -> void:
	if _damage_boosted_targets.has(target.get_rid()): return;
	
	var target_entity_component: EntityComponent = EntityComponent.from_entity_or_assert(target);
	var target_status_receiver_component := target_entity_component.exp_status_receiver_component;
	
	if not target_status_receiver_component: return;
	
	var dmg_boost_request := IntValueRequest.new(damage_boost_amount, entity_identity);
	
	target_status_receiver_component.damage_boost_requests.add(dmg_boost_request);
	_damage_boosted_targets[target.get_rid()] = DamageBoostedTarget.new(dmg_boost_request, target);


func _apply_damage_boost_to_targets_inside_ultimate() -> void:
	for target: PhysicsBody3D in _targets_inside_ultimate.values():
		_apply_damage_boost_to_target(target);


func _remove_damage_boost_to_target(target: PhysicsBody3D) -> void:
	var dmg_boosted_target: DamageBoostedTarget = _damage_boosted_targets[target.get_rid()];

	if not dmg_boosted_target: return;

	var target_entity_component := EntityComponent.from_entity_or_assert(dmg_boosted_target.entity);
	var target_status_receiver_component := target_entity_component.exp_status_receiver_component;

	if not target_status_receiver_component: return;

	target_status_receiver_component.damage_boost_requests.remove(dmg_boosted_target.request);
	_damage_boosted_targets.erase(target.get_rid());


func _remove_all_damage_boosted_targets() -> void:
	for target: DamageBoostedTarget in _damage_boosted_targets.values():
		_remove_damage_boost_to_target(target.entity);


func _on_body_entered(body: Node3D) -> void:
	var target := body as PhysicsBody3D;

	if not target: return;
	if not target.is_in_group(&"allies"): return;

	_targets_inside_ultimate.set(target.get_rid(), target);

	if _is_active() and _state == _State.DAMAGE_BOOST:
		_apply_damage_boost_to_target(target);


func _on_body_exited(body: Node3D) -> void:
	var target := body as PhysicsBody3D;

	if not target: return;
	if not target.is_in_group(&"allies"): return;

	_targets_inside_ultimate.erase(target.get_rid());

	if _is_active() and _state == _State.DAMAGE_BOOST:
		_remove_damage_boost_to_target(target);


func _on_duration_timer_timeout() -> void:
	_end_ultimate();


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();


class DamageBoostedTarget extends RefCounted:
	var request: IntValueRequest;
	var entity: PhysicsBody3D;

	@warning_ignore("shadowed_variable")
	func _init(request: IntValueRequest, entity: PhysicsBody3D) -> void:
		self.request = request;
		self.entity = entity;
