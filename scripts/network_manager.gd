extends Node

signal player_list_changed
signal connected
signal connection_failed
signal server_disconnected

const PORT := 8910
const MAX_PLAYERS := 8

var players: Dictionary = {}


func host_game() -> String:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		return "Could not start server (error %d)." % err
	multiplayer.multiplayer_peer = peer
	_connect_signals()
	players[multiplayer.get_unique_id()] = true
	player_list_changed.emit()
	return ""


func join_game(address: String) -> String:
	var peer := ENetMultiplayerPeer.new()
	var host := address if address != "" else "127.0.0.1"
	var err := peer.create_client(host, PORT)
	if err != OK:
		return "Could not connect (error %d)." % err
	multiplayer.multiplayer_peer = peer
	_connect_signals()
	return ""


func leave_game() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()


func is_host() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()


func _connect_signals() -> void:
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_peer_connected(id: int) -> void:
	players[id] = true
	player_list_changed.emit()


func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	player_list_changed.emit()


func _on_connected_to_server() -> void:
	players[multiplayer.get_unique_id()] = true
	player_list_changed.emit()
	connected.emit()


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()


func _on_server_disconnected() -> void:
	players.clear()
	multiplayer.multiplayer_peer = null
	server_disconnected.emit()
