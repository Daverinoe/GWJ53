extends Node
# Contains references to nodes that need to be preserved across scenes

var in_game_menu_ref := preload("res://source/scenes/menus/in_game_menu.tscn")
var settings_menu_ref := preload("res://source/scenes/menus/settings/settings.tscn")
var save_menu_ref := preload("res://source/scenes/menus/serials/save.tscn")
var load_menu_ref := preload("res://source/scenes/menus/serials/load.tscn")

var main_menu_path := "res://source/scenes/menus/main_menu/main_menu.tscn"


var level_ref
var active_menu
var active_scene
