extends Node3D


@export_group("Dependencies")
@export var playable: CharacterBody3D;
@export var camera_component: PlayableCameraComponent;

@export_group("Dependencies From Component Scene")
@export var _bullet: PackedScene;

@onready var _bullet_start_position_anchor: Node3D = %BulletStartPositionAnchor;

@onready var _mesh_instance_pivot: Node3D = %MeshInstancePivot;


func _physics_process(_delta: float) -> void:
	_mesh_instance_pivot.look_at(camera_component.get_position_to_look_at_aim_direction(true));

	if not Input.is_action_just_pressed(&"primary_fire"): return;

	var bullet: PlayableTestArcingProjectileWeapon1ComponentBullet = _bullet.instantiate();

	bullet.add_collision_exception_with(playable);

	add_child(bullet);

	var where_to_shoot_at: Vector3 = camera_component.get_position_to_look_at_aim_direction();
	bullet.launch(_bullet_start_position_anchor.global_position, where_to_shoot_at, 50.0, true, 2.0);
