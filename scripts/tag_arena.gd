extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const WORLD_SEED := 42
const TAG_RANGE := 2.5
const TAG_COOLDOWN := 2.0
const SPAWN_RADIUS := 6.0

@onready var voxel_world = $VoxelWorld
@onready var players_root = $Players
@onready var hud = $HUD/HUDControl

var players: Dictionary = {}
var local_player: CharacterBody3D
var it_peer_id := -1
var tag_cooldown_timer := 0.0


func _ready() -> void:
	voxel_world.world_seed = WORLD_SEED
	voxel_world.generate()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	var my_id := multiplayer.get_unique_id()
	_spawn_player(my_id)
	for id in multiplayer.get_peers():
		_spawn_player(id)

	if multiplayer.is_server():
		it_peer_id = my_id
		_broadcast_it.rpc(it_peer_id)

	hud.setup(self)


func _process(delta: float) -> void:
	if tag_cooldown_timer > 0.0:
		tag_cooldown_timer -= delta
	if multiplayer.is_server() and it_peer_id != -1 and tag_cooldown_timer <= 0.0:
		_check_tags()


func _check_tags() -> void:
	var it_player: Node3D = players.get(it_peer_id)
	if it_player == null or not is_instance_valid(it_player):
		return
	var it_pos: Vector3 = it_player.global_transform.origin
	for id in players.keys():
		if id == it_peer_id:
			continue
		var p: Node3D = players[id]
		if not is_instance_valid(p):
			continue
		if it_pos.distance_to(p.global_transform.origin) <= TAG_RANGE:
			it_peer_id = id
			_broadcast_it.rpc(it_peer_id)
			return


@rpc("authority", "call_local", "reliable")
func _broadcast_it(new_it: int) -> void:
	it_peer_id = new_it
	tag_cooldown_timer = TAG_COOLDOWN
	for id in players.keys():
		var p = players[id]
		if is_instance_valid(p):
			p.set_is_it(id == it_peer_id)
	hud.update_it_status(it_peer_id, multiplayer.get_unique_id())


func _spawn_player(id: int) -> void:
	if players.has(id):
		return
	var p := PLAYER_SCENE.instantiate()
	p.name = "Player_%d" % id
	p.setup_networked(id)
	players_root.add_child(p)
	p.global_transform.origin = _spawn_position_for(id)
	if id == multiplayer.get_unique_id():
		local_player = p
		p.dig_requested.connect(_on_local_dig_requested)
	players[id] = p


func _spawn_position_for(id: int) -> Vector3:
	var center_x: float = voxel_world.width / 2.0
	var center_z: float = voxel_world.depth / 2.0
	var surface_y: int = voxel_world.get_surface_height(int(center_x), int(center_z))
	var angle := float(id) * 2.399963
	var ox: float = center_x + cos(angle) * SPAWN_RADIUS
	var oz: float = center_z + sin(angle) * SPAWN_RADIUS
	return Vector3(ox, surface_y + 8.0, oz)


func _on_peer_connected(id: int) -> void:
	_spawn_player(id)
	if multiplayer.is_server():
		_broadcast_it.rpc_id(id, it_peer_id)


func _on_peer_disconnected(id: int) -> void:
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
	if id == it_peer_id and multiplayer.is_server() and players.size() > 0:
		it_peer_id = players.keys()[0]
		_broadcast_it.rpc(it_peer_id)


func _on_local_dig_requested(pos: Vector3, radius: float) -> void:
	if multiplayer.is_server():
		apply_dig.rpc(pos, radius)
	else:
		request_dig.rpc_id(1, pos, radius)


@rpc("any_peer", "reliable")
func request_dig(pos: Vector3, radius: float) -> void:
	if not multiplayer.is_server():
		return
	apply_dig.rpc(pos, radius)


@rpc("authority", "call_local", "reliable")
func apply_dig(pos: Vector3, radius: float) -> void:
	voxel_world.dig_sphere(pos, radius)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		NetworkManager.leave_game()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
