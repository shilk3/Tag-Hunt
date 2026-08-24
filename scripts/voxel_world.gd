extends Node3D

# Bounded voxel terrain: a single flat voxel grid, meshed in fixed-size
# chunks so digging only has to rebuild the handful of chunks it touches.
# Voxel values: 0 = air, 1 = dirt, 2 = grass (top layer).

signal terrain_dug(position: Vector3, radius: float)

@export var width := 64
@export var height := 48
@export var depth := 64
@export var chunk_size := 16
@export var height_base := 14.0
@export var height_amplitude := 6.0
@export var noise_frequency := 0.02
@export var world_seed := 0

const GRASS_COLOR := Color(0.24, 0.58, 0.22)
const DIRT_COLOR := Color(0.42, 0.30, 0.19)

const TRI_ORDER := [0, 1, 2, 0, 2, 3]

const FACES := [
	{"dir": Vector3i(1, 0, 0), "corners": [Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(1, 1, 1), Vector3(1, 0, 1)]},
	{"dir": Vector3i(-1, 0, 0), "corners": [Vector3(0, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 1), Vector3(0, 1, 0)]},
	{"dir": Vector3i(0, 1, 0), "corners": [Vector3(0, 1, 0), Vector3(0, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 0)]},
	{"dir": Vector3i(0, -1, 0), "corners": [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)]},
	{"dir": Vector3i(0, 0, 1), "corners": [Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)]},
	{"dir": Vector3i(0, 0, -1), "corners": [Vector3(0, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(1, 0, 0)]},
]

const NEIGHBOR_DIRS := [
	Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
	Vector3i(0, 1, 0), Vector3i(0, -1, 0),
	Vector3i(0, 0, 1), Vector3i(0, 0, -1),
]

var data: PackedByteArray
var heightmap: PackedInt32Array
var chunks: Dictionary = {}
var _material: StandardMaterial3D


func _ready() -> void:
	add_to_group("voxel_world")


func generate() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = world_seed if world_seed != 0 else randi()
	noise.frequency = noise_frequency
	noise.fractal_octaves = 2

	data = PackedByteArray()
	data.resize(width * height * depth)
	heightmap = PackedInt32Array()
	heightmap.resize(width * depth)

	for x in range(width):
		for z in range(depth):
			var n := noise.get_noise_2d(x, z)
			var h: int = clampi(int(height_base + n * height_amplitude), 2, height - 2)
			heightmap[x + z * width] = h
			for y in range(h):
				data[idx(x, y, z)] = 2 if y == h - 1 else 1

	_build_all_chunks()


func idx(x: int, y: int, z: int) -> int:
	return x + width * (y + height * z)


func get_voxel(x: int, y: int, z: int) -> int:
	if x < 0 or y < 0 or z < 0 or x >= width or y >= height or z >= depth:
		return 0
	return data[idx(x, y, z)]


func get_surface_height(x: int, z: int) -> int:
	if x < 0 or z < 0 or x >= width or z >= depth:
		return 0
	return heightmap[x + z * width]


func dig_sphere(center: Vector3, radius: float) -> void:
	var min_x := maxi(0, floori(center.x - radius))
	var max_x := mini(width - 1, ceili(center.x + radius))
	var min_y := maxi(1, floori(center.y - radius))
	var max_y := mini(height - 1, ceili(center.y + radius))
	var min_z := maxi(0, floori(center.z - radius))
	var max_z := mini(depth - 1, ceili(center.z + radius))

	var dirty: Dictionary = {}
	var changed := false
	var r2 := radius * radius

	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			for z in range(min_z, max_z + 1):
				var vc := Vector3(x + 0.5, y + 0.5, z + 0.5)
				if vc.distance_squared_to(center) > r2:
					continue
				if get_voxel(x, y, z) == 0:
					continue
				data[idx(x, y, z)] = 0
				changed = true
				dirty[_chunk_coord(x, y, z)] = true
				for d in NEIGHBOR_DIRS:
					dirty[_chunk_coord(x + d.x, y + d.y, z + d.z)] = true

	if not changed:
		return

	for c in dirty.keys():
		rebuild_chunk(c)

	terrain_dug.emit(center, radius)


func _chunk_coord(x: int, y: int, z: int) -> Vector3i:
	return Vector3i(floori(x / float(chunk_size)), floori(y / float(chunk_size)), floori(z / float(chunk_size)))


func _build_all_chunks() -> void:
	var cx_count := ceili(float(width) / chunk_size)
	var cy_count := ceili(float(height) / chunk_size)
	var cz_count := ceili(float(depth) / chunk_size)
	for cx in range(cx_count):
		for cy in range(cy_count):
			for cz in range(cz_count):
				rebuild_chunk(Vector3i(cx, cy, cz))


func rebuild_chunk(c: Vector3i) -> void:
	if c.x < 0 or c.y < 0 or c.z < 0:
		return
	var x0 := c.x * chunk_size
	var y0 := c.y * chunk_size
	var z0 := c.z * chunk_size
	if x0 >= width or y0 >= height or z0 >= depth:
		return
	var x1 := mini(x0 + chunk_size, width)
	var y1 := mini(y0 + chunk_size, height)
	var z1 := mini(z0 + chunk_size, depth)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face_count := 0

	for x in range(x0, x1):
		for y in range(y0, y1):
			for z in range(z0, z1):
				var v := get_voxel(x, y, z)
				if v == 0:
					continue
				var color := GRASS_COLOR if v == 2 else DIRT_COLOR
				var origin := Vector3(x, y, z)
				for face in FACES:
					var d: Vector3i = face["dir"]
					if get_voxel(x + d.x, y + d.y, z + d.z) != 0:
						continue
					var normal := Vector3(d.x, d.y, d.z)
					var corners: Array = face["corners"]
					for corner_idx in TRI_ORDER:
						st.set_normal(normal)
						st.set_color(color)
						st.add_vertex(origin + corners[corner_idx])
					face_count += 1

	if face_count == 0:
		if chunks.has(c):
			chunks[c]["body"].queue_free()
			chunks.erase(c)
		return

	var mesh := st.commit()
	var entry := _get_or_create_chunk_node(c)
	entry["mesh"].mesh = mesh
	entry["shape"].shape = mesh.create_trimesh_shape()


func _get_or_create_chunk_node(c: Vector3i) -> Dictionary:
	if chunks.has(c):
		return chunks[c]

	var static_body := StaticBody3D.new()
	static_body.collision_layer = 1
	static_body.collision_mask = 0

	var collision_shape := CollisionShape3D.new()
	static_body.add_child(collision_shape)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.material_override = _get_material()
	static_body.add_child(mesh_instance)

	add_child(static_body)

	var entry := {"body": static_body, "mesh": mesh_instance, "shape": collision_shape}
	chunks[c] = entry
	return entry


func _get_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_material.roughness = 1.0
	return _material
