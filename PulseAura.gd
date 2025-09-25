extends Sprite2D
signal aura_charged

@export var pulse_speed: float = 4.0      # how fast it pulses
@export var pulse_amount: float = 0.18    # how much it grows/shrinks (0.0–0.5)
@export var pulses_per_charge: int = 3    # emit aura_charged after N pulses
@export var base_alpha: float = 0.5       # base visibility

var _t: float = 0.0
var _pulses: int = 0
var _active: bool = false
var _base_scale: Vector2 = Vector2(0.5, 0.5)  # half of the original (1,1)

func _ready() -> void:
	set_process(true)
	# Give it a texture if none assigned (same size as original)
	if texture == null:
		texture = _make_radial_texture(192, 192)

	centered = true
	z_index = 1000
	visible = true
	scale = _base_scale
	modulate = Color(1, 1, 1, base_alpha)

func _process(delta: float) -> void:
	if not _active:
		return

	_t += delta * pulse_speed

	# Pulse scale around _base_scale
	var s: float = 1.0 + pulse_amount * (0.5 + 0.5 * sin(_t))
	scale = _base_scale * s

	# Slight shimmer
	var a: float = clamp(base_alpha * (0.85 + 0.15 * (0.5 + 0.5 * sin(_t))), 0.05, 1.0)
	var c: Color = modulate
	c.a = a
	modulate = c

	# Count pulses
	if _t >= TAU:
		_t = 0.0
		_pulses += 1
		if _pulses >= pulses_per_charge:
			_pulses = 0
			aura_charged.emit()

func activate() -> void:
	_active = true
	_t = 0.0
	_pulses = 0
	show()

func deactivate() -> void:
	_active = false
	scale = _base_scale
	var c: Color = modulate
	c.a = base_alpha
	modulate = c
	hide()


func _make_radial_texture(w: int, h: int) -> Texture2D:
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1,1,1,0.9), Color(1,1,1,0.0)])
	grad.offsets = PackedFloat32Array([0.0, 1.0])

	var tex := GradientTexture2D.new()
	tex.width = w
	tex.height = h
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.gradient = grad
	return tex
