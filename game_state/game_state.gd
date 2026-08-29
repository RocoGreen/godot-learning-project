extends Node


signal in_game_input_got_disabled;
signal in_game_input_got_enabled_back;

var in_game_input_disabled: bool = false:
	set(new_in_game_input_disabled):
		if in_game_input_disabled == new_in_game_input_disabled: return;

		in_game_input_disabled = new_in_game_input_disabled;

		if in_game_input_disabled == true:
			in_game_input_got_disabled.emit();
		else:
			in_game_input_got_enabled_back.emit();


func enable_back_in_game_input() -> void:
	if in_game_input_disabled == false: return;

	in_game_input_disabled = false;


func disable_in_game_input() -> void:
	if in_game_input_disabled == true: return;

	in_game_input_disabled = true;
