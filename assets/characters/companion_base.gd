class_name CompanionBase
extends CharacterBody2D

@export var target: Node2D
@export var follow_speed: float = 220.0
@export var follow_distance: float = 50.0
@export var jump_velocity: float = -430.0
@export var gravity: float = 980.0

@onready var body: AnimatedSprite2D = $Body

var blink_timer: float = 0.0
var is_blinking: bool = false
var jump_cooldown: float = 0.0

var jump_queue: Array[Dictionary] = []
var pending_takeoff: Vector2 = Vector2.ZERO
var target_in_jump: bool = false
var target_was_on_floor: bool = true
var last_target_floor_pos: Vector2 = Vector2.ZERO

var is_jumping_to_land: bool = false
var air_vx: float = 0.0
var active_land_pos: Vector2 = Vector2.ZERO
var stuck_timer: float = 0.0

const MAX_JUMPS := 12

func _ready() -> void:
	if target == null:
		if is_inside_tree():
			var tree := get_tree()
			if tree != null:
				target = tree.get_first_node_in_group("player")
		if target == null and get_parent() != null:
			target = get_parent().get_node_or_null("Cyto")
	if target != null:
		last_target_floor_pos = target.global_position
		var target_body := target as CharacterBody2D
		if target_body != null:
			target_was_on_floor = target_body.is_on_floor()
	blink_timer = randf_range(0.8, 4.5)
	_init_face_nodes()

func _init_face_nodes() -> void:
	pass

func _set_blink_frame(_target_frame: int) -> void:
	pass

func _apply_visual_state(_is_moving: bool, _dir_x: float) -> void:
	pass

func _update_blink(delta: float) -> void:
	blink_timer -= delta
	if blink_timer <= 0.0:
		is_blinking = not is_blinking
		_set_blink_frame(1 if is_blinking else 0)
		blink_timer = randf_range(0.12, 0.2) if is_blinking else randf_range(2.0, 5.0)

func _raycast_ground(from_pos: Vector2, to_pos: Vector2) -> Dictionary:
	var space := get_world_2d().direct_space_state
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters2D.create(from_pos, to_pos, 1)
	query.exclude = [get_rid()]
	return space.intersect_ray(query)

func _has_floor_at(world_pos: Vector2) -> bool:
	return not _raycast_ground(world_pos + Vector2(0.0, 12.0), world_pos + Vector2(0.0, 26.0)).is_empty()

func _record_target_jumps() -> void:
	var target_body := target as CharacterBody2D
	if target_body == null:
		return
	var target_on_floor := target_body.is_on_floor()

	if target_was_on_floor and not target_on_floor and target_body.velocity.y < -100.0:
		pending_takeoff = last_target_floor_pos
		target_in_jump = true
	elif not target_was_on_floor and target_on_floor:
		if target_in_jump:
			var land_pos := target.global_position
			var changed_height: bool = abs(land_pos.y - pending_takeoff.y) >= 20.0
			var crossed_void: bool = not _has_floor_at(pending_takeoff.lerp(land_pos, 0.5))
			if changed_height or crossed_void:
				jump_queue.append({"takeoff": pending_takeoff, "land": land_pos})
				while jump_queue.size() > MAX_JUMPS:
					jump_queue.pop_front()
		target_in_jump = false

	if target_on_floor:
		last_target_floor_pos = target.global_position
	target_was_on_floor = target_on_floor

func _calc_jump_vx(from_pos: Vector2, land_pos: Vector2) -> float:
	var dy := land_pos.y - from_pos.y
	var t_up := -jump_velocity / gravity
	var h_max := (jump_velocity * jump_velocity) / (2.0 * gravity)
	var drop := maxf(4.0, h_max + dy)
	var t_down := sqrt(2.0 * drop / gravity)
	var t_flight := maxf(0.25, t_up + t_down)
	return clampf((land_pos.x - from_pos.x) / t_flight, -follow_speed * 1.15, follow_speed * 1.15)

