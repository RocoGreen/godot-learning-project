class_name PlayableHitscanBullet
extends RayCast3D


signal hit;


func launch(from_global_position: Vector3, to_global_position: Vector3) -> bool:
	look_at_from_position(from_global_position, to_global_position);

	target_position.z = -global_position.distance_to(to_global_position) + -1.0;

	force_raycast_update();

	if is_colliding():
		hit.emit();

	return is_colliding();
