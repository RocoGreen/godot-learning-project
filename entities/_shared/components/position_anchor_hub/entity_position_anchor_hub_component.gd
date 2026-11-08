@tool
class_name EntityPositionAnchorHubComponent
extends Node3D


@export var entity_model_center_anchor: Marker3D:
	set(new_entity_model_center_anchor):
		entity_model_center_anchor = new_entity_model_center_anchor;

		if Engine.is_editor_hint():
			update_configuration_warnings();

@export var anchors_to_check_if_entity_model_sees_an_area_of_effect: Array[Marker3D] = [];


static func from_entity(entity: PhysicsBody3D) -> EntityPositionAnchorHubComponent:
	if not entity:
		return null;

	if not EntityComponent.is_entity(entity):
		return null;

	var entity_entity_component: EntityComponent = EntityComponent.get_from(entity);

	if not entity_entity_component:
		return null;

	var entity_position_anchor_hub_component := entity_entity_component.position_anchor_hub_component;

	if not entity_position_anchor_hub_component:
		return null;

	return entity_position_anchor_hub_component;


static func from_entity_as_object(object: Object) -> EntityPositionAnchorHubComponent:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_position_anchor_hub_component: EntityPositionAnchorHubComponent = from_entity(entity);

	if not entity_position_anchor_hub_component:
		return null;

	return entity_position_anchor_hub_component;


static func get_entity_model_center_anchor(entity: PhysicsBody3D) -> Marker3D:
	if not entity:
		return null;

	if not EntityComponent.is_entity(entity):
		return null;

	var entity_position_anchor_hub_component: EntityPositionAnchorHubComponent = from_entity(entity);

	if not entity_position_anchor_hub_component:
		return null;

	if not entity_position_anchor_hub_component.entity_model_center_anchor:
		return null;

	return entity_position_anchor_hub_component.entity_model_center_anchor;


static func get_entity_as_object_model_center_anchor(object: Object) -> Marker3D:
	if not object:
		return null;

	var entity: PhysicsBody3D = EntityComponent.cast_object_to_entity(object);

	if not entity:
		return null;

	var entity_model_center_position_anchor: Marker3D = get_entity_model_center_anchor(entity);

	if not entity_model_center_position_anchor:
		return null;

	return entity_model_center_position_anchor;


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not entity_model_center_anchor:
		warnings.append(
				"`entity_model_center_anchor` is not set.\n" +
				"Without it, game mechanics needing it won't be able to work properly.\n" +
				"If not desired, please add a `Marker3D` as child of this component and " +
				"position it at your entity's center location.\n" +
				"Then, assign it to the exported variable."
		);

	elif anchors_to_check_if_entity_model_sees_an_area_of_effect.is_empty():
		warnings.append(
				"`anchors_to_check_if_entity_model_sees_an_area_of_effect` array is empty.\n" +
				"Without any anchor in the array, game mechanics like Area of " + 
				"Effects won't be able to check if the entity's model can see it.\n" + 
				"Please, add an anchor to the array. Else, it'll be considered " +
				"that the model cannot see an area of effect no matter what."
		);

	return warnings;


func is_area_of_effect_visible_to_entity_model(origin_global_position: Vector3) -> bool:
	if anchors_to_check_if_entity_model_sees_an_area_of_effect.is_empty():
		return false;

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state;

	for anchor: Marker3D in anchors_to_check_if_entity_model_sees_an_area_of_effect:
		var ray_start: Vector3 = anchor.global_position;
		var ray_length: float = anchor.global_position.distance_to(origin_global_position) + 1.0;
		var ray_end: Vector3 = ray_start + (ray_start.direction_to(origin_global_position) * ray_length);

		var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
				ray_start, 
				ray_end,
				CollisionMaskLibrary.get_obstacles(),
		);

		var ray_results: Dictionary = space_state.intersect_ray(ray_query);

		# If no obstable has been hit then the area of effect is indeed visible.
		if ray_results.is_empty():
			return true;

	return false;
