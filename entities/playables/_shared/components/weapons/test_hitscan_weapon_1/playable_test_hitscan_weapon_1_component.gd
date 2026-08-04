extends Node3D


enum _Mode {
	HEAL,
	DAMAGE
}

@export_group("Dependencies")
@export var entity: PhysicsBody3D;
@export var entity_identity: EntityIdentity = EntityIdentity.new();
@export var camera_component: PlayableCameraComponent;

var _mode: _Mode = _Mode.HEAL;

@onready var _mesh_instance_pivot: Node3D = %MeshInstancePivot;

@onready var _bullet_start_position_anchor: Marker3D = %BulletStartPositionAnchor;
@onready var _bullet: PlayableHitscanBullet = %Bullet;


func _ready() -> void:
	_bullet.add_exception(entity);


func _physics_process(_delta: float) -> void:
	_mesh_instance_pivot.look_at(camera_component.get_virtual_camera_aim_point());
	
	if Input.is_action_just_pressed(&"toggle_weapon_mode"):
		if _mode == _Mode.HEAL:
			_mode = _Mode.DAMAGE;
			print("Hitscan weapon is now in damage mode !");
		elif _mode == _Mode.DAMAGE:
			_mode = _Mode.HEAL;
			print("Hitscan weapon is now in heal mode !");
	
	if not Input.is_action_just_pressed(&"primary_fire"): return;
	
	var camera_aim_point: Vector3 = camera_component.get_camera_aim_point_by_ray(
			_bullet.collision_mask,
	);
	
	if not camera_aim_point: 
		return;
	
	_bullet.launch(_bullet_start_position_anchor.global_position, camera_aim_point);


func _on_bullet_hit() -> void:
	print("Hit: ", _bullet.get_collider());
	
	var target := _bullet.get_collider() as PhysicsBody3D;
	
	if not target: return;
	if not target.is_in_group(&"entities"): return;
	
	var target_entity_component := EntityComponent.from_entity_or_assert(target);
	var target_health_component := target_entity_component.exp_health_component;
	
	if not target_health_component: return;

	if _mode == _Mode.HEAL:
		target_health_component.heal(30.0, entity_identity);
	elif _mode == _Mode.DAMAGE:
		target_health_component.damage(30.0, entity_identity);
