extends Area2D
signal hugged(mob)

@export var speed := 400.0
var screen_size: Vector2
var active: bool = false

# handle player initialization requirements
func _ready():
	screen_size = get_viewport_rect().size
	hide()
	# Ensure body_entered is wired (or keep your editor connection)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)

# if the game is not yet active, do not process input
func _process(delta):
	if not active:
		return

	# create movement vectors based on input (arrow keys)
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"): velocity.x += 1
	if Input.is_action_pressed("move_left"):  velocity.x -= 1
	if Input.is_action_pressed("move_down"):  velocity.y += 1
	if Input.is_action_pressed("move_up"):    velocity.y -= 1

	# if moving, play the walk animation
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	# if sitting still, do not play animation
	else:
		$AnimatedSprite2D.stop()

	# determine postion based on velocity
	position += velocity * delta
	
	# limit player position to window
	position = position.clamp(Vector2.ZERO, screen_size)

	# if has x velocity, walk animation
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	# if has y veloicty, swim animation
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0

# emit hug signal if player collides with mob
func _on_body_entered(body):
	if active and body.is_in_group("mobs"):
		hugged.emit(body)

# place player and enable collision/movement
func start(pos: Vector2):
	position = pos
	show()
	active = true
	$CollisionShape2D.disabled = false

# handle game end, stop input, disable input and hide player
func stop():
	active = false
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
