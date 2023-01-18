extends Node

signal reload_main_menu # For forcing the main menu to check whether save games exist or not
# to display correct button schema

signal train_on_cell(center_of_cell_in_global_position)
signal update_train_speed_multiplier(new_speed_multiplier)
signal zoom_level_changed(zoom_level)
