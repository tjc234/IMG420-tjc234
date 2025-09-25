extends Node

@export var mob_scene: PackedScene

const WIN_TARGET: int = 75

var score: int = 0
var high_score: int = 0
var time_left: int = 60
var base_speed: float = 400.0
var speed_step: float = 50.0
var game_active: bool = false

func _ready() -> void:
	# --- HUD -> Main (start game) ---
	if has_node("HUD") and not $HUD.start_game.is_connected(self.new_game):
		$HUD.start_game.connect(self.new_game)

	# --- Player -> Main (hugged) ---
	if not $Player.hugged.is_connected(self._on_player_hugged):
		$Player.hugged.connect(self._on_player_hugged)

	# --- Timers -> Main ---
	if not $StartTimer.timeout.is_connected(self._on_start_timer_timeout):
		$StartTimer.timeout.connect(self._on_start_timer_timeout)
	if not $MobTimer.timeout.is_connected(self._on_mob_timer_timeout):
		$MobTimer.timeout.connect(self._on_mob_timer_timeout)
	if not $TickTimer.timeout.is_connected(self._on_tick_timer_timeout):
		$TickTimer.timeout.connect(self._on_tick_timer_timeout)
	if not $GameTimer.timeout.is_connected(self._on_game_timer_timeout):
		$GameTimer.timeout.connect(self._on_game_timer_timeout)

	# --- TrophyStar hookups (only if node exists) ---
	if has_node("TrophyStar"):
		# Set player_path in code if not set in Inspector
		if $TrophyStar.player_path == NodePath():
			$TrophyStar.player_path = $Player.get_path()
		# Star -> Main (award bonus on collect)
		if not $TrophyStar.star_collected.is_connected(self._on_star_collected):
			$TrophyStar.star_collected.connect(self._on_star_collected)

	# --- OPTIONAL: PulseAura hookups (child of Player) ---
	if has_node("Player/PulseAura"):
		# Start button also activates the aura
		if has_node("HUD") and not $HUD.start_game.is_connected($Player/PulseAura.activate):
			$HUD.start_game.connect($Player/PulseAura.activate)
		# Aura → Main buff/feedback
		if not $Player/PulseAura.aura_charged.is_connected(self._on_aura_charged):
			$Player/PulseAura.aura_charged.connect(self._on_aura_charged)

	# --- Sanity check: exported mob scene assigned ---
	if mob_scene == null:
		push_error("[Main] Assign mob_scene (Mob.tscn) on the Main node in the Inspector")

	# --- Boot-time HUD values (so labels aren't blank) ---
	if has_node("HUD"):
		$HUD.update_high_score(high_score)
		$HUD.update_score(0)
		$HUD.update_time(60)

func new_game() -> void:
	game_active = true
	score = 0
	time_left = 60

	$Player.speed = base_speed
	$HUD.update_score(score)
	$HUD.update_time(time_left)
	$HUD.update_high_score(high_score)

	# Clear leftover mobs
	get_tree().call_group("mobs", "queue_free")

	# Reset player and show round title
	$Player.start($StartPosition.position)
	$HUD.show_message("Hug the Creeps!", 3.0)

	# Turn aura on (if present)
	if has_node("Player/PulseAura"):
		$Player/PulseAura.activate()

	# Start timers
	$StartTimer.start()  # small delay before spawning
	$GameTimer.start()   # 60s total
	$TickTimer.start()   # 1s countdown ticks

func game_over() -> void:
	game_active = false
	$TickTimer.stop()
	$GameTimer.stop()
	$MobTimer.stop()
	$Player.stop()

	# Turn aura off
	if has_node("Player/PulseAura"):
		$Player/PulseAura.deactivate()

	# End-of-round win/lose check
	var did_win: bool = score >= WIN_TARGET

	# Update session high score
	if score > high_score:
		high_score = score
	$HUD.update_high_score(high_score)

	$HUD.show_game_over(did_win)

func _on_start_timer_timeout() -> void:
	$MobTimer.start()

func _on_tick_timer_timeout() -> void:
	time_left -= 1
	$HUD.update_time(time_left)

func _on_game_timer_timeout() -> void:
	game_over()

func _on_mob_timer_timeout() -> void:
	# Spawn a mob
	var mob: RigidBody2D = mob_scene.instantiate() as RigidBody2D
	mob.add_to_group("mobs")

	# Random spawn along path
	var mob_spawn_location: Node2D = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position

	# Random travel direction & speed
	var direction: float = mob_spawn_location.rotation + PI / 2.0
	direction += randf_range(-PI / 4.0, PI / 4.0)
	mob.rotation = direction

	var velocity: Vector2 = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	add_child(mob)

func _on_player_hugged(mob: Node) -> void:
	if not game_active:
		return

	# Remember where the mob was for TrophyStar spawn
	var drop_pos: Vector2 = Vector2.ZERO
	if is_instance_valid(mob) and mob is Node2D:
		drop_pos = (mob as Node2D).global_position
		mob.queue_free()

	# Base score for a hug
	score += 1
	$HUD.update_score(score)

	# Spawn a collectible star where the mob was
	if has_node("TrophyStar"):
		$TrophyStar.spawn_at(drop_pos)

	# Speed boost every 10 hugs
	if score % 10 == 0:
		$Player.speed += speed_step
		$HUD.flash_speed_boost()

func _on_star_collected(points: int) -> void:
	if not game_active:
		return
	score += points
	$HUD.update_score(score)
	$HUD.show_message("+%d Bonus!" % points, 1.0)

func _on_aura_charged() -> void:
	if not game_active:
		return
	$Player.speed += 5.0
	$HUD.show_message("Aura charged! +Speed", 1.5)
