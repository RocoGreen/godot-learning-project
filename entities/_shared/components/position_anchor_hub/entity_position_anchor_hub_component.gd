@tool

class_name EntityPositionAnchorHubComponent
extends Node3D


@export var center_anchor: Marker3D:
	set(new_center_anchor):
		center_anchor = new_center_anchor;

		if Engine.is_editor_hint():
			update_configuration_warnings();


static func from_entity(entity: Node) -> EntityPositionAnchorHubComponent:
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


static func get_center_position_of_entity(entity: Node) -> Vector3:
	if not entity:
		return Vector3.ZERO;

	if not EntityComponent.is_entity(entity):
		return Vector3.ZERO;

	var entity_position_anchor_hub_component: EntityPositionAnchorHubComponent = from_entity(entity);

	if not entity_position_anchor_hub_component:
		return Vector3.ZERO;

	if not entity_position_anchor_hub_component.center_anchor:
		return Vector3.ZERO;

	return entity_position_anchor_hub_component.center_anchor.global_position;
 

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not center_anchor:
		warnings.append(
				"`center_anchor` is not set.\n" +
				"Without it, game mechanics needing it won't be able to work properly.\n" +
				"If not desired, please add a `Marker3D` as child of this component and " +
				"position it at your entity's center location.\n" +
				"Then, assign it to the exported variable."
		);

	return warnings;
