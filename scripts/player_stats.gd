extends Node

var health: int = 100
var max_health: int = 100
var attack_bonus: int = 0
var damage_reduction: float = 0.0
var dash_discount: float = 0.0
var speed_bonus: float = 0.0

func reset() -> void:
	health = 100
	max_health = 100
	attack_bonus = 0
	damage_reduction = 0.0
	dash_discount = 0.0
	speed_bonus = 0.0
