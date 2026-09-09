extends Area2D

var opened: bool = false
var upgrades = ["sharpened blade","healing potion","stamina crystal","swift boots", "berserker blade", "dash master", "iron skin"]

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var chestopensound: AudioStreamPlayer = $chestopensound
@onready var sparkles: GPUParticles2D = $sparkles

func _on_body_entered(body: Node2D) -> void:
	if opened:
		return
	if body.name == "player1":
		open_chest()

func open_chest() -> void:
	opened = true
	animated_sprite.play("open")
	chestopensound.play()
	sparkles.restart()
	var upgrade = upgrades.pick_random()
	var main = get_tree().current_scene
	main.show_upgrade(upgrade, global_position)
	give_upgrade(upgrade)

func give_upgrade(upgrade: String) -> void:
	var player = get_tree().get_first_node_in_group("player1")
	if player == null:
		return
	match upgrade:
		"berserker blade":
			player.attack_bonus += 40
			player.strength = 20 + player.attack_bonus
		"iron skin":
			PlayerStats.damage_reduction = 0.20
			player.damage_reduction = PlayerStats.damage_reduction
		"dash master":
			PlayerStats.dash_discount = 15
			player.dash_discount = PlayerStats.dash_discount
		"sharpened blade":
			PlayerStats.attack_bonus += 20
			player.attack_bonus = PlayerStats.attack_bonus
			player.strength = 20 + player.attack_bonus
		"healing potion":
			player.heal(40)
		"stamina crystal":
			player.MAX_STAMINA += 30
			player.stamina = player.MAX_STAMINA
			player.stamina_changed.emit(player.stamina)
		"swift boots":
			PlayerStats.speed_bonus += 40
			player.SPEED = 300.0 + PlayerStats.speed_bonus
