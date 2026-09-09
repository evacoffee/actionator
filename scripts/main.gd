extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var scorelabel: Label = $scoreHUD/scorepanel/scorelabel

var level: int = 1
var current_level_root: Node = null
var score: int = 0

var run_time: float = 0.0
var run_active: bool = true

var best_level: int = 1
var best_time: float = 0.0

const SAVE_PATH: String = "user://highscore.save"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_level_root = get_node("levelroot")
	load_high_score()
	_load_level(level)

func load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		best_level = file.get_var()
		best_time = file.get_var()

func save_high_score() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(best_level)
	file.store_var(best_time)

#------------------------------
#level management
#------------------------------
func _load_level(level_number: int) -> void:
	if current_level_root: 
		current_level_root.queue_free()
	#change level
	var level_path = "res://scenes/levels/level_%s.tscn" % level_number
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "levelroot"
	_setup_level(current_level_root)


func _setup_level(level_root: Node) -> void:
	#connect player 
	var player = level_root.get_node("player1")
	$HUD.set_player(player)
	player.died.connect(_on_player_died)

	# connect apples
	var apples = level_root.get_node_or_null("apples")
	if apples:
		for apple in apples.get_children():
			apple.collected.connect(increase_apples)

	#connect exit
	var exit = level_root.get_node_or_null("exit")
	if exit:
		exit.body_entered.connect(_on_exit_body_entered)

#-------------------------------
#signal handlers
#-------------------------------
func _on_exit_body_entered(body: Node2D) -> void: 
	if body.name == "player1":
		level += 1
		call_deferred("_load_level", level)

func _on_player_died() -> void:
	run_active = false
	var new_best := false
	if level > best_level or (level == best_level and (best_time == 0.0 or run_time < best_time)):
		best_level = level
		best_time = run_time
		new_best = true
	save_high_score()
	await get_tree().create_timer(1.0).timeout
	if new_best:
		hud.new_best.visible = true
		await get_tree().create_timer(2.0).timeout
		hud.new_best.visible = false
	hud.show_run_results(run_time, level, score, best_level, best_time)
	await hud.fade(0.0)
	await wait_for_restart()
	hud.hide_run_results()
	level = 1
	score = 0
	scorelabel.text = "SCORE: 0"
	PlayerStats.reset()
	run_time = 0.0
	run_active = true
	hud.run_timer.text = "TIME: 00:00"
	_load_level(level)

func wait_for_restart() -> void:
	while true:
		if Input.is_action_just_pressed("attack"):
			return
		await get_tree().process_frame
#-------------------------------
#scroeee
#-------------------------------
func increase_apples() -> void: 
	score += 1
	scorelabel.text = "APPLES: " + str(score)
	if score % 5 == 0:
		var player = current_level_root.get_node("player1")
		player.heal(20)

func _process(delta: float) -> void:
	if run_active:
		run_time += delta
		var minutes: int = int(run_time / 60.0)
		var seconds := int(run_time) % 60
		hud.run_timer.text = "TIME: %02d:%02d" % [minutes, seconds]

#-------------------------------
#combos
#-------------------------------
func show_combo(combo: int, slime_position: Vector2) -> void:
	hud.show_combo_popup(combo, slime_position)

func show_upgrade(upgrade: String, world_position: Vector2) -> void:
	hud.show_upgrade_popup(upgrade, world_position)
