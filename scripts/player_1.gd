extends CharacterBody2D

signal health_changed(new_health: int)
signal died
signal stamina_changed(new_stamina: float)

var SPEED: float = 300.0

var MAX_STAMINA: float = 100
const STAMINA_REGEN: float = 15
var stamina: float = MAX_STAMINA

const DASH_SPEED: float = 550
const DASH_TIME: float = 0.15
var DASH_COST: float = 30
var dash_discount: float = 0
const DASH_COOLDOWN: float = 0.5
var is_dashing: bool = false
var dash_cooldown: float = 0
var is_flickering: bool = false

var combo: int = 0
var combo_timer: float = 0.0
const COMBO_TIME: float = 2.0

var is_charging: bool = false
var charge_time: float = 0.0
const CHARGE_TIME: float = 0.5

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2
var alive: bool = true
var max_health: int
var health: int
var strength: int = 20
var attack_bonus: int = 0
var damage_reduction: float = 0.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var take_damage_sound: AudioStreamPlayer2D = $TakeDamage
@onready var swing_sword_sound: AudioStreamPlayer2D = $SwingSword
@onready var hitbox: Area2D = $hitbox
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	health = PlayerStats.health
	max_health = PlayerStats.max_health
	attack_bonus = PlayerStats.attack_bonus
	damage_reduction = PlayerStats.damage_reduction
	dash_discount = PlayerStats.dash_discount
	SPEED = 300.0 + PlayerStats.speed_bonus
	hitbox_offset = hitbox.position
	stamina = MAX_STAMINA
	stamina_changed.emit(stamina)
	if camera:
		camera.enabled = true
		camera.make_current()

func _physics_process(delta: float) -> void:
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo = 0
	if dash_cooldown > 0:
		dash_cooldown -= delta
	#regen stamina
	if alive:
		regenerate_stamina(delta)
		if Input.is_action_just_pressed("dash") and not is_dashing:
			dash()
		if is_dashing:
			move_and_slide()
			return
		if Input.is_action_just_pressed("attack") and not is_attacking:
			is_charging = true
			charge_time = 0.0
		if is_charging:
			velocity = Vector2.ZERO
			charge_time += delta
			if Input.is_action_just_released("attack"):
				is_charging = false
				if charge_time >= CHARGE_TIME:
					charged_attack()
				else:
					attack()
				charge_time = 0.0
		#skip movement if attacking
		if is_attacking:
			velocity = Vector2.ZERO
			return
		process_movement()
		process_animation()
		move_and_slide()
#-----------------------
#stamina func
#-----------------------

func regenerate_stamina(delta: float) -> void:
	if stamina < MAX_STAMINA:
		stamina += STAMINA_REGEN * delta
		if stamina > MAX_STAMINA:
			stamina = MAX_STAMINA
		stamina_changed.emit(stamina)

func use_stamina(amount: float) -> bool:
	if stamina < amount:
		return false
	stamina -= amount
	stamina_changed.emit(stamina)
	return true

func restore_stamina(amount: float) -> void:
	stamina += amount
	if stamina > MAX_STAMINA:
		stamina = MAX_STAMINA
	stamina_changed.emit(stamina)

func dash() -> void:
	if dash_cooldown > 0:
		return
	if not use_stamina(DASH_COST - dash_discount):
		return
	var dash_direction := Input.get_vector("left", "right", "up", "down")
	# If the player isn't moving, dash in the direction they're facing
	if dash_direction == Vector2.ZERO:
		dash_direction = last_direction
	is_dashing = true
	dash_cooldown = DASH_COOLDOWN
	flicker_invincibility()
	velocity = dash_direction.normalized() * DASH_SPEED
	await get_tree().create_timer(DASH_TIME).timeout
	is_dashing = false

#-----------------------
#Mmovement and animation
#-----------------------

func process_movement() -> void:
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
		update_hitbox_offset()
	else: 
		velocity = Vector2.ZERO

func process_animation() -> void:
	if is_attacking:
		return
	if velocity != Vector2.ZERO: 
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)
	
func play_animation(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")
		

#----------------------------------------
#attacking
#----------------------------------------

func attack() -> void:
	is_attacking = true
	hitbox.monitoring = true
	swing_sword_sound.play()
	play_animation("attack", last_direction)

func charged_attack() -> void:
	if not use_stamina(50):
		is_attacking = false
		return
	is_attacking = true
	hitbox.monitoring = true
	strength = 40 + attack_bonus
	swing_sword_sound.play()
	play_animation("attack", last_direction)
	screen_shake()

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		hitbox.monitoring = false
		strength = 20 + attack_bonus


#-------------------------------------
# hitbox 
#-------------------------------------

func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	match last_direction: 
		Vector2.LEFT:
			hitbox.position = Vector2(-x, y)
		Vector2.RIGHT:
			hitbox.position = Vector2(x, y)
		Vector2.UP:
			hitbox.position = Vector2(y, -x)
		Vector2.DOWN:
			hitbox.position = Vector2(-y, x)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.name.begins_with("slime"):
		body.take_damage(strength, position)
		combo += 1
		combo_timer = COMBO_TIME
		if combo == 20:
			heal(20)
		elif combo == 10:
			stamina = MAX_STAMINA
			stamina_changed.emit(stamina)
		var main = get_tree().current_scene
		main.show_combo(combo, body.global_position)

func heal(amount:int) -> void:
	health += amount
	if health >= max_health:
		health = max_health	
	PlayerStats.health = health
	emit_signal("health_changed", health)


func take_damage(amount: int) -> void:
	if alive:
		if is_dashing:
			return
		if damage_cooldown.time_left > 0:
			return
		take_damage_sound.play()
		health -= amount
		PlayerStats.health = health
		emit_signal("health_changed", health)
		if health <= 0:
			die()
		#make player invincible for a short time
		damage_cooldown.start()


func die() -> void:
	animated_sprite_2d.play("dying")
	alive = false
	await animated_sprite_2d.animation_finished
	died.emit()

#--------------------------
#cameraa
#--------------------------
func screen_shake() -> void:
	var original_position := camera.position
	for i in range(8):
		var shake_offset = Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		camera.position = original_position + shake_offset
		await get_tree().create_timer(0.02).timeout
	camera.position = original_position
#-------------------------
#flickering bro
#-------------------------
func flicker_invincibility() -> void:
	if is_flickering:
		return
	is_flickering = true
	while is_dashing or damage_cooldown.time_left > 0:
		animated_sprite_2d.visible = false
		await get_tree().create_timer(0.05).timeout
		animated_sprite_2d.visible = true
		await get_tree().create_timer(0.05).timeout
	animated_sprite_2d.visible = true
	is_flickering = false
