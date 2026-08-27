@tool

class_name EntityPositionAnchorHubComponent
extends Node3D


@export var center_of_mass_anchor: Marker3D:
	set(new_center_of_mass_anchor):
		center_of_mass_anchor = new_center_of_mass_anchor;

		if Engine.is_editor_hint():
			update_configuration_warnings();


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = PackedStringArray();

	if not center_of_mass_anchor:
		warnings.append(
				"`center_of_mass_anchor` is not set.\n" +
				"Without it, game mechanics needing it won't be able to work properly.\n" +
				"If not desired, please add a `Marker3D` as child of this component and " +
				"position it at your `Entity`'s center of mass.\n" +
				"Then, assign it to the exported variable."
		);

	return warnings;
