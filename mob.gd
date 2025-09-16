extends RigidBody2D

# assign 1 of three animation types to mob
func _ready():
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	$AnimatedSprite2D.play()

# remove mobs that move to outside of screen window
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
