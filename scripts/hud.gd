extends Control

const RADAR_SIZE := 180.0
const RADAR_RANGE := 45.0

var player: CharacterBody3D
var treasure_manager: Node
var total_count := 0

var fuel_bar: ProgressBar
var treasure_label: Label
var win_label: Label
var radar: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw.connect(_draw_crosshair)

	var fuel_label := Label.new()
	fuel_label.text = "FUEL"
	fuel_label.position = Vector2(24, 2)
	add_child(fuel_label)

	fuel_bar = ProgressBar.new()
	fuel_bar.min_value = 0
	fuel_bar.max_value = 100
	fuel_bar.value = 100
	fuel_bar.show_percentage = false
	fuel_bar.position = Vector2(24, 24)
	fuel_bar.size = Vector2(220, 22)
	add_child(fuel_bar)

	treasure_label = Label.new()
	treasure_label.text = "Treasures: 0 / 0"
	treasure_label.add_theme_font_size_override("font_size", 20)
	treasure_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	treasure_label.position = Vector2(-260, 24)
	treasure_label.size = Vector2(240, 30)
	treasure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(treasure_label)

	win_label = Label.new()
	win_label.text = "ALL TREASURES FOUND!"
	win_label.add_theme_font_size_override("font_size", 36)
	win_label.set_anchors_preset(Control.PRESET_CENTER)
	win_label.position = Vector2(-260, -30)
	win_label.size = Vector2(520, 60)
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.visible = false
	add_child(win_label)

	radar = Control.new()
	radar.size = Vector2(RADAR_SIZE, RADAR_SIZE)
	radar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	radar.position = Vector2(-RADAR_SIZE - 24, -RADAR_SIZE - 24)
	radar.draw.connect(_draw_radar)
	add_child(radar)

	queue_redraw()


func setup(p: CharacterBody3D, tm: Node) -> void:
	player = p
	treasure_manager = tm
	total_count = tm.treasure_count
	tm.treasure_found.connect(_on_treasure_found)
	p.fuel_changed.connect(_on_fuel_changed)
	_on_fuel_changed(p.fuel, p.max_fuel)
	_on_treasure_found(tm.found_count, tm.treasure_count)


func show_win_message() -> void:
	win_label.visible = true


func _process(_delta: float) -> void:
	if radar:
		radar.queue_redraw()


func _on_fuel_changed(current: float, max_value: float) -> void:
	fuel_bar.max_value = max_value
	fuel_bar.value = current


func _on_treasure_found(count: int, total: int) -> void:
	total_count = total
	treasure_label.text = "Treasures: %d / %d" % [count, total]


func _draw_crosshair() -> void:
	var center := size / 2.0
	draw_circle(center, 3.0, Color(1, 1, 1, 0.85))


func _draw_radar() -> void:
	var c := RADAR_SIZE / 2.0
	radar.draw_circle(Vector2(c, c), c, Color(0, 0, 0, 0.45))
	radar.draw_arc(Vector2(c, c), c - 1.0, 0, TAU, 32, Color(0.6, 0.9, 0.6, 0.6), 2.0)
	if not player or not treasure_manager:
		return

	var yaw := player.rotation.y
	var cos_y := cos(yaw)
	var sin_y := sin(yaw)
	var usable_radius := c - 10.0

	for t in treasure_manager.treasures:
		if not is_instance_valid(t):
			continue
		var rel: Vector3 = t.global_transform.origin - player.global_transform.origin
		var dist := Vector2(rel.x, rel.z).length()
		if dist < 0.05:
			continue
		var local_x := rel.x * cos_y - rel.z * sin_y
		var local_z := rel.x * sin_y + rel.z * cos_y
		var dir_local := Vector2(local_x, local_z) / dist
		var ratio := minf(dist / RADAR_RANGE, 1.0)
		var point := Vector2(c, c) + dir_local * ratio * usable_radius

		var col: Color
		if rel.y > 3.0:
			col = Color(0.4, 0.7, 1.0)
		elif rel.y < -3.0:
			col = Color(1.0, 0.55, 0.3)
		else:
			col = Color(1.0, 0.85, 0.2)
		radar.draw_circle(point, 5.0, col)

	radar.draw_circle(Vector2(c, c), 4.0, Color(1, 1, 1))