func _physics_process(delta: float) -> void:
	_update_blink(delta)
	if jump_cooldown > 0.0:
		jump_cooldown -= delta

	if target == null:
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		return

	_record_target_jumps()

	var target_facing: float = 1.0
	if "last_facing_direction" in target:
		target_facing = target.last_facing_direction

	if global_position.y > 760.0:
		global_position = last_target_floor_pos + Vector2(-target_facing * minf(follow_distance, 45.0), -12.0)
		velocity = Vector2.ZERO
		is_jumping_to_land = false
		jump_queue.clear()
		stuck_timer = 0.0
		return

	if is_on_floor():
		is_jumping_to_land = false
	else:
		velocity.y += gravity * delta

	var same_level: bool = abs(target.global_position.y - global_position.y) <= 24.0
	var behind_distance: float = (target.global_position.x - global_position.x) * target_facing

	# Bersihkan lompatan yang sudah berhasil dilewati bot
	while not jump_queue.is_empty():
		var jp: Dictionary = jump_queue[0]
		var takeoff: Vector2 = jp["takeoff"]
		var land: Vector2 = jp["land"]
		if abs(global_position.y - land.y) <= 24.0 and (global_position.distance_to(land) < global_position.distance_to(takeoff) or _has_floor_at(global_position.lerp(land, 0.5))):
			jump_queue.pop_front()
		else:
			break

	# Jika selevel & sudah berada di posisi aman, atau Cyto berbalik arah melewati bot -> bersihkan antrean lama
	if same_level and behind_distance <= follow_distance + 12.0:
		jump_queue.clear()
		stuck_timer = 0.0
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0.0, follow_speed * delta * 12.0)
			move_and_slide()
			_apply_visual_state(false, target_facing)
			return

	if same_level and not jump_queue.is_empty():
		var takeoff_dx: float = jump_queue[0]["takeoff"].x - global_position.x
		var target_dx: float = target.global_position.x - global_position.x
		if abs(takeoff_dx) > 12.0 and abs(target_dx) > 12.0 and signf(takeoff_dx) != signf(target_dx):
			jump_queue.clear()

	# Saat di udara mengikuti lintasan parabola mulus menuju titik pendaratan
	if not is_on_floor():
		if is_jumping_to_land:
			var steer_dir := signf(air_vx) if air_vx != 0.0 else target_facing
			var blocked_by_side: bool = velocity.y < 0.0 and (
				not _raycast_ground(global_position, global_position + Vector2(steer_dir * 18.0, 0.0)).is_empty()
				or not _raycast_ground(global_position + Vector2(0.0, 16.0), global_position + Vector2(steer_dir * 18.0, 16.0)).is_empty()
			)
			velocity.x = 0.0 if blocked_by_side else air_vx
			move_and_slide()
			_apply_visual_state(true, steer_dir)
		else:
			move_and_slide()
		return

	# Di lantai: cek apakah ada pasangan lompat di antrean yang selevel dengan bot
	var desired_x: float = target.global_position.x - (target_facing * follow_distance)
	var should_follow: bool = not same_level or behind_distance > follow_distance + 12.0

	if not jump_queue.is_empty():
		var jp: Dictionary = jump_queue[0]
		var takeoff: Vector2 = jp["takeoff"]
		var land: Vector2 = jp["land"]
		if abs(takeoff.y - global_position.y) <= 28.0:
			desired_x = takeoff.x
			should_follow = true
			if abs(takeoff.x - global_position.x) <= 12.0 and jump_cooldown <= 0.0:
				velocity.y = jump_velocity
				air_vx = _calc_jump_vx(global_position, land)
				velocity.x = air_vx
				is_jumping_to_land = true
				active_land_pos = land
				jump_cooldown = 0.3
				move_and_slide()
				_apply_visual_state(true, signf(air_vx) if air_vx != 0.0 else target_facing)
				return
	elif target_in_jump and abs(pending_takeoff.y - global_position.y) <= 28.0:
		var takeoff_dir := signf(pending_takeoff.x - global_position.x)
		var target_dir := signf(target.global_position.x - global_position.x)
		if takeoff_dir != 0.0 and takeoff_dir == target_dir:
			desired_x = pending_takeoff.x
			should_follow = true

	var diff_x: float = desired_x - global_position.x
	var dir_x: float = signf(diff_x) if abs(diff_x) > 4.0 else target_facing

	# Ledge safety: jika selevel dan sudah dekat di platform yang sama, berhenti aman di tepi
	if same_level and should_follow and not _has_floor_at(global_position + Vector2(dir_x * 12.0, 0.0)):
		if abs(target.global_position.x - global_position.x) <= follow_distance + 30.0:
			velocity.x = move_toward(velocity.x, 0.0, follow_speed * delta * 12.0)
			move_and_slide()
			_apply_visual_state(false, dir_x)
			return
		# Lompat void hanya jika menuju ke arah Cyto (tidak pernah lompat ke belakang menjauhi Cyto)
		var to_target_dir := signf(target.global_position.x - global_position.x)
		if jump_cooldown <= 0.0 and dir_x == to_target_dir:
			velocity.y = jump_velocity
			air_vx = dir_x * follow_speed
			velocity.x = air_vx
			is_jumping_to_land = true
			jump_cooldown = 0.3
			move_and_slide()
			_apply_visual_state(true, dir_x)
			return

	if should_follow and is_on_wall() and jump_cooldown <= 0.0:
		velocity.y = jump_velocity
		air_vx = dir_x * follow_speed * 0.85
		velocity.x = air_vx
		is_jumping_to_land = true
		jump_cooldown = 0.3
		move_and_slide()
		_apply_visual_state(true, dir_x)
		return

	if should_follow and abs(velocity.x) < 15.0:
		stuck_timer += delta
	else:
		stuck_timer = 0.0

	if global_position.distance_to(target.global_position) > 480.0 or stuck_timer > 3.0:
		global_position = last_target_floor_pos + Vector2(-target_facing * minf(follow_distance, 45.0), -12.0)
		velocity = Vector2.ZERO
		is_jumping_to_land = false
		jump_queue.clear()
		stuck_timer = 0.0
		return

	if should_follow:
		var cur_speed := follow_speed
		if abs(diff_x) > follow_distance + 40.0 or not jump_queue.is_empty():
			cur_speed *= 1.25
		velocity.x = move_toward(velocity.x, dir_x * cur_speed, cur_speed * delta * 8.0)
		move_and_slide()
		_apply_visual_state(true, dir_x)
	else:
		velocity.x = move_toward(velocity.x, 0.0, follow_speed * delta * 12.0)
		move_and_slide()
		_apply_visual_state(false, dir_x)
