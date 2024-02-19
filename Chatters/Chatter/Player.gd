extends CharacterBody2D

class_name Player

@export var projectile_scene: PackedScene

@onready var inventory = get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/Inventory")
@onready var fight_UI = get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/FightingPanel")

@export var movement_speed = 300
@onready var speed = movement_speed

var user
var is_leader

var level = 1
var experience = 0
var next_level = 50

var strength = 10
var defense = 5
var base_defense = 5
var magic = 3
var mana
var max_mana = 5
var dodge = 10
var health
var max_health = 50

var potions = 1
var elixirs = 1

var colour = "8f563b"
var UI_a = "VIOLET"
var UI_b = "YELLOW"
var UI_c = "CADET_BLUE"
var UI_d = "DARK_RED"

var stopped = false
var interacting_unit

var combat = false
var current_target
var skills = {"Attacks": ["Slice", "Shove"], "Magic": []}

var levelup_skills = {3: ["Attacks", "Impale"], 4: ["Magic", "Thunder"], 6: ["Magic", "Fire"], 8: ["Magic", "Ice"]}
var potential_skills = {}

signal interaction_started
signal turn_over
signal dead

func gain_skill(skill_info, replaced_skill):
	if potential_skills.has(skill_info):
		if skills[potential_skills[skill_info]].has(replaced_skill):
			skills[potential_skills[skill_info]].erase(replaced_skill)
			skills[potential_skills[skill_info]].append(skill_info)
			potential_skills.erase(skill_info)
			get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/MarginContainer/Label").update_label()

func dismiss_skill(skill_info):
	if potential_skills.has(skill_info):
		potential_skills.erase(skill_info)
		get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/MarginContainer/Label").update_label()

func _ready():
	fight_UI.fight_started.connect(_toggle_combat)
	fight_UI.fight_over.connect(_combat_over)
	turn_over.connect(_hide_name)
	
	if is_leader:
		change_ui()
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false
		
	$Name.text = user
		
	_set_colour(colour)
	
	health = max_health
	mana = max_mana
	
	$AnimatedSprite2D2.animation_finished.connect($AnimatedSprite2D2.play.bind("default"))

func _process(_delta):
	if $TimerLabel.visible:
		$TimerLabel.text = str(round($Timer.time_left))

func _remove_skill(skill, type):
	skills[type].erase(skill)

func _gain_skill(skill, type):
	skills[type].append(skill)

func _set_colour(colour_hex):
	if Color(colour_hex) != Color() or colour_hex == "black" or colour_hex == "000000":
		colour = colour_hex
		$Name.modulate = Color(colour)
		$AnimatedSprite2D.material.set_shader_parameter("colour_to", Color(colour))
		$AnimatedSprite2D2.material.set_shader_parameter("colour_to", Color(colour))

func _combat_over(experience_value):
	experience += experience_value
	if experience >= next_level:
		experience -= next_level
		level += 1
		next_level = 50 * (level)
		max_health += 20
		max_mana += 5
		dodge += 2
		magic += 1
		strength += 2
		base_defense += 2
		health = max_health
		mana = max_mana
		if levelup_skills.has(level):
			if skills[levelup_skills[level][0]].size() < 3:
				skills[levelup_skills[level][0]].append(levelup_skills[level][1])
			else:
				potential_skills[levelup_skills[level][1]] = levelup_skills[level][0]
				get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/MarginContainer/Label").update_label()
	_toggle_combat()

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

func _gain_health(value):
	_change_of_health_label(value, Color.GREEN)
	health += value
	if health > max_health:
		health = max_health

func _gain_mana(value):
	_change_of_health_label(value, Color.DODGER_BLUE)
	mana += value
	if mana > max_mana:
		mana = max_mana
		
func _dodges():
	var dodged = randi() % 100 >= 100 - dodge
	if dodged:
		$AnimatedSprite2D2.play("miss")
	return dodged

func _take_damage(value, label_colour = Color.BLACK):
	if defense > base_defense:
		$AnimatedSprite2D2.play("defending")
	var damage = defense - value 
	damage = abs(damage) if damage < 0 else 0
	health -= damage 
	await _change_of_health_label(damage, label_colour)
	if health <= 0:
		die()

func die():
	dead.emit()
	if !is_leader:
		queue_free()

func _change_of_health_label(value, label_colour):
	var label = Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 32)
	label.modulate = Color(label_colour)
	label.global_position = global_position + Vector2((50 * randi_range(0,3)), -50)
	get_parent().get_parent().add_child(label)

	var tween = get_tree().create_tween().set_parallel(true)

	tween.tween_property(label, "global_position", global_position + Vector2(0, -100), 1.0).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(label, "modulate", Color(label.modulate.r, label.modulate.g, label.modulate.b, 0), 1.0)
	
	tween.chain().tween_callback(label.queue_free)
	await label.tree_exited
	return

func _physics_process(delta):
	velocity = speed * Vector2.RIGHT * delta
	var collision = move_and_collide(velocity)
	if collision:
		var collider = collision.get_collider()
		if collider is Collectable: 
			if collider is Potion:
				potions += 1
			elif collider is Elixir:
				elixirs += 1
			inventory.share_item(collider, user)

			collider.queue_free()

