extends StaticBody3D


@onready var health_component: EntityHealthComponent = %EntityHealthComponent;
@onready var health_indicator: Label3D = %HealthIndicator;


func _ready() -> void:
	_update_health_indicator();


func _update_health_indicator() -> void:
	%HealthIndicator.text = "%s / %s" % [health_component.current_health, health_component.max_health];


func _on_health_changed(_old_health: float, _new_health: float, _source: EntityIdentity) -> void:
	_update_health_indicator();
