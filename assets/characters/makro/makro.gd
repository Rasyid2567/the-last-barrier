extends CompanionBase

@onready var face_idle: Node2D = $Body/FaceIdle
@onready var face_walk: Node2D = $Body/FaceWalk
@onready var eye_left: AnimatedSprite2D = $Body/FaceIdle/EyeLeft
@onready var eye_right: AnimatedSprite2D = $Body/FaceIdle/EyeRight
@onready var eye_side: AnimatedSprite2D = $Body/FaceWalk/EyeSide

func _init() -> void:
	follow_distance = 140.0

func _init_face_nodes() -> void:
	eye_left.pause()
	eye_right.pause()
	eye_side.pause()
	eye_left.frame = 0
	eye_right.frame = 0
	eye_side.frame = 0

func _set_blink_frame(target_frame: int) -> void:
	eye_left.frame = target_frame
	eye_right.frame = target_frame
	eye_side.frame = target_frame

func _apply_visual_state(is_moving: bool, dir_x: float) -> void:
	var base_scale_x: float = abs(body.scale.x)
	if is_moving:
		body.play("walk")
		face_idle.visible = false
		face_walk.visible = true
		body.scale.x = dir_x * base_scale_x
	else:
		body.play("idle")
		face_idle.visible = true
		face_walk.visible = false
		body.scale.x = base_scale_x
