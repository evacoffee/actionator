extends AnimatedSprite2D

var speed: float = 80.0
var direction: int = 1

func _ready() -> void:
	play("idle")

func _process(delta: float) -> void:
	position.x += speed * direction * delta
	if position.x > 1114:
		direction = -1
		flip_h = true
	elif position.x < 170:
		direction = 1
		flip_h = false
