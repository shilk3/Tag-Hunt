extends Control


func _ready() -> void:
	$CenterContainer/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/TagButton.pressed.connect(_on_tag_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/treasure_hunt.tscn")


func _on_tag_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tag_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
