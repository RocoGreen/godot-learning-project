extends Node3D


enum _Mode {
	HEAL,
	DAMAGE
};

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
	_mesh_instance_pivot.look_at(camera_component.get_position_to_look_at_aim_direction());
	
	if Input.is_action_just_pressed(&"toggle_weapon_mode"):
		if _mode == _Mode.HEAL:
			_mode = _Mode.DAMAGE;
			print("Hitscan weapon is now in damage mode !");

		elif _mode == _Mode.DAMAGE:
			_mode = _Mode.HEAL;
			print("Hitscan weapon is now in heal mode !");
	
	if not Input.is_action_just_pressed(&"primary_fire"): return;
	
	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();
	
	if ray_to_get_what_player_aims_at_results.is_empty(): return;
	
	var where_to_shoot_at: Vector3 = ray_to_get_what_player_aims_at_results.get("position");
	_bullet.launch(_bullet_start_position_anchor.global_position, where_to_shoot_at);


func _on_bullet_hit() -> void:
	print("Hit: ", _bullet.get_collider());
	
	var target := _bullet.get_collider() as PhysicsBody3D;
	
	if not target: return;
	if not target.is_in_group(&"entities"): return;
	
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;
	
	if not target_health: return;

	if _mode == _Mode.HEAL:
		target_health.heal(30.0, entity_identity);
	elif _mode == _Mode.DAMAGE:
		target_health.damage(30.0, entity_identity);
