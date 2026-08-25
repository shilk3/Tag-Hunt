extends Control

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var ip_field: LineEdit = $CenterContainer/VBoxContainer/IPField


func _ready() -> void:
	$CenterContainer/VBoxContainer/HostButton.pressed.connect(_on_host_pressed)
	$CenterContainer/VBoxContainer/JoinButton.pressed.connect(_on_join_pressed)
	$CenterContainer/VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	NetworkManager.connection_failed.connect(_on_connection_failed)


func _on_host_pressed() -> void:
	var err := NetworkManager.host_game()
	if err != "":
		status_label.text = err
		return
	get_tree().change_scene_to_file("res://scenes/tag_arena.tscn")


func _on_join_pressed() -> void:
	status_label.text = "Connecting..."
	var err := NetworkManager.join_game(ip_field.text.strip_edges())
	if err != "":
		status_label.text = err
		return
	await NetworkManager.connected
	get_tree().change_scene_to_file("res://scenes/tag_arena.tscn")


func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Check the IP address and try again."


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
