extends CompanionBase

@onready var face_idle: AnimatedSprite2D = $Body/FaceIdle
@onready var face_walk: AnimatedSprite2D = $Body/FaceWalk

func _init() -> void:
	follow_distance = 95.0

func _init_face_nodes() -> void:
	face_idle.visible = true
	face_walk.visible = false
	face_idle.pause()
	face_walk.pause()
	face_idle.frame = 0
	face_walk.frame = 0

func _set_blink_frame(target_frame: int) -> void:
	face_idle.frame = target_frame
	face_walk.frame = target_frame

func _apply_visual_state(is_moving: bool, dir_x: float) -> void:
	var base_scale_x: float = abs(body.scale.x)
	if is_moving:
		body.play("walk")
		face_idle.visible = false
		face_walk.visible = true
		# Sprite asli Lacto bawaannya menghadap ke kiri, balik arahnya (-dir_x) agar menghadap ke depan arah jalan
		body.scale.x = -dir_x * base_scale_x
	else:
		body.play("idle")
		face_idle.visible = true
		face_walk.visible = false
		body.scale.x = base_scale_x
