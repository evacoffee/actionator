extends CanvasLayer

const HEART_SIZE: int = 20
var player: Node2D

const HEART_FULL = preload("res://assets/images/ui/HeartFull.png")
const HEART_HALF = preload("res://assets/images/ui/HeartHalf.png")
const HEART_EMPTY = preload("res://assets/images/ui/HeartEmpty.png")
const ABADDON_BOLD = preload("res://assets/font/Abaddon Bold.ttf")

@onready var fadeoverlay: ColorRect = $fadeoverlay
@onready var hearts_container: HBoxContainer = $hearts
@onready var stamina_bar: ProgressBar = $stamina_bar
@onready var run_timer: Label = $run_timer
@onready var run_results: Panel = $run_results
@onready var title: Label = $run_results/title
@onready var time_label: Label = $run_results/time_label
@onready var level_label: Label = $run_results/level_label
@onready var apples_label: Label = $run_results/apples_label
@onready var restart_label: Label = $run_results/restart_label
@onready var pause_menu: Panel = $pause_menu
@onready var resume_button: Button = $pause_menu/resume_button
@onready var quit_button: Button = $pause_menu/quit_button
@onready var best_level_label: Label = $run_results/best_level_label
@onready var best_time_label: Label = $run_results/best_time_label
@onready var heartbeat: AudioStreamPlayer = $heartbeat
@onready var new_best: Label = $new_best
@onready var combo_label: Label = $combo
@onready var upgrade_label: Label = $upgrade

func set_player(p) -> void:
	player = p
	if player:
		player.health_changed.connect(_update_health)
		player.stamina_changed.connect(_update_stamina)
		_update_health(player.health)
		_update_stamina(player.stamina)

func _update_health(new_health: int) -> void:
	var hearts = hearts_container.get_children()
	var max_hearts = len(hearts)
	var full = int(float(new_health) / HEART_SIZE)
	var half = 1 if (new_health % HEART_SIZE) > 0 else 0
	var empty = max_hearts - (full + half)
	#update full hearts
	for i in full:
		hearts[i].texture = HEART_FULL
	#update half heart
	if half:
		hearts[full].texture = HEART_HALF
	#update empty hearts
	for i in empty:
		hearts[len(hearts) - 1 - i].texture = HEART_EMPTY
	#low health heartbeat
	if new_health <= 20 and new_health > 0:
		if heartbeat.playing == false:
			heartbeat.play()
	else: 
		heartbeat.stop()

func _update_stamina(new_stamina: float) -> void:
	stamina_bar.value = new_stamina

func fade(to_alpha: float) -> void:
	var tween:= create_tween()
	tween.tween_property(fadeoverlay, "modulate:a", to_alpha, 1.5)
	await tween.finished

func show_run_results(time: float, level_reached: int, apples: int, best_level: int, best_time: float) -> void:
	run_results.visible = true
	title.text = "RUN OVER"
	var minutes: int = int(time / 60.0)
	var seconds := int(time) % 60
	time_label.text = "TIME: %02d:%02d" % [minutes, seconds]
	level_label.text = "LEVEL REACHED: %d" % level_reached
	apples_label.text = "APPLES: %d" % apples
	best_level_label.text = "BEST LEVEL: %d" % best_level
	var best_minutes: int = int(best_time / 60.0)
	var best_seconds: int = int(best_time) % 60
	best_time_label.text = "BEST TIME: %02d:%02d" % [best_minutes, best_seconds]
	restart_label.text = "PRESS SPACE TO TRY AGAIN"

func hide_run_results() -> void:
	run_results.visible = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused

func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_menu.visible = false

func _on_quit_pressed() -> void:
	get_tree().paused = false #must upasue before chaging  scine
	pause_menu.visible = false
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
	PlayerStats.reset()

#-----------------------
# uh the combo stuff
#-----------------------
func show_combo(combo:int) -> void:
	combo_label.text = "COMBO x%d" % combo
	combo_label.visible = true

func hide_combo() -> void:
	combo_label.visible = false

func show_combo_popup(combo: int, world_position: Vector2) -> void:
	combo_label.text = "COMBO x%d" % combo
	combo_label.visible = true
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * world_position
	var start_position := screen_position + Vector2(-30, -50)
	combo_label.position = start_position
	combo_label.modulate.a = 1.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(combo_label, "position", start_position + Vector2(0, -40), 0.6)
	tween.tween_property(combo_label, "modulate:a", 0.0, 0.6)
	await tween.finished
	combo_label.visible = false
	combo_label.modulate.a = 1.0
#---------------------
#uogrades
#---------------------
func show_upgrade_popup(upgrade: String, world_position: Vector2) -> void:
	upgrade_label.text = upgrade
	upgrade_label.visible = true
	var screen_position: Vector2 = get_viewport().get_canvas_transform() * world_position
	var start_position: Vector2 = screen_position + Vector2(-50, -50)
	upgrade_label.position = start_position
	upgrade_label.modulate.a = 1.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(upgrade_label, "position", start_position + Vector2(0, -50), 2.0)
	tween.tween_property(upgrade_label, "modulate:a", 0.0, 2.0)
	await tween.finished
	upgrade_label.visible = false
	upgrade_label.modulate.a = 1.0
