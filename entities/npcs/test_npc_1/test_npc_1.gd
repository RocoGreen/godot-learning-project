class_name TestNPC1
extends StaticBody3D


@onready var health_component: EntityHealthComponent = %EntityHealthComponent;
@onready var health_indicator_label_3d: Label3D = %HealthIndicator;


func _ready() -> void:
	health_component.health_changed.connect(_on_health_changed);

	_update_health_indicator();


func _update_health_indicator() -> void:
	health_indicator_label_3d.text = "%s / %s" % [
			health_component.get_current_health(), 
			health_component.get_maximum_health(),
	];


func _on_health_changed(_old_health: float, _new_health: float) -> void:
	_update_health_indicator();
