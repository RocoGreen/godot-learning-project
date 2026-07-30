extends Node3D


const _BULLET: PackedScene = preload("uid://lskivaa3dmuk");

@export_group("Dependencies")
@export var entity: PhysicsBody3D;
@export var camera_component: EntityCameraComponent;

@onready var _bullet_start_position_anchor: Node3D = %BulletStartPositionAnchor;

@onready var _mesh_instance_pivot: Node3D = %MeshInstancePivot;


func _physics_process(_delta: float) -> void:
	_mesh_instance_pivot.look_at(camera_component.get_fallback_camera_aim_point());

	if not Input.is_action_just_pressed(&"primary_fire"): return;

	var bullet: PlayableTestArcingProjectileWeapon1ComponentBullet = _BULLET.instantiate();

	bullet.add_collision_exception_with(entity);

	add_child(bullet);
	
	var where_to_shoot_at: Vector3 = camera_component.get_camera_aim_point_by_ray_else_fallback(
			bullet.collision_mask
	);
	print(where_to_shoot_at);
	bullet.launch(_bullet_start_position_anchor.global_position, where_to_shoot_at, 50.0, 2.0);
