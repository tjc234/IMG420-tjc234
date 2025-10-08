extends Node

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
	if has_node("MobTimer"):
		$MobTimer.stop()
		$MobTimer.autostart = false

	if not $TickTimer.timeout.is_connected(self._on_tick_timer_timeout):
		$TickTimer.timeout.connect(self._on_tick_timer_timeout)
	if not $GameTimer.timeout.is_connected(self._on_game_timer_timeout):
		$GameTimer.timeout.connect(self._on_game_timer_timeout)

	# --- Hook Player into the C# FlockManager (fix indent so it always runs) ---
	var fm := get_node_or_null("FlockManager")
	if fm:
		# Calls C# FlockManager.SetPlayer(Player)
		fm.call("SetPlayer", $Player)
		fm.call("EnableAlwaysOnChase", 2.0)

	# --- TrophyStar hookups (only if node exists) ---
	if has_node("TrophyStar"):
		if $TrophyStar.player_path == NodePath():
			$TrophyStar.player_path = $Player.get_path()
		if not $TrophyStar.star_collected.is_connected(self._on_star_collected):
			$TrophyStar.star_collected.connect(self._on_star_collected)

	# --- OPTIONAL: PulseAura hookups (child of Player) ---
	if has_node("Player/PulseAura"):
		if has_node("HUD") and not $HUD.start_game.is_connected($Player/PulseAura.activate):
			$HUD.start_game.connect($Player/PulseAura.activate)
		if not $Player/PulseAura.aura_charged.is_connected(self._on_aura_charged):
			$Player/PulseAura.aura_charged.connect(self._on_aura_charged)

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

	# Clear leftover mobs/boids (we use the same group)
	get_tree().call_group("mobs", "queue_free")

	# Reset player and show round title
	$Player.start($StartPosition.position)
	$HUD.show_message("Run from the Creeps!", 3.0)

	# Turn aura on (if present)
	if has_node("Player/PulseAura"):
		$Player/PulseAura.activate()

	# Start timers (NO MobTimer)
	$StartTimer.start()  # small delay before spawning
	$GameTimer.start()   # 60s total
	$TickTimer.start()   # 1s countdown ticks


func game_over() -> void:
	game_active = false
	$TickTimer.stop()
	$GameTimer.stop()
	# Ensure old MobTimer doesn’t run
	if has_node("MobTimer"):
		$MobTimer.stop()
	$Player.stop()

	if has_node("Player/PulseAura"):
		$Player/PulseAura.deactivate()

	var did_win: bool = score >= WIN_TARGET

	if score > high_score:
		high_score = score
	$HUD.update_high_score(high_score)

	$HUD.show_game_over(did_win)


# === Instead of starting MobTimer, spawn the flock once when the round begins ===
func _on_start_timer_timeout() -> void:
	# Despawn any stragglers, then spawn a fresh flock
	if has_node("FlockSpawner"):
		$FlockSpawner.DespawnAll()
		$FlockSpawner.Spawn()
	# If you want periodic re-spawns, you can start a custom timer here instead of MobTimer.


func _on_tick_timer_timeout() -> void:
	time_left -= 1
	$HUD.update_time(time_left)


func _on_game_timer_timeout() -> void:
	game_over()


func _on_player_hugged(mob: Node) -> void:
	if not game_active:
		return

	var drop_pos: Vector2 = Vector2.ZERO
	if is_instance_valid(mob) and mob is Node2D:
		drop_pos = (mob as Node2D).global_position
		mob.queue_free()

	score += 1
	$HUD.update_score(score)

	if has_node("TrophyStar"):
		$TrophyStar.spawn_at(drop_pos)

	if score % 10 == 0:
		$Player.speed += speed_step
		$HUD.flash_speed_boost()


func _on_star_collected(points: int) -> void:
	if not game_active:
		return
	score += points
	$HUD.update_score(score)


func _on_aura_charged() -> void:
	if not game_active:
		return
	$Player.speed += 5.0
