class_name PlayableHitscanBullet
extends RayCast3D


signal hit;


func launch(from_global_position: Vector3, towards: Vector3) -> void:
	look_at_from_position(from_global_position, towards);

	target_position.z = -global_position.distance_to(towards) + -1.0;

	force_raycast_update();

	if is_colliding():
		hit.emit();
