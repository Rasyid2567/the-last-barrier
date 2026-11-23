extends Sprite2D

@export var map_width: int = 3840
@export var viewport_height: int = 720

func _ready() -> void:
	texture = preload("res://assets/environment/ground/ground.png")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	
	# ground.png berukuran 256 x 128
	# Skalakan secara proporsional agar tinggi pas memenuhi viewport_height (720px)
	var scale_factor: float = float(viewport_height) / 128.0 # 5.625
	scale = Vector2(scale_factor, scale_factor)
	
	centered = false
	position = Vector2.ZERO
	region_enabled = true
	# Lebar region dibagi scale_factor agar hasil akhir setelah diskalakan tepat map_width
	region_rect = Rect2(0, 0, float(map_width) / scale_factor, 128.0)
	z_index = -10
	show()

	print("Side-scroller background ground.png aktif: ", map_width, " x ", viewport_height)
