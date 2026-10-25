class_name PlayableCloakAndDaggerDaggerLightExplosionAbilityVeil
extends PlayableProjectileBullet


static var _PACKED_SCENE: PackedScene = load("res://entities/playables/cloak_and_dagger/components/dagger/abilities/light_explosion/veil/playable_cloak_and_dagger_dagger_light_explosion_ability_veil.tscn");

var _healing_per_entity_hit: float;
var _healing_amplification_percentage: int;
var _healing_amplification_duration_seconds: float;

var _width_size_meters: float;
var _height_size_meters: float;

var _playable_cloak_and_dagger_to_exclude_from_collision: PlayableCloakAndDagger;
var _playable_cloak_and_dagger_identity: EntityIdentity;

@onready var mesh_instance_3d: MeshInstance3D = %MeshInstance3D;
@onready var mesh_instance_3d_box_mesh: BoxMesh = mesh_instance_3d.mesh as BoxMesh; 

@onready var collision_shape_3d: CollisionShape3D = %CollisionShape3D;
@onready var collision_shape_3d_box_shape_3d: BoxShape3D = collision_shape_3d.shape as BoxShape3D;

@onready var entity_detector_area_3d: Area3D = %EntityDetectorArea3D;
@onready var entity_detector_collision_shape_3d: CollisionShape3D = %EntityDetectorCollisionShape3D;
@onready var entity_detector_collision_shape_3d_box_shape_3d: BoxShape3D = \
		entity_detector_collision_shape_3d.shape as BoxShape3D;


static func create(
		healing_per_entity_hit: float,
		healing_amplification_percentage: int,
		healing_amplification_duration_seconds: float,

		width_size_meters: float,
		height_size_meters: float,

		playable_cloak_and_dagger_to_exclude_from_collision: PlayableCloakAndDagger,
		playable_cloak_and_dagger_identity: EntityIdentity,
) -> PlayableCloakAndDaggerDaggerLightExplosionAbilityVeil:
	var veil: PlayableCloakAndDaggerDaggerLightExplosionAbilityVeil = _PACKED_SCENE.instantiate();

	veil._healing_per_entity_hit = healing_per_entity_hit;
	veil._healing_amplification_percentage = healing_amplification_percentage;
	veil._healing_amplification_duration_seconds = healing_amplification_duration_seconds;

	veil._width_size_meters = width_size_meters;
	veil._height_size_meters = height_size_meters;

	veil._playable_cloak_and_dagger_to_exclude_from_collision = \
			playable_cloak_and_dagger_to_exclude_from_collision;
	veil._playable_cloak_and_dagger_identity = playable_cloak_and_dagger_identity;

	return veil;


func _apply_healing_to_entity(entity: PhysicsBody3D) -> void:
	var entity_health_component: EntityHealthComponent = EntityHealthComponent.from_entity(entity);

	if not entity_health_component: return;

	entity_health_component.heal(_healing_per_entity_hit, _playable_cloak_and_dagger_identity);


func _setup_mesh_and_shape_sizes() -> void:
	mesh_instance_3d_box_mesh.size = Vector3(_width_size_meters, _height_size_meters, 0.1);
	collision_shape_3d_box_shape_3d.size = Vector3(_width_size_meters - 3.0, _height_size_meters - 3.0, 0.1);

	entity_detector_collision_shape_3d_box_shape_3d.size = \
			Vector3(_width_size_meters, _height_size_meters, 0.1);


func _on_launched() -> void:
	_setup_mesh_and_shape_sizes();


func _on_collided(_collision: KinematicCollision3D) -> void:
	queue_free();


func _on_maximum_travel_distance_reached() -> void:
	queue_free();


func _on_entity_detector_area_3d_body_entered(body: Node3D) -> void:
	if not EntityComponent.is_object_an_entity(body): return;

	var entity_who_entered: PhysicsBody3D = EntityComponent.cast_object_to_entity(body);

	if entity_who_entered == _playable_cloak_and_dagger_to_exclude_from_collision: 
		return;

	var entity_who_entered_identity: EntityIdentity = EntityIdentity.from_entity(entity_who_entered);

	if not entity_who_entered_identity: 
		return;

	var entity_who_entered_team: EntityIdentity.Team = entity_who_entered_identity.team;

	if entity_who_entered_team == null:
		return;

	if entity_who_entered_team != _playable_cloak_and_dagger_identity.team: 
		return;

	_apply_healing_to_entity(entity_who_entered);
