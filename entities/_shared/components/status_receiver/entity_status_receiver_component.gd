@tool

class_name EntityStatusReceiverComponent
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

var damage_boost_requests: RequestsHandler = RequestsHandler.new();


func _init() -> void:
	if Engine.is_editor_hint() and entity_identity:
		entity_identity.changed.connect(_on_entity_identity_changed);


func _ready() -> void:
	if Engine.is_editor_hint(): return;
	
	AssertLib.assert_if_entity_identity_not_found(entity_identity);


func _get_configuration_warnings() -> PackedStringArray:
	return ConfigurationWarningLib.get_for_entity_identity(entity_identity);


func _on_entity_identity_changed() -> void:
	update_configuration_warnings();
