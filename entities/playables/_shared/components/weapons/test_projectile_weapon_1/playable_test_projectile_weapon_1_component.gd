@tool

class_name PlayableTestProjectileWeapon1Component
extends Node3D


enum _Mode {
	HEAL,
	DAMAGE,
};

@export_group("Dependencies")
@export var entity: PhysicsBody3D:
	set(new_entity):
		entity = new_entity;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var entity_identity: EntityIdentity = EntityIdentity.new():
	set(new_entity_identity):
		entity_identity = new_entity_identity;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var camera_component: PlayableCameraComponent:
	set(new_camera_component):
		camera_component = new_camera_component;
		
		if Engine.is_editor_hint():
			update_configuration_warnings();

@export_group("Dependencies From Component Scene")
@export var _bullet: PackedScene;

@export_group("Bullet Settings")
@export var bullet_damage: float = 30.0;
@export var bullet_healing: float = 30.0;
@export var bullet_travel_speed: float = 50.0;

var _mode: _Mode = _Mode.DAMAGE;

var _frame_ray_point_from_camera_forward: Vector3 = Vector3.ZERO;

@onready var _mesh_instance_pivot: Node3D = %MeshInstancePivot;

@onready var _bullet_start_transform_anchor_pivot: Marker3D = %BulletStartTransformAnchorPivot;
@onready var _bullet_start_transform_anchor: Node3D = %BulletStartTransformAnchor;

@onready var _muzzle_forward_raycast: RayCast3D = %MuzzleForwardRayCast;

@onready var _ray_point_from_camera_forward_indicator: MeshInstance3D = %RayPointFromCameraForwardIndicator;
@onready var _ray_point_from_muzzle_forward_indicator: MeshInstance3D = %RayPointFromMuzzleForwardIndicator;


func _ready() -> void:
	if Engine.is_editor_hint(): return;

	AssertLib.assert_if_entity_not_found(entity);
	AssertLib.assert_if_entity_identity_not_found(entity_identity);
	AssertLib.assert_if_camera_component_not_found(camera_component);

	_bullet_start_transform_anchor.top_level = true;

	_muzzle_forward_raycast.add_exception(entity);


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return;

	if Input.is_action_just_pressed(&"toggle_weapon_mode"): 
		_toggle_mode();

	_update_mesh_instance_pivot();

	_update_frame_ray_point_from_camera_forward();

	_update_bullet_start_transform_anchor();

	_update_ray_point_from_camera_forward_indicator();

	_update_ray_point_from_muzzle_forward_indicator();

	if Input.is_action_just_pressed(&"primary_fire"): 
		_fire_bullet();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	warnings.append_array(ConfigurationWarningLib.get_for_entity(entity));

	warnings.append_array(ConfigurationWarningLib.get_for_entity_identity(entity_identity));

	warnings.append_array(ConfigurationWarningLib.get_for_camera_component(camera_component));

	return warnings;


func _toggle_mode() -> void:
	if _mode == _Mode.DAMAGE:
		_mode = _Mode.HEAL;
		print("Test Character 1's weapon now heals any entity !");

	elif _mode == _Mode.HEAL:
		_mode = _Mode.DAMAGE;
		print("Test Character 1's weapon now damages any entity !");


func _fire_bullet() -> void:
	var bullet: PlayableTestProjectileWeapon1ComponentBullet = _bullet.instantiate();
	bullet.weapon = self;

	add_child(bullet);


func _update_mesh_instance_pivot() -> void:
	_mesh_instance_pivot.look_at(camera_component.get_virtual_camera_aim_point());


func _update_frame_ray_point_from_camera_forward() -> void:
	var camera_aim_point: Vector3 = camera_component.get_camera_aim_point_by_ray();

	if camera_aim_point:
		_frame_ray_point_from_camera_forward = camera_aim_point;
	else:
		_frame_ray_point_from_camera_forward = Vector3.ZERO;


func _update_bullet_start_transform_anchor() -> void:
	var where_to_shoot: Vector3 = camera_component.get_virtual_camera_aim_point();

	if _frame_ray_point_from_camera_forward:
		where_to_shoot = _frame_ray_point_from_camera_forward;

	_bullet_start_transform_anchor.look_at_from_position(
			_bullet_start_transform_anchor_pivot.global_position,
			where_to_shoot,
	);


func _update_ray_point_from_camera_forward_indicator() -> void:
	if _frame_ray_point_from_camera_forward:
		_ray_point_from_camera_forward_indicator.global_position = _frame_ray_point_from_camera_forward;
		_ray_point_from_camera_forward_indicator.show();
	else:
		_ray_point_from_camera_forward_indicator.hide();


func _update_ray_point_from_muzzle_forward_indicator() -> void:
	if _frame_ray_point_from_camera_forward:
		_muzzle_forward_raycast.target_position = Vector3(
				0.0, 
				0.0, 
				-(_muzzle_forward_raycast.global_position.distance_to(_frame_ray_point_from_camera_forward) + 5.0)
		);
	else:
		_muzzle_forward_raycast.target_position = Vector3(0.0, 0.0, -1000.0);
	
	_muzzle_forward_raycast.force_raycast_update();

	if _muzzle_forward_raycast.is_colliding():
		var indicator_new_global_position: Vector3 = _muzzle_forward_raycast.get_collision_point();

		_ray_point_from_muzzle_forward_indicator.global_position = indicator_new_global_position;
		_ray_point_from_muzzle_forward_indicator.show();
	else:
		_ray_point_from_muzzle_forward_indicator.hide();
