@tool

class_name EntityStatusReceiverHubComponent
extends Node


@export_group("Dependencies")
@export var entity_identity: EntityIdentity = EntityIdentity.new():
	set(new_entity_identity):
		if entity_identity and Engine.is_editor_hint():
			entity_identity.changed.disconnect(_on_entity_identity_changed);

		entity_identity = new_entity_identity;

		if Engine.is_editor_hint():
			update_configuration_warnings();

			if entity_identity:
				entity_identity.changed.connect(_on_entity_identity_changed);

@onready var damage_boost_receiver: EntityDamageBoostStatusReceiver = %DamageBoost;


static func from_entity(entity: Node) -> EntityStatusReceiverHubComponent:
	if not entity:
		return null;

	if not EntityComponent.is_entity(entity):
		return null;

	var entity_entity_component: EntityComponent = EntityComponent.get_from(entity);

	if not entity_entity_component:
		return null;

	var entity_status_receiver_hub_component := entity_entity_component.status_receiver_hub_component;

	if not entity_status_receiver_hub_component:
		return null;

	return entity_status_receiver_hub_component;


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLibrary.get_for_entity_identity(entity_identity);


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();