func _on_area_2d_body_entered(body):
	if body is Unit:
		create_tween().tween_callback(_stop).set_delay(0.33)
		body.interaction_finished.connect(_start)
		interacting_unit = body
		body.interact()
	elif body is Projectile:
		body.queue_free()

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
	"strength" : strength,
	"magic" : magic,
	"dodge" : dodge,
	"base_defense" : base_defense,
	"max_health" : max_health,
	"max_mana" : max_mana,
	"experience" : experience,
	"level" : level,
	"next_level" : next_level,
	"skills" : skills,
	"potions" : potions,
	"elixirs" : elixirs,
	"colour" : colour,
	"UI_a" : UI_a,
	"UI_b" : UI_b,
	"UI_c" : UI_c,
	"UI_d" : UI_d
	}
	return save_dict

func change_ui(new_a = UI_a, new_b = UI_b, new_c = UI_c, new_d = UI_d):
	UI_a = new_a
	UI_b = new_b
	UI_c = new_c
	UI_d = new_d
	if is_leader:
		get_parent().get_parent().get_parent().get_node("GameUI/DialoguePanel").change_colours(UI_a, UI_b, UI_c, UI_d)
		get_parent().get_parent().get_parent().get_node("GameUI/DialoguePanel/OptionPanel").change_colours(UI_a, UI_b, UI_c, UI_d)
		get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/FightingPanel").change_colours(UI_a, UI_b, UI_c, UI_d)
		get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/FightingPanel/MarginContainer/HBoxContainer/AttackPanel").change_colours(UI_a, UI_b, UI_c, UI_d)
		get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/FightingPanel/MarginContainer/HBoxContainer/MagicPanel").change_colours(UI_a, UI_b, UI_c, UI_d)
		get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/FightingPanel/MarginContainer/HBoxContainer/MiscPanel").change_colours(UI_a, UI_b, UI_c, UI_d)

func slice():
	if current_target and skills["Attacks"].has("Slice"):
		$AnimationPlayer.play("attack")
		var dodge_success = await current_target.dodges()
		if !dodge_success:
			current_target.take_physical_hit(strength * 0.9)
			current_target.take_bleed(1)
		current_target = null
		turn_over.emit()

func shove():
	if current_target and skills["Attacks"].has("Shove"):
		$AnimationPlayer.play("attack")
		var dodge_success = await current_target.dodges()
		if !dodge_success:
			current_target.take_physical_hit(strength * 1.1)
		current_target = null
		turn_over.emit()

func impale():
	if current_target and skills["Attacks"].has("Impale"):
		$AnimationPlayer.play("attack")
		var dodge_success = await current_target.dodges()
		if !dodge_success:
			current_target.take_physical_hit(strength * 0.5)
			current_target.take_bleed(3)
		current_target = null
		turn_over.emit()

func fire():
	if _can_use_magic(5) and current_target and skills["Magic"].has("Fire"):
		_projectile("Fire")
		_decrease_mana(5)
		current_target.take_magical_hit(magic * 0.7)
		current_target.take_burn(3)
		current_target = null
		turn_over.emit()


func ice():
	if _can_use_magic(3) and current_target and skills["Magic"].has("Ice"):
		_projectile("Ice")
		_decrease_mana(3)
		current_target.take_frostbite(int(magic / 2))
		current_target = null
		turn_over.emit()


func thunder():
	if _can_use_magic(4) and current_target and skills["Magic"].has("Thunder"):
		_decrease_mana(4)
		current_target.take_magical_hit(magic * 0.5)
		current_target.shocked = true
		turn_over.emit()

func defend():
	if current_target:
		current_target = null
		$AnimatedSprite2D2.play("defending")
		await $AnimatedSprite2D2.animation_finished
		defense *= 2
		turn_over.emit()

func item(item_used):
	match item_used.to_lower():
		"potion":
			if potions > 0:
				potions -= 1
				var value = int(max_health * 0.2)
				_gain_health(value)
				inventory.get_node("MarginContainer/GridContainer/Potions/Label2").text = str(potions)
		"elixir":
			if elixirs > 0:
				elixirs -= 1
				var value = int(max_mana * 0.2)
				_gain_mana(value)
				inventory.get_node("MarginContainer/GridContainer/Elixirs/Label2").text = str(elixirs)
	turn_over.emit()

func _can_use_magic(cost):
	return mana - cost >= 0

func _decrease_mana(value):
	mana -= value

func _on_timer_timeout():
	turn_over.emit()

func _projectile(type):
	var projectile = projectile_scene.instantiate()
	match type:
		"Fire":
			projectile.get_node("Sprite2D").texture = load("res://assets/fireball.png")
		"Ice":
			projectile.get_node("Sprite2D").texture = load("res://assets/frostbit.png")
	get_parent().get_parent().get_node("Other").add_child(projectile)
	projectile.global_position = $Marker2D.global_position
	pass
