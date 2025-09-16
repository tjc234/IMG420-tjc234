extends CanvasLayer
signal start_game

# ensure these connections exist when button initializing
func _ready() -> void:
	if not $StartButton.pressed.is_connected(_on_start_button_pressed):
		$StartButton.pressed.connect(_on_start_button_pressed)
	if not $MessageTimer.timeout.is_connected(_on_message_timer_timeout):
		$MessageTimer.timeout.connect(_on_message_timer_timeout)
	$StartButton.show()

# handle message functionality
func show_message(text: String, seconds: float = 3.0) -> void:
	$Message.text = text
	$Message.show()
	$MessageTimer.stop()
	$MessageTimer.wait_time = seconds
	$MessageTimer.one_shot = true
	$MessageTimer.start()

# handle display of game over message
func show_game_over(did_win: bool) -> void:
	if did_win:
		show_message("WIN!", 3.0)
	else:
		show_message("LOSE", 3.0)
	await $MessageTimer.timeout

	$Message.text = "Hug the Creeps!"
	$Message.show()
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()

# handle score incrementation
func update_score(score: int) -> void:
	$ScoreLabel.text = str(score)

# update time counter
func update_time(seconds_left: int) -> void:
	$TimeLabel.text = "Remaining Time: %d" % seconds_left

#update high score counter
func update_high_score(high: int) -> void:
	$HighScoreLabel.text = "Best: %d" % high

# update speed booster
func flash_speed_boost() -> void:
	show_message("Speed Up!", 3.0)

# handle button press
func _on_start_button_pressed() -> void:
	$StartButton.hide()
	start_game.emit()

# hide message after timeout
func _on_message_timer_timeout() -> void:
	$Message.hide()
