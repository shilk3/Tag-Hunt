extends Control

const RADAR_SIZE := 180.0
const RadarDisplayScript := preload("res://scripts/radar_display.gd")

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

	radar = RadarDisplayScript.new()
	radar.size = Vector2(RADAR_SIZE, RADAR_SIZE)
	radar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	radar.position = Vector2(-RADAR_SIZE - 24, -RADAR_SIZE - 24)
	add_child(radar)

	queue_redraw()


func setup(p: CharacterBody3D, tm: Node) -> void:
	player = p
	treasure_manager = tm
	total_count = tm.treasure_count
	radar.setup(p)
	tm.treasure_found.connect(_on_treasure_found)
	p.fuel_changed.connect(_on_fuel_changed)
	_on_fuel_changed(p.fuel, p.max_fuel)
	_on_treasure_found(tm.found_count, tm.treasure_count)


func show_win_message() -> void:
	win_label.visible = true


func _process(_delta: float) -> void:
	if not treasure_manager:
		return
	var blips: Array = []
	for t in treasure_manager.treasures:
		if not is_instance_valid(t):
			continue
		var rel: Vector3 = t.global_transform.origin - player.global_transform.origin
		var col: Color
		if rel.y > 3.0:
			col = Color(0.4, 0.7, 1.0)
		elif rel.y < -3.0:
			col = Color(1.0, 0.55, 0.3)
		else:
			col = Color(1.0, 0.85, 0.2)
		blips.append({"pos": t.global_transform.origin, "color": col})
	radar.set_blips(blips)
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
