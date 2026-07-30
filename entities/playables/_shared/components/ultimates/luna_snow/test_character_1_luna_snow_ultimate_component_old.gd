@tool

extends ShapeCast3D


enum _AbilityState {
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

@export var entity_mesh: MeshInstance3D:
	set(new_entity_mesh):
		entity_mesh = new_entity_mesh;
		update_configuration_warnings();

@export_group("Settings")
@export var cast_healing_amount: float = 200.0;
@export var healing_amount: float = 250.0;
@export_range(0, 100) var damage_boost_amount: int = 40;

var _ability_current_state: _AbilityState = _AbilityState.HEALING:
	set(new_ability_current_state):
		if _ability_current_state == new_ability_current_state:
			return;
		
		if new_ability_current_state == _AbilityState.HEALING:
			_dancefloor_mesh_material.albedo_color = Color.PINK;
			
			if _is_active():
				_remove_all_dmg_boosted_targets();
		
		elif new_ability_current_state == _AbilityState.DAMAGE_BOOSTING:
			_dancefloor_mesh_material.albedo_color = Color.SKY_BLUE;
		
		_ability_current_state = new_ability_current_state;

var _dmg_boosted_targets: Dictionary[RID, DmgBoostedTarget] = {};

var _apply_cast_healing: bool = false;

var _ultimate_input_action: StringName = &"ultimate";
var _pressing_again_ultimate_input_action_required: bool = false;

@onready var _dancefloor: MeshInstance3D = %Dancefloor;
@onready var _dancefloor_mesh_material: StandardMaterial3D = _dancefloor.mesh.material;
@onready var _dancefloor_pivot: Marker3D = %DancefloorPivot;

@onready var _duration_timer: Timer = %DurationTimer;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;
	
	AssertLib.assert_if_entity_identity_not_found(entity_identity);
	
	assert(
			is_instance_of(entity_mesh, MeshInstance3D), 
			
			"`entity_mesh` variable is not a `MeshInstance3D`."
	);
	
	_dancefloor.top_level = true;


func _process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;
	
	if _is_active():
		_dancefloor.global_position = _dancefloor_pivot.global_position;


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return;
	
	if _pressing_again_ultimate_input_action_required:
		if Input.is_action_pressed(_ultimate_input_action):
			_pressing_again_ultimate_input_action_required = false;
		else:
			return;
	
	elif _is_active():
		if Input.is_action_just_pressed(_ultimate_input_action):
			_toggle_ability_state();
		
		_handle_ultimate(delta);
	
	elif Input.is_action_pressed(_ultimate_input_action):
		_start(delta);


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLib.get_for_entity_identity(entity_identity));
	
	if not entity_mesh:
		warnings.append("`entity_mesh` exported variable is not set.");
	
	return warnings;


#func _handle_configuration_warnings() -> void:
	#if not entity_identity:
		#update_configuration_warnings();
	#
	#elif EntityIdentity.is_default(entity_identity):
		#update_configuration_warnings();
	#
	#elif not entity_mesh:
		#update_configuration_warnings();


func _start_dance_loop() -> void:
	entity_mesh.rotate_z(deg_to_rad(50));
	
	await get_tree().create_timer(0.5).timeout;
	
	if not _is_active():
		return;
	
	entity_mesh.set_basis(Basis());
	
	await get_tree().create_timer(0.5).timeout;
	
	if not _is_active():
		return;
	
	entity_mesh.rotate_z(deg_to_rad(-50));
	
	await get_tree().create_timer(0.5).timeout;
	
	entity_mesh.set_basis(Basis());
	
	await get_tree().create_timer(0.5).timeout;
	
	if _is_active():
		_start_dance_loop();


func _start(delta: float) -> void:
	_ability_current_state = _AbilityState.HEALING;
	
	enabled = true;
	force_shapecast_update(); # Enabling a `ShapeCast3D` doesn't automatically update it.
	
	_duration_timer.start();
	
	_dancefloor.show();
	_start_dance_loop();
	
	print(
			"Luna Snow Ultimate Started ! " + 
			"Press ultimate input action to toggle between dmg boost and healing !"
	);
	
	_apply_cast_healing = true;
	
	_handle_ultimate(delta);
	
	_apply_cast_healing = false;


func _handle_ultimate(delta: float) -> void:
	for collision_index: int in range(get_collision_count()):
		var target: PhysicsBody3D = get_collider(collision_index);
		
		if not target.is_in_group(&"allies"):
			continue;
		
		elif _ability_current_state == _AbilityState.HEALING:
			_apply_healing_to_target(target, delta);
		
		elif _ability_current_state == _AbilityState.DAMAGE_BOOSTING:
			_apply_dmg_boost_to_target(target);
	
	_remove_dmg_boost_to_targets_who_exited_ability();


func _end() -> void:
	enabled = false;
	
	_dancefloor.hide();
	_dancefloor_mesh_material.set_albedo(Color.PINK);
	
	_remove_all_dmg_boosted_targets();
	
	if Input.is_action_pressed(_ultimate_input_action):
		_pressing_again_ultimate_input_action_required = true;
	
	print("Luna Snow Ultimate Ended !");


