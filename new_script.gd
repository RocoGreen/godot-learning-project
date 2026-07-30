extends CharacterBody3D


@export var speed: float = 10.0;

var test_global_position: Vector3 = Vector3.ZERO;

var camera: Camera3D = Camera3D.new();
var muzzle: MeshInstance3D = MeshInstance3D.new();

var weapon_range: float = 50.0;


func _ready() -> void:
	# Get the distance between the characterbody3d global_position and test_global_position
	var distance: float = global_position.distance_to(test_global_position);

	# Get the characterbody3d global_position pointing toward the test_global_position
	var direction: Vector3 = global_position.direction_to(test_global_position);

	if distance >= 40.0: return;

	# Move the characterbody3d to the test_global_position
	velocity = direction * speed;
	move_and_slide();


func fire_weapon() -> void:
	var cam_start: Vector3 = camera.get_global_position();
	var cam_end: Vector3 = (cam_start + -camera.global_basis.z.normalized()) * weapon_range;
	
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(cam_start, cam_end);
	query.set_exclude([ self ]);
	var cam_result: Dictionary = get_world_3d().get_direct_space_state().intersect_ray(query);

	var target_point: Vector3;
	if cam_result:
		target_point = cam_result.get("position");
	else:
		target_point = cam_end; # Default: Nothing hit, aim at max range

	# Step 2: Fire the real shot from the muzzle, aimed at that point
	var muzzle_start: Vector3 = muzzle.get_global_position();
	var muzzle_end: Vector3 = (muzzle_start + muzzle_start.direction_to(target_point)) * weapon_range;

	var muzzle_query := PhysicsRayQueryParameters3D.create(muzzle_start, muzzle_end);
	muzzle_query.set_exclude([ self ]);
	var muzzle_result: Dictionary = get_world_3d().get_direct_space_state().intersect_ray(muzzle_query);

	if muzzle_result:
		var muzzle_result_target: PhysicsBody3D = muzzle_result.collider;
		print("Actually hit: ", muzzle_result_target.get_name());
