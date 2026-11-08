extends Node3D


@export_group("Dependencies")
@export var playable: CharacterBody3D;
@export var player_camera_component: PlayablePlayerCameraComponent;

@export_group("Dependencies From Component Scene")
@export var _bullet: PackedScene;

@onready var _bullet_start_position_anchor: Node3D = %BulletStartPositionAnchor;

@onready var _mesh_instance_pivot: Node3D = %MeshInstancePivot;


func _physics_process(_delta: float) -> void:
	_mesh_instance_pivot.look_at(player_camera_component.get_position_to_point_at_aim_direction(true));

	if not Input.is_action_just_pressed(&"primary_fire"): 
		return;

	var bullet: PlayableTestArcingProjectileWeapon1ComponentBullet = _bullet.instantiate();

	bullet.add_collision_exception_with(playable);

	add_child(bullet);

	bullet.launch(
			_bullet_start_position_anchor.global_position, 
			player_camera_component.get_position_to_point_at_aim_direction(), 
			50.0, 
			true, 
			2.0,
	);
