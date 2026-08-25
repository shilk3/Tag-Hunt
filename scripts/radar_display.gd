extends Control

# Player-relative radar: forward is always "up". Blips are supplied each
# frame via set_blips() as an Array of {"pos": Vector3, "color": Color}.

const RADAR_RANGE := 45.0

var blips: Array = []
var tracked: Node3D


func _ready() -> void:
	draw.connect(_on_draw)


func setup(tracked_node: Node3D) -> void:
	tracked = tracked_node


func set_blips(new_blips: Array) -> void:
	blips = new_blips


func _on_draw() -> void:
	var c := size.x / 2.0
	draw_circle(Vector2(c, c), c, Color(0, 0, 0, 0.45))
	draw_arc(Vector2(c, c), c - 1.0, 0, TAU, 32, Color(0.6, 0.9, 0.6, 0.6), 2.0)
	if not tracked:
		return

	var yaw := tracked.rotation.y
	var cos_y := cos(yaw)
	var sin_y := sin(yaw)
	var usable_radius := c - 10.0

	for blip in blips:
		var rel: Vector3 = blip["pos"] - tracked.global_transform.origin
		var dist := Vector2(rel.x, rel.z).length()
		if dist < 0.05:
			continue
		var local_x := rel.x * cos_y - rel.z * sin_y
		var local_z := rel.x * sin_y + rel.z * cos_y
		var dir_local := Vector2(local_x, local_z) / dist
		var ratio := minf(dist / RADAR_RANGE, 1.0)
		var point := Vector2(c, c) + dir_local * ratio * usable_radius
		draw_circle(point, 5.0, blip["color"])

	draw_circle(Vector2(c, c), 4.0, Color(1, 1, 1))
