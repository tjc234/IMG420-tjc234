extends Area2D
signal hugged(mob)

@export var speed := 400.0
var screen_size: Vector2
var active: bool = false

func _ready():
	screen_size = get_viewport_rect().size
	hide()
	# listen for Area2D overlaps (works with boid Area2D)
	if not is_connected("area_entered", Callable(self, "_on_area_entered")):
		area_entered.connect(_on_area_entered)
	# make sure this player is on Layer 1, mask includes Layer 2 (editor is fine)

func _process(delta):
	if not active: return

	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"): velocity.x += 1
	if Input.is_action_pressed("move_left"):  velocity.x -= 1
	if Input.is_action_pressed("move_down"):  velocity.y += 1
	if Input.is_action_pressed("move_up"):    velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

# NEW: area-based collision (boids use Area2D)
func _on_area_entered(area: Area2D) -> void:
	var root := area.get_parent()
	if active and root and root.is_in_group("mobs"):
		hugged.emit(root)

# legacy path not used now, but harmless if still connected in editor
func _on_body_entered(body: Node) -> void:
	if active and body.is_in_group("mobs"):
		hugged.emit(body)

func start(pos: Vector2):
	position = pos
	show()
	active = true
	$CollisionShape2D.disabled = false

func stop():
	active = false
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
