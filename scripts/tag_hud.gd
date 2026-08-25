extends Control

const RADAR_SIZE := 180.0
const RadarDisplayScript := preload("res://scripts/radar_display.gd")

var arena: Node3D
var status_label: Label
var radar: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	draw.connect(_draw_crosshair)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 28)
	status_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	status_label.position = Vector2(0, 16)
	status_label.size = Vector2(0, 40)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status_label)

	radar = RadarDisplayScript.new()
	radar.size = Vector2(RADAR_SIZE, RADAR_SIZE)
	radar.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	radar.position = Vector2(-RADAR_SIZE - 24, -RADAR_SIZE - 24)
	add_child(radar)

	queue_redraw()


func setup(a: Node3D) -> void:
	arena = a
	radar.setup(a.local_player)


func show_disconnected_message() -> void:
	status_label.text = "Host disconnected. Returning to menu..."
	status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))


func update_it_status(it_peer_id: int, my_id: int) -> void:
	if it_peer_id == my_id:
		status_label.text = "YOU ARE IT!"
		status_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	else:
		status_label.text = "Player %d is it" % it_peer_id
		status_label.add_theme_color_override("font_color", Color(1, 1, 1))


func _process(_delta: float) -> void:
	if not arena or not arena.local_player or not multiplayer.has_multiplayer_peer():
		return
	var blips: Array = []
	var my_id := multiplayer.get_unique_id()
	for id in arena.players.keys():
		if id == my_id:
			continue
		var p = arena.players[id]
		if not is_instance_valid(p):
			continue
		var col := Color(0.9, 0.2, 0.2) if id == arena.it_peer_id else Color(0.3, 0.7, 1.0)
		blips.append({"pos": p.global_transform.origin, "color": col})
	radar.set_blips(blips)
	radar.queue_redraw()


func _draw_crosshair() -> void:
	var center := size / 2.0
	draw_circle(center, 3.0, Color(1, 1, 1, 0.85))
