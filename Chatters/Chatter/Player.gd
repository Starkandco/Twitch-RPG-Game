extends CharacterBody2D

class_name Player

@onready var inventory = get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/Inventory")
@onready var fight_UI = get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/FightingPanel")

@export var movement_speed = 300

@onready var speed = movement_speed
var colour = "8f563b"
var interacting_unit
var user
var stopped = false
var combat = false
var level = 1
var experience = 0
var next_level = 50
var strength = 10
var defense = 5
var base_defense = 5
var magic = 3
var mana = 20
var max_mana = 20
var dodge = 10
var health = 50
var max_health = 50
var potions = 1
var current_target
var skills = {"Attacks": ["Slice", "Shove", "Impale"], "Magic": ["Fire", "Ice", "Thunder"]}

var UI_a = Color.VIOLET
var UI_b = Color.YELLOW
var UI_c = Color.CADET_BLUE
var UI_d = Color.DARK_RED

signal interaction_started
signal turn_over

func _ready():
	fight_UI.fight_started.connect(_toggle_combat)
	fight_UI.fight_over.connect(_toggle_combat)
	inventory.load_potions(potions)
	turn_over.connect(_hide_name)
	_change_UI(UI_a, UI_b, UI_c, UI_d)
	$Name.text = user
	if name != "Player":
		$Camera2D.enabled = false
	else:
		$Camera2D.make_current()
	$AnimatedSprite2D.material.set_shader_parameter("colour_to", Color(colour))

func _process(delta):
	if $TimerLabel.visible:
		$TimerLabel.text = str(round($Timer.time_left))

func _set_colour(colour_hex):
	colour = colour_hex
	if Color(colour) != Color():
		$AnimatedSprite2D.material.set_shader_parameter("colour_to", Color(colour))

func _toggle_combat():
	combat = !combat

func _hide_name():
	$Name.visible = false
	$TimerLabel.visible = false

func _await_attack(target):
	current_target = target
	defense = base_defense
	$Name.visible = true
	$TimerLabel.visible = true
	$Timer.start()

func _dodges():
	return randi() % 100 >= 100 - dodge

func _take_damage(value):
	var damage = defense - value 
	damage = abs(damage) if damage < 0 else 0
	health -= damage 
	
	var damage_label = Label.new()
	damage_label.text = str(damage)
	damage_label.add_theme_font_size_override("font_size", 32)
	get_parent().get_parent().add_child(damage_label)
	damage_label.modulate = Color.BLACK
	damage_label.global_position = global_position + Vector2(0, -50)

	var tween = get_tree().create_tween().set_parallel(true)

	tween.tween_property(damage_label, "global_position", global_position + Vector2(0, -100), 1.0).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(damage_label, "modulate", Color(damage_label.modulate.r, damage_label.modulate.g, damage_label.modulate.b, 0), 1.0).set_delay(1)
	
	tween.chain().tween_callback(damage_label.queue_free)

func _physics_process(delta):
	velocity = speed * Vector2.RIGHT * delta
	var collision = move_and_collide(velocity)
	if collision:
		var collider = collision.get_collider()
		if collider is Collectable: 
			if collider is Potion:
				potions += 1
				inventory.gain_potion()
			collider.queue_free()

func _on_area_2d_body_entered(body):
	if body is Unit:
		create_tween().tween_callback(_stop).set_delay(0.33)
		body.interaction_finished.connect(_start)
		interacting_unit = body
		body.interact()

func _say(arg):
	if interacting_unit and !combat:
		if interacting_unit.has_method("handle_response"):
			interacting_unit.handle_response(arg)

func _stop():
	if !stopped:
		stopped = true
		interaction_started.emit()
		speed = 0

func _start():
	interacting_unit = null
	speed = movement_speed 
	stopped = false

func _return_dict_for_save():
	var save_dict = {
	"filename" : get_scene_file_path(),
	"user" : user,
	"attack" : strength,
	"defense" : defense,
	"health" : health,
	"max_health" : max_health,
	"experience" : experience,
	"level" : level,
	"skills" : skills,
	"potions" : potions,
	"colour" : colour,
	"UI_a" : UI_a,
	"UI_b" : UI_b,
	"UI_c" : UI_c,
	"UI_d" : UI_d
	}
	return save_dict

func _change_UI(new_a, new_b, new_c, new_d):
	UI_a = new_a
	UI_b = new_b
	UI_c = new_c
	UI_d = new_d
	get_parent().get_parent().get_parent().get_node("GameUI/DialoguePanel").change_colours(UI_a, UI_b, UI_c, UI_d)

func _update_colours(new_a, new_b, new_c, new_d):
	UI_a = new_a
	UI_b = new_b
	UI_c = new_c
	UI_d = new_d

func slice():
	if current_target and skills["Attacks"].has("Slice") and !current_target.dodges():
		$AnimationPlayer.play("attack")
		current_target.take_physical_hit(strength * 0.9)
		current_target.take_bleed(1)
		current_target = null
		turn_over.emit()

func shove():
	if current_target and skills["Attacks"].has("Shove") and !current_target.dodges():
		$AnimationPlayer.play("attack")
		current_target.take_physical_hit(strength * 1.1)
		current_target = null
		turn_over.emit()

func defend():
	if current_target:
		current_target = null
		defense *= 2
		turn_over.emit()

func impale():
	if current_target and skills["Attacks"].has("Impale") and !current_target.dodges():
		$AnimationPlayer.play("attack")
		current_target.take_physical_hit(strength * 0.5)
		current_target.take_bleed(3)
		current_target = null
		turn_over.emit()

func fire():
	if _can_use_magic(5) and current_target and skills["Magic"].has("Fire"):
		_decrease_mana(5)
		current_target.take_magical_hit(magic * 0.7)
		current_target.take_burn(3)
		current_target = null
		turn_over.emit()

func ice():
	if _can_use_magic(3) and current_target and skills["Magic"].has("Ice"):
		_decrease_mana(3)
		current_target.take_frostbite(5)
		current_target = null
		turn_over.emit()

func thunder():
	if _can_use_magic(4) and current_target and skills["Magic"].has("Thunder"):
		_decrease_mana(4)
		current_target.take_magical_hit(magic * 0.5)
		current_target.shocked = true
		turn_over.emit()

func _can_use_magic(cost):
	return mana - cost >= 0

func _decrease_mana(value):
	mana -= value

func _on_timer_timeout():
	turn_over.emit()
