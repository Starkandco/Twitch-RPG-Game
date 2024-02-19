extends CharacterBody2D

class_name Projectile

const SPEED = 300.0

func _physics_process(_delta):
	velocity = Vector2.RIGHT * SPEED
	move_and_slide()
