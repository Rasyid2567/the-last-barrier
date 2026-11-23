extends CharacterBody2D

@export var speed: float = 220.0
@export var jump_velocity: float = -405.0
@export var gravity: float = 980.0
@export var attack_damage: int = 25
@export var attack_cooldown: float = 0.35
@export var attack_pose_hold_time: float = 0.55

@onready var body: AnimatedSprite2D = $Body
@onready var face_idle: Node2D = $Body/FaceIdle
@onready var face_walk: Node2D = $Body/FaceWalk
@onready var weapon_pivot: Node2D = $Body/WeaponPivot
@onready var weapon_hitbox: Area2D = $Body/WeaponPivot/Hitbox

var last_facing_direction: float = 1.0
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var attack_pose_timer: float = 0.0
var hit_targets: Array[Node] = []
var spawn_position: Vector2

const WEAPON_REST_ANGLE_IDLE := -35.0
const WEAPON_REST_ANGLE_WALK := 35.0
const WEAPON_POS_IDLE := Vector2(-12.5, 8.5)
const WEAPON_POS_WALK := Vector2(1.5, 7.5)

func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	face_idle.visible = true
	face_walk.visible = false
	weapon_pivot.position = WEAPON_POS_IDLE
	weapon_pivot.rotation_degrees = WEAPON_REST_ANGLE_IDLE
	weapon_pivot.show_behind_parent = false
	weapon_hitbox.monitoring = false
	weapon_hitbox.body_entered.connect(_on_weapon_hitbox_body_entered)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_attack()
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_J or event.keycode == KEY_F):
		_try_attack()

func _find_nearest_enemy() -> Node2D:
	if not is_inside_tree():
		return null
	var nearest: Node2D = null
	var min_dist_sq := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var dist_sq := global_position.distance_squared_to(enemy.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			nearest = enemy
	return nearest

func _try_attack() -> void:
	if is_attacking or attack_cooldown_timer > 0.0:
		return
	var nearest_enemy := _find_nearest_enemy()
	if nearest_enemy != null:
		var dx := nearest_enemy.global_position.x - global_position.x
		if abs(dx) > 1.0:
			last_facing_direction = signf(dx)

	is_attacking = true
	attack_cooldown_timer = attack_cooldown
	attack_pose_timer = attack_pose_hold_time
	hit_targets.clear()
	weapon_pivot.position = WEAPON_POS_WALK
	weapon_pivot.rotation_degrees = -45.0
	weapon_hitbox.monitoring = true

	var tween := create_tween()
	tween.tween_property(weapon_pivot, "rotation_degrees", 115.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		weapon_hitbox.monitoring = false
	)
	tween.tween_property(weapon_pivot, "rotation_degrees", WEAPON_REST_ANGLE_WALK, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		is_attacking = false
	)

func _on_weapon_hitbox_body_entered(hit_body: Node2D) -> void:
	if hit_body in hit_targets:
		return
	if hit_body.is_in_group("enemies") and hit_body.has_method("take_damage"):
		hit_targets.append(hit_body)
		hit_body.take_damage(attack_damage)

func _physics_process(delta: float) -> void:
	if global_position.y > 760.0:
		global_position = spawn_position
		velocity = Vector2.ZERO
		return

	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	if attack_pose_timer > 0.0 and not is_attacking:
		attack_pose_timer -= delta

	# Terapkan gravitasi jika sedang tidak berada di lantai
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Tombol lompat saat menyentuh lantai (Spasi, W, atau Panah Atas)
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_action_just_pressed("ui_up"):
			velocity.y = jump_velocity

	# Input pergerakan horizontal (A/D atau Panah Kiri/Kanan)
	var direction := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		direction -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		direction += 1.0

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, speed * delta * 10.0)
		last_facing_direction = signf(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 12.0)

	move_and_slide()

	var base_scale_x: float = abs(body.scale.x)
	var is_moving_horizontal: bool = abs(velocity.x) > 10.0 or direction != 0.0
	var show_walk_pose: bool = is_moving_horizontal or is_attacking or attack_pose_timer > 0.0

	# Kontrol animasi & arah hadap
	if show_walk_pose:
		# Bergerak ke samping atau sedang menyerang (hadap samping)
		if is_moving_horizontal:
			if body.animation != "walk" or not body.is_playing():
				body.play("walk")
		else:
			body.animation = "walk"
			body.pause()
			body.frame = 0
		face_idle.visible = false
		face_walk.visible = true
		weapon_pivot.position = WEAPON_POS_WALK
		if not is_attacking:
			weapon_pivot.rotation_degrees = WEAPON_REST_ANGLE_WALK
		weapon_pivot.show_behind_parent = last_facing_direction < 0.0
		body.scale.x = last_facing_direction * base_scale_x
	else:
		# Diam di lantai atau lompat vertikal di tempat (Idle front-facing)
		if body.animation != "idle" or not body.is_playing():
			body.play("idle")
		face_idle.visible = true
		face_walk.visible = false
		weapon_pivot.position = WEAPON_POS_IDLE
		if not is_attacking:
			weapon_pivot.rotation_degrees = WEAPON_REST_ANGLE_IDLE
		weapon_pivot.show_behind_parent = false
		body.scale.x = base_scale_x