func _toggle_ability_state() -> void:
	if _ability_current_state == _AbilityState.HEALING:
		_ability_current_state = _AbilityState.DAMAGE_BOOSTING;

	elif _ability_current_state == _AbilityState.DAMAGE_BOOSTING:
		_ability_current_state = _AbilityState.HEALING;


#func _is_target_valid(target: Node3D) -> bool:
	#if not is_instance_of(target, PhysicsBody3D):
		#return false;
	#
	#elif not target.is_in_group(&"allies"):
		#return false;
	#
	#else:
		#return true;
	#
	#var is_target_valid := true;
#
	#if not target:
		#is_target_valid = false;
	#
	#elif not target.is_in_group(&"allies"):
		#is_target_valid = false;
	#
	#return is_target_valid;


func _is_active() -> bool:
	if _duration_timer.is_stopped():
		return false;
	else:
		return true;


#func _apply_healing_or_dmg_boost_to_targets_in_ultimate(delta: float) -> void:
	#for collider_index in range(get_collision_count()):
		#var target := get_collider(collider_index) as PhysicsBody3D;
		#
		#if not _is_target_valid(target):
			#continue;
		#
		#if _ability_current_state == _AbilityState.HEALING:
			#_apply_healing_to_target(target, delta);
		#
		#elif _ability_current_state == _AbilityState.DAMAGE_BOOSTING:
			#_apply_dmg_boost_to_target(target);


func _apply_healing_to_target(target: PhysicsBody3D, delta: float) -> void:
	var target_entity_component: EntityComponent = EntityComponent.from_entity_or_assert(target);
	
	if not target_entity_component.exp_health_component: return;
	
	var healing_to_do: float = cast_healing_amount if _apply_cast_healing else healing_amount * delta;
	target_entity_component.exp_health_component.heal(healing_to_do, entity_identity);
	
	#var target_entity_component := EntityComponent.from_entity_or_assert(target);
	#
	#var target_health := target_entity_component.exp_health_component;
	#var healing_to_do := cast_healing_amount if _apply_cast_healing else healing_amount * delta;
	#
	#target_health.heal(healing_to_do, entity_component.identity);


func _apply_dmg_boost_to_target(target: PhysicsBody3D) -> void:
	if _dmg_boosted_targets.has(target.get_rid()): return;
	
	var target_entity_component: EntityComponent = EntityComponent.from_entity_or_assert(target);
	
	if not target_entity_component.exp_status_receiver_component: return;
	
	var dmg_boost_request: IntValueRequest = IntValueRequest.new(damage_boost_amount, entity_identity);
	
	target_entity_component.exp_status_receiver_component.damage_boost_requests.add(dmg_boost_request);
	
	_dmg_boosted_targets[target.get_rid()] = DmgBoostedTarget.new(dmg_boost_request, target);


#func _is_target_dmg_boosted(target: PhysicsBody3D) -> bool:
	#var dmg_boosted_target := _get_dmg_boosted_target(target);
	#
	#return is_instance_of(dmg_boosted_target, DmgBoostedTarget);


#func _get_dmg_boosted_target(target: PhysicsBody3D) -> DmgBoostedTarget:
	#var dmg_boosted_target_index = _dmg_boosted_targets.find_custom(
			#func(t: DmgBoostedTarget): return t.entity.get_rid() == target.get_rid()
	#);
	#
	#if dmg_boosted_target_index == -1:
		#return null;
	#else:
		#return _dmg_boosted_targets[dmg_boosted_target_index];


#func _get_dmg_boosted_target_index(target: PhysicsBody3D) -> DmgBoostedTarget:
	#


func _remove_dmg_boost_to_target(target: PhysicsBody3D) -> void:
	var dmg_boosted_target: DmgBoostedTarget = _dmg_boosted_targets[target.get_rid()];
	
	if not dmg_boosted_target: return;
	
	_dmg_boosted_targets.erase(target.get_rid());
	
	var target_entity_component := EntityComponent.from_entity_or_assert(dmg_boosted_target.entity);
	var target_status_receiver_component := target_entity_component.exp_status_receiver_component;
	
	if not target_status_receiver_component: return;
	
	target_status_receiver_component.damage_boost_requests.remove(dmg_boosted_target.request);


func _remove_dmg_boost_to_targets_who_exited_ability() -> void:
	var targets_to_remove_dmg_boost_to: Dictionary = _dmg_boosted_targets.duplicate();
	
	for collision_index: int in range(get_collision_count()):
		var target: PhysicsBody3D = get_collider(collision_index);
		
		if not target.is_in_group(&"allies"):
			return;
		
		if targets_to_remove_dmg_boost_to.has(target.get_rid()):
			targets_to_remove_dmg_boost_to.erase(target.get_rid());
	
	for target: DmgBoostedTarget in targets_to_remove_dmg_boost_to.values():
		_remove_dmg_boost_to_target(target.entity);


func _remove_all_dmg_boosted_targets() -> void:
	for target: DmgBoostedTarget in _dmg_boosted_targets.values():
		_remove_dmg_boost_to_target(target.entity);


func _on_duration_timer_timeout() -> void:
	_end();


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();


class DmgBoostedTarget extends RefCounted:
	var request: IntValueRequest;
	var entity: PhysicsBody3D;

	@warning_ignore("shadowed_variable")
	func _init(request: IntValueRequest, entity: PhysicsBody3D) -> void:
		self.request = request;
		self.entity = entity;
