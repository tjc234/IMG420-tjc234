extends Node
@export var mob_scene: PackedScene

# initialize variables
const WIN_TARGET := 75
var score: int = 0
var high_score: int = 0
var time_left: int = 60
var base_speed: float = 400.0
var speed_step: float = 50.0
var game_active: bool = false

# ensure connections exist, I had a lot of trouble with wiring connections via editor
func _ready() -> void:
	if not $HUD.start_game.is_connected(self.new_game):
		$HUD.start_game.connect(self.new_game)

	if not $Player.hugged.is_connected(self._on_player_hugged):
		$Player.hugged.connect(self._on_player_hugged)

	if not $StartTimer.timeout.is_connected(self._on_start_timer_timeout):
		$StartTimer.timeout.connect(self._on_start_timer_timeout)
	if not $MobTimer.timeout.is_connected(self._on_mob_timer_timeout):
		$MobTimer.timeout.connect(self._on_mob_timer_timeout)
	if not $TickTimer.timeout.is_connected(self._on_tick_timer_timeout):
		$TickTimer.timeout.connect(self._on_tick_timer_timeout)
	if not $GameTimer.timeout.is_connected(self._on_game_timer_timeout):
		$GameTimer.timeout.connect(self._on_game_timer_timeout)

	# show current high score on boot
	$HUD.update_high_score(high_score)

# handle spawning of new game
func new_game() -> void:
	game_active = true
	score = 0
	time_left = 60

	# reset player speed to base speed
	$Player.speed = base_speed
	
	# update resetted score values to HUD
	$HUD.update_score(score)
	$HUD.update_time(time_left)
	$HUD.update_high_score(high_score)

	# call queue free on all mob nodes (delete all instances of mobs)
	get_tree().call_group("mobs", "queue_free")

	# set player starting postion
	$Player.start($StartPosition.position)
	$HUD.show_message("Hug the Creeps!", 3.0)

	# start hud timers
	$StartTimer.start()
	$GameTimer.start()
	$TickTimer.start()

# handle gracefull game exiting
func game_over() -> void:
	game_active = false
	$TickTimer.stop()
	$GameTimer.stop()
	$MobTimer.stop()
	$Player.stop()

	# win/lose check at end of round
	var did_win := score >= WIN_TARGET

	# update high score for the session
	if score > high_score:
		high_score = score
	$HUD.update_high_score(high_score)

	# display game over, win-lose message
	$HUD.show_game_over(did_win)

# on start timer finish, spawn mobs
func _on_start_timer_timeout() -> void:
	$MobTimer.start()

# decrement time left every second
func _on_tick_timer_timeout() -> void:
	time_left -= 1
	$HUD.update_time(time_left)

# when game time is over, end the game
func _on_game_timer_timeout() -> void:
	game_over()

# handle spawning of mobs
func _on_mob_timer_timeout() -> void:
	# create instance of mob
	var mob = mob_scene.instantiate()
	
	# add this mob to group of mobs
	mob.add_to_group("mobs")

	# determine random location for mob spawning
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position

	# determing random movement direction on spawned mob
	var direction = mob_spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# set mob velocity based on direction
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)
	
	# create another mob
	add_child(mob)

# handle collision
func _on_player_hugged(mob: Node) -> void:
	if not game_active:
		return
	
	# delete the hugged mob
	if is_instance_valid(mob):
		mob.queue_free()

	# increment score
	score += 1
	$HUD.update_score(score)

	# handle speed boost every 10 hugs
	if score % 10 == 0:
		$Player.speed += speed_step
		$HUD.flash_speed_boost()
