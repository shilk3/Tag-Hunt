extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const TREASURE_SCENE := preload("res://scenes/treasure.tscn")

@onready var voxel_world = $VoxelWorld
@onready var treasure_manager = $TreasureManager
@onready var hud = $HUD/HUDControl

var player: CharacterBody3D


func _ready() -> void:
	voxel_world.generate()

	var sx: int = voxel_world.width / 2
	var sz: int = voxel_world.depth / 2
	var surface_y: int = voxel_world.get_surface_height(sx, sz)

	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform.origin = Vector3(sx + 0.5, surface_y + 8.0, sz + 0.5)

	treasure_manager.treasure_scene = TREASURE_SCENE
	treasure_manager.setup(voxel_world)
	treasure_manager.all_treasures_found.connect(_on_all_found)

	hud.setup(player, treasure_manager)


func _on_all_found() -> void:
	hud.show_win_message()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
