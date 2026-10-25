class_name EntityVisibleOnScreenNotifierComponent
extends VisibleOnScreenNotifier3D


@export var entity: PhysicsBody3D;


static func get_entities_visible_on_screen(scene_tree: SceneTree) -> Array[PhysicsBody3D]:
	var entities_visible_on_screen: Array[Node] = \
			scene_tree.get_nodes_in_group(&"entities_visible_on_screen");
	var valid_entities_visible_on_screen: Array[PhysicsBody3D] = [];

	for entity_visible_on_screen: Node in entities_visible_on_screen:
		if EntityComponent.is_object_an_entity(entity_visible_on_screen):
			valid_entities_visible_on_screen.append(entity_visible_on_screen);

	return valid_entities_visible_on_screen;


static func get_entities_in_team_visible_on_screen(
		scene_tree: SceneTree,
		team: EntityIdentity.Team, 
) -> Array[PhysicsBody3D]:
	var entities_visible_on_screen: Array[PhysicsBody3D] = get_entities_visible_on_screen(scene_tree);
	var entities_visible_on_screen_in_team: Array[PhysicsBody3D] = [];

	for entity_visible_on_screen: PhysicsBody3D in entities_visible_on_screen:
		var entity_visible_on_screen_identity := EntityIdentity.from_entity(entity_visible_on_screen);

		if not entity_visible_on_screen_identity:
			continue;

		var entity_visible_on_screen_team: EntityIdentity.Team = entity_visible_on_screen_identity.team;

		if entity_visible_on_screen_team == null:
			continue;

		if entity_visible_on_screen_team != team:
			continue;

		entities_visible_on_screen_in_team.append(entity_visible_on_screen);

	return entities_visible_on_screen_in_team;


func _on_screen_entered() -> void:
	if not entity.is_in_group(&"entities_visible_on_screen"):
		entity.add_to_group(&"entities_visible_on_screen");


func _on_screen_exited() -> void:
	if entity.is_in_group(&"entities_visible_on_screen"):
		entity.remove_from_group(&"entities_visible_on_screen");
