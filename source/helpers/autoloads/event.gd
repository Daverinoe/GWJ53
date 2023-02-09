extends Node

signal reload_main_menu # For forcing the main menu to check whether save games exist or not
# to display correct button schema

signal train_on_cell(center_of_cell_in_global_position)
signal update_train_speed_multiplier(new_speed_multiplier)
signal zoom_level_changed(zoom_level)
signal you_died()


# Train movement signals
signal move_to_start_of_path
signal at_end_of_path
signal generate_hex_path(hex_to_generate_path_for)
signal get_next_hex
signal path_generated(path : Array)
signal start_pathing
