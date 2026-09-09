extends Node2D

@onready var fadeoverlay: ColorRect = $fadeoverlay
@onready var prompt_label: Label = $prompt_label
@onready var best_run_label: Label = $best_run_panel/best_run_label
@onready var title_label: Label = $title_label

var original_position := position

const SAVE_PATH: String = "user://highscore.save"

func _ready() -> void:
	show_best_run()
	bounce_title()

func _process(_delta: float) -> void:
	#blink effect on text
	prompt_label.visible = int(Time.get_ticks_msec() / 500.0) % 2 == 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"): #spaceeee by defualt
		start_game()

func start_game() -> void:
	set_process_unhandled_input(false) # to prevant dougel trig
	var tween := create_tween()
	tween.tween_property(fadeoverlay, "modulate:a", 1.0, 0.2)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func start_game_transition() -> void:
	var fade := ColorRect.new()
	fade.color = Color.BLACK
	fade.color.a = 0.0
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	for i in range(5):
		position = original_position + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		await get_tree().create_timer(0.03).timeout
	position = original_position
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func show_best_run() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		best_run_label.text = "BEST RUN\nLEVEL: 1\nTIME: 00.00"
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var best_level = file.get_var()
	var best_time = file.get_var()
	var minutes = int(best_time /60.0)
	var seconds = int(best_time) % 60
	best_run_label.text = "BEST RUN\nLEVEL: %d\nTIME: %02d:%02d" % [best_level, minutes, seconds]

func bounce_title() -> void:
	var start_position := title_label.position
	while true:
		var tween := create_tween()
		tween.tween_property(title_label, "position:y", start_position.y - 25, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(title_label, "position:y", start_position.y, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		await tween.finished
		await get_tree().create_timer(0.25).timeout

#controls
func _on_controls_button_pressed() -> void:
	$controls_panel.visible = true

func _on_close_button_pressed() -> void:
	$controls_panel.visible = false

#credits
func _on_credits_button_pressed() -> void:
	$credits_panel.visible = true

func _on_creditsclose_button_pressed() -> void:
	$credits_panel.visible = false

#upgrades
func _on_achievements_button_pressed() -> void:
	$achievements_panel.visible = true

func _on_achievementsclose_button_pressed() -> void:
	$achievements_panel.visible = false

#best run
func _on_best_run_button_pressed() -> void:
	$best_run_panel.visible = true

func _on_bestrun_close_button_pressed() -> void:
	$best_run_panel.visible = false
