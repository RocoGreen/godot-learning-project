extends Node3D


@export var playable_identity: EntityIdentity;
@export var camera_component: PlayableCameraComponent;

@onready var lag_between_shots_timer: Timer = %LagBetweenShotsTimer;


func _physics_process(_delta: float) -> void:
	if not playable_identity: return;
	if not camera_component: return;

	if not Input.is_action_pressed(&"primary_fire"): return;
	if not lag_between_shots_timer.is_stopped(): return;

	var ray_to_get_what_player_aims_at_results: Dictionary = camera_component.ray_to_aim_direction();

	if ray_to_get_what_player_aims_at_results.is_empty(): 
		return;

	var target: PhysicsBody3D = ray_to_get_what_player_aims_at_results.get("collider");

	if not target.is_in_group(&"entities"): 
		return;

	var target_entity_component: EntityComponent = EntityComponent.from_entity(target);
	var target_health: EntityHealthComponent = target_entity_component.health_component;

	if not target_health:
		return;

	target_health.damage(10.0, playable_identity);

	lag_between_shots_timer.start();
