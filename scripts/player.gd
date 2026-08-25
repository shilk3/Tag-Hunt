extends CharacterBody3D

signal fuel_changed(current: float, max_value: float)
signal dig_requested(position: Vector3, radius: float)

@export var move_speed := 9.0
@export var move_accel := 12.0
@export var jetpack_thrust := 22.0
@export var descend_thrust := 14.0
@export var gravity := 18.0
@export var max_fuel := 100.0
@export var fuel_use_rate := 28.0
@export var fuel_regen_rate := 14.0
@export var mouse_sensitivity := 0.0025
@export var dig_radius := 2.5
@export var dig_range := 30.0
@export var dig_cooldown := 0.12

@onready var camera: Camera3D = $Camera3D
@onready var body_mesh: MeshInstance3D = $BodyMesh

const NORMAL_COLOR := Color(0.3, 0.55, 0.9)
const TAGGED_COLOR := Color(0.9, 0.2, 0.2)

var fuel: float
var yaw := 0.0
var pitch := 0.0
var dig_timer := 0.0
var _body_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("player")
	fuel = max_fuel
	yaw = rotation.y
	camera.current = is_multiplayer_authority()
	body_mesh.visible = not is_multiplayer_authority()
	_body_material = body_mesh.get_surface_override_material(0)
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func setup_networked(peer_id: int) -> void:
	set_multiplayer_authority(peer_id, true)
	var sync := MultiplayerSynchronizer.new()
	sync.name = "Sync"
	var config := SceneReplicationConfig.new()
	config.add_property(NodePath(":position"))
	config.add_property(NodePath(":rotation"))
	sync.replication_config = config
	sync.root_path = NodePath("..")
	add_child(sync)
	set_multiplayer_authority(peer_id, true)


func set_is_it(is_it: bool) -> void:
	_body_material.albedo_color = TAGGED_COLOR if is_it else NORMAL_COLOR
	if is_it:
		_body_material.emission_enabled = true
		_body_material.emission = TAGGED_COLOR
		_body_material.emission_energy_multiplier = 0.6
	else:
		_body_material.emission_enabled = false


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.4, 1.4)
		rotation.y = yaw
		camera.rotation.x = pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_back"):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()

	var forward := -transform.basis.z
	var right := transform.basis.x
	var wish_dir := right * input_dir.x + forward * -input_dir.y
	wish_dir.y = 0.0
	if wish_dir.length() > 0.001:
		wish_dir = wish_dir.normalized()

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(wish_dir * move_speed, move_accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	var thrusting := false
	if Input.is_action_pressed("thrust_up") and fuel > 0.0:
		velocity.y += jetpack_thrust * delta
		fuel = maxf(0.0, fuel - fuel_use_rate * delta)
		thrusting = true
	elif Input.is_action_pressed("thrust_down"):
		velocity.y -= descend_thrust * delta
	else:
		velocity.y -= gravity * delta

	if not thrusting:
		fuel = minf(max_fuel, fuel + fuel_regen_rate * delta)
	fuel_changed.emit(fuel, max_fuel)

	move_and_slide()
	_process_dig(delta)


func _process_dig(delta: float) -> void:
	dig_timer -= delta
	if not Input.is_action_pressed("dig"):
		return
	if dig_timer > 0.0:
		return
	dig_timer = dig_cooldown

	var space_state := get_world_3d().direct_space_state
	var origin := camera.global_transform.origin
	var dir := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * dig_range)
	query.collision_mask = 1
	var result := space_state.intersect_ray(query)
	if result:
		var dig_point: Vector3 = result.position + dir * 0.15
		dig_requested.emit(dig_point, dig_radius)
