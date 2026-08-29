extends Node3D


@export_group("Dependencies")
@export var playable: CharacterBody3D;
@export var playable_identity: EntityIdentity;
@export var camera_component: PlayableCameraComponent;

@onready var ray_cast_to_check_line_of_sight: RayCast3D = %RayCastToCheckLineOfSight;


func _ready() -> void:
	if not playable: return;

	ray_cast_to_check_line_of_sight.add_exception(playable);


func _physics_process(_delta: float) -> void:
	if not playable or not playable_identity: return;
	if not camera_component: return;
	if not Input.is_action_just_pressed(&"ultimate"): return;

	var entities_in_game: Array[Node] = get_tree().get_nodes_in_group(&"entities");
	var targets_to_shoot_at: Array[TargetToShootAt] = [];

	for target: Node in entities_in_game:
		if target is not PhysicsBody3D:
			continue;

		target = target as PhysicsBody3D;

		var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
		#var target_identity: EntityIdentity = target_entity_component.identity;

		if target == playable: continue;
		#if target_identity.team == playable_identity.team: continue;

		var target_position_anchor_hub_component: EntityPositionAnchorHubComponent = \
				target_entity_component.position_anchor_hub_component;

		if not target_position_anchor_hub_component: continue;

		var target_center_of_mass_global_position: Vector3 = \
				target_position_anchor_hub_component.center_of_mass_anchor.global_position;
		var playable_camera: Camera3D = camera_component._camera;

		if not playable_camera.is_position_in_frustum(target_center_of_mass_global_position):
			print("Failed by not in camera's frustum");
			continue;

		if playable_camera.global_position.direction_to(target_center_of_mass_global_position).dot(
				-playable_camera.global_basis.z.normalized()
		) < deg_to_rad(45):
			print("Failed due to center of mass being more than 45 degrees far");
			continue;

		ray_cast_to_check_line_of_sight.look_at_from_position(
				camera_component._camera.global_position,
				target_center_of_mass_global_position,
		);

		ray_cast_to_check_line_of_sight.target_position.z = \
				-ray_cast_to_check_line_of_sight.global_position.distance_to(
							target_center_of_mass_global_position,
					);
		ray_cast_to_check_line_of_sight.target_position.z += -1.0;

		ray_cast_to_check_line_of_sight.force_raycast_update();

		if not ray_cast_to_check_line_of_sight.is_colliding(): continue;
		if not ray_cast_to_check_line_of_sight.get_collider() == target: continue;

		targets_to_shoot_at.append(TargetToShootAt.new(target, playable_camera.global_position.direction_to(target_center_of_mass_global_position).dot(
				-playable_camera.global_basis.z.normalized()
		)));

	var final_target_to_shoot_at: TargetToShootAt;

	for target_to_shoot_at: TargetToShootAt in targets_to_shoot_at:
		print("Candidate : ", target_to_shoot_at.entity, " : ", target_to_shoot_at.angle_radians);
		if not final_target_to_shoot_at:
			final_target_to_shoot_at = target_to_shoot_at;
			continue;
		
		if not target_to_shoot_at.angle_radians > final_target_to_shoot_at.angle_radians:
			continue;
		
		final_target_to_shoot_at = target_to_shoot_at;

	print("Selected : ", final_target_to_shoot_at.entity, " : ", final_target_to_shoot_at.angle_radians);

	var target: PhysicsBody3D = final_target_to_shoot_at.entity;
	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);

	var target_health_component: EntityHealthComponent = target_entity_component.health_component;

	if not target_health_component:
		return;

	target_health_component.damage(10.0, playable_identity);


class TargetToShootAt extends RefCounted:
	var entity: PhysicsBody3D;
	var angle_radians: float;

	@warning_ignore("shadowed_variable")
	func _init(entity: PhysicsBody3D, angle_radians: float) -> void:
		self.entity = entity;
		self.angle_radians = angle_radians;
