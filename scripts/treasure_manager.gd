extends Node3D

signal treasure_found(count: int, total: int)
signal all_treasures_found

@export var treasure_count := 10

var treasure_scene: PackedScene
var treasures: Array = []
var found_count := 0
var voxel_world: Node = null


func setup(world: Node) -> void:
	voxel_world = world
	voxel_world.terrain_dug.connect(_on_terrain_dug)
	for i in range(treasure_count):
		_spawn_one()


func _spawn_one() -> void:
	var pos := _pick_buried_position()
	var t := treasure_scene.instantiate()
	add_child(t)
	t.global_transform.origin = pos
	t.touched.connect(_on_treasure_touched.bind(t))
	treasures.append(t)


func _pick_buried_position() -> Vector3:
	for attempt in range(60):
		var x := randi_range(3, voxel_world.width - 4)
		var z := randi_range(3, voxel_world.depth - 4)
		var surface_y: int = voxel_world.get_surface_height(x, z)
		if surface_y < 8:
			continue
		var min_depth := 2
		var max_depth: int = mini(surface_y - 2, 18)
		if max_depth <= min_depth:
			continue
		var y := surface_y - randi_range(min_depth, max_depth)
		if voxel_world.get_voxel(x, y, z) != 0:
			return Vector3(x + 0.5, y + 0.5, z + 0.5)
	return Vector3(voxel_world.width / 2.0, voxel_world.height / 2.0, voxel_world.depth / 2.0)


func _on_terrain_dug(position: Vector3, radius: float) -> void:
	for t in treasures.duplicate():
		if is_instance_valid(t) and t.global_transform.origin.distance_to(position) <= radius + 1.0:
			_collect(t)


func _on_treasure_touched(t: Node3D) -> void:
	_collect(t)


func _collect(t: Node3D) -> void:
	if not treasures.has(t):
		return
	treasures.erase(t)
	found_count += 1
	treasure_found.emit(found_count, treasure_count)
	if is_instance_valid(t):
		t.queue_free()
	if found_count >= treasure_count:
		all_treasures_found.emit()
