extends Node

# Registers input actions in code instead of hand-editing the [input] section
# of project.godot, since that section's InputEventKey resource syntax is
# fragile to write by hand. Runs as an autoload, so this executes before any
# scene's _ready().

func _init() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("thrust_up", KEY_SPACE)
	_add_key_action("thrust_down", KEY_CTRL)
	_add_mouse_action("dig", MOUSE_BUTTON_LEFT)


func _add_key_action(action: String, keycode: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)


func _add_mouse_action(action: String, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
