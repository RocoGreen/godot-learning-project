extends Node3D


enum _Mode {
	HEAL,
	DAMAGE,
};

@export_group("Dependencies")
@export var playable: CharacterBody3D;
@export var player_camera_component: PlayablePlayerCameraComponent;

@export_group("Bullet Healing & Damage Sources")
@export var bullet_healing_source: EntityHealthHealingSource;
@export var bullet_damage_source: EntityHealthDamageSource;

var _mode: _Mode = _Mode.HEAL;

@onready var _mesh_instance_pivot: Node3D = %MeshInstancePivot;

@onready var _bullet_start_position_anchor: Marker3D = %BulletStartPositionAnchor;
@onready var _bullet: PlayableHitscanBullet = %Bullet;


func _ready() -> void:
	_bullet.add_exception(playable);


func _physics_process(_delta: float) -> void:
	_mesh_instance_pivot.look_at(player_camera_component.get_position_to_point_at_aim_direction());
	
	if Input.is_action_just_pressed(&"toggle_weapon_mode"):
		if _mode == _Mode.HEAL:
			_mode = _Mode.DAMAGE;
			print("Hitscan weapon is now in damage mode !");

		elif _mode == _Mode.DAMAGE:
			_mode = _Mode.HEAL;
			print("Hitscan weapon is now in heal mode !");

	if not Input.is_action_just_pressed(&"primary_fire"): return;

	var ray_to_hit_an_object_player_aims_at_results: Dictionary = \
			player_camera_component.ray_to_hit_an_object_aimed_at(
					CollisionMaskLibrary.get_entities_and_obstacles(),
			);

	if ray_to_hit_an_object_player_aims_at_results.is_empty(): return;

	var global_position_to_shoot_at: Vector3 = ray_to_hit_an_object_player_aims_at_results.position;
	_bullet.launch(_bullet_start_position_anchor.global_position, global_position_to_shoot_at);


func _on_bullet_hit() -> void:
	var collider: Object = _bullet.get_collider();

	print("Hit: ", collider);

	if not EntityComponent.is_object_an_entity(collider): return;

	var collider_entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(collider);
	var collider_entity_health_component := EntityHealthComponent.from_entity(collider_entity);

	if not collider_entity_health_component: return;

	if _mode == _Mode.HEAL:
		var healing_request: EntityHealthHealingRequest = EntityHealthHealingRequest.new(
				30.0,
				bullet_healing_source,
				playable,
				true,
		);

		if not collider_entity_health_component.is_request_allowed_to_heal(healing_request): 
			return;

		collider_entity_health_component.heal(healing_request);

	elif _mode == _Mode.DAMAGE:
		var damage_request: EntityHealthDamageRequest = EntityHealthDamageRequest.new(
				30.0,
				bullet_damage_source,
				playable,
				true,
		);

		if not collider_entity_health_component.is_request_allowed_to_damage(damage_request): 
			return;

		collider_entity_health_component.damage(damage_request);
