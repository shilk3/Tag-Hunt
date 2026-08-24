extends Area3D

signal touched


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(delta * 1.5)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		touched.emit()
