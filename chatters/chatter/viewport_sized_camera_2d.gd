extends Camera2D

func _process(_delta):
	var screen_size = get_viewport_rect().size
	offset.x = -84
	offset.y = (-screen_size.y + 74) / zoom.y
