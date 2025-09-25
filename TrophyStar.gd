extends Sprite2D

signal star_collected(points: int)

@export var spins_per_sec: float = 1.25
@export var pickup_radius: float = 48.0
@export var points: int = 5
@export var player_path: NodePath

var _player: Node2D

func _ready() -> void:
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as Node2D
	# Ensure a visible texture even if none assigned
	if texture == null:
		texture = _make_star_texture(20, 20)
	hide()

func _process(delta: float) -> void:
	rotation += TAU * spins_per_sec * delta
	if visible and _player:
		if global_position.distance_to(_player.global_position) <= pickup_radius:
			star_collected.emit(points)
			hide() # reuse instead of freeing

func spawn_at(pos: Vector2) -> void:
	global_position = pos
	show()

# Tiny diamond
func _make_star_texture(w: int, h: int) -> Texture2D:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx: int = w >> 1   # half width
	var cy: int = h >> 1   # half height
	for y in range(h):
		for x in range(w):
			var dx: int = abs(x - cx)
			var dy: int = abs(y - cy)
			if dx + dy <= int(min(cx, cy) - 1):
				img.set_pixel(x, y, Color(1.0, 0.95, 0.3, 1.0))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	return tex
