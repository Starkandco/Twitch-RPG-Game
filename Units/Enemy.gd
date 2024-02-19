extends Unit

class_name Enemy

@onready var fight_UI = get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/FightingPanel")

var count = 0
var bleed_count = 0
var burn_count = 0
var frostbite_count = 0
var shocked = false

@export var strength = 20
@export var defense = 4
@export var magic = 0
@export var base_defense = 4
@export var mana = 1
@export var max_mana = 1
@export var dodge = 1
@export var health = 50
@export var max_health = 50
@export var experience = 25
@export var possible_moves = ["attack", "defend"]

signal turn_start
signal turn_over
signal dead
signal reset_done

func set_colour(colour):
	$AnimatedSprite2D2.material.set_shader_parameter("colour_to", Color(colour))

func _ready():
	turn_over.connect(end_turn)
	turn_start.connect(reset)
	$AnimatedSprite2D2.animation_finished.connect($AnimatedSprite2D2.play.bind("default"))
	dialogue_tree = {
	"text": "Prepare to go down!!",
	"options": [
		{
			"text": "En garde!",
			"callback": "start_fight"
		}	]	}

func handle_response(arg):
	if health > 0:
		huh = {
		"text": (".... this should be easy they can't write out simple commands" if count >= 5 else "wanna try again?"),
		"options": [
			{
				"text": "En garde!",
				"callback": "show_dialogue_tree_2"
			} 	]	} 
		
		match arg.to_upper():
			"EN GARDE!":
				dialogue_UI.on_option_selected("start_fight")
			var _default:
				count += 1
				dialogue_UI.on_option_selected("show_huh")
	else:
		huh = {
		"text": ("You can \"continue\" on now"),
		"options": [
			{
				"text": "Continue",
				"callback": "end_interaction"
			} 	]	}
		match arg.to_upper():
			"CONTINUE":
				dialogue_UI.on_option_selected("end_interaction")
			var _default:
				count += 1
				dialogue_UI.on_option_selected("show_huh")

func call_dialogue_callback(callback_name):
	var new_callable = Callable(self, callback_name)
	if new_callable.is_valid():
		new_callable.call()
	else:
		show_huh()

func reset():
	defense = base_defense
	reset_done.emit()

func end_turn():
	$TurnMarker.visible = false

func decide(players):
	turn_start.emit()
	$TurnMarker.visible = true
	await turn_start_damage()
	await get_tree().create_timer(1).timeout
	if health > 0 and !shocked:
		var move = select_move()
		move.call(players)
	else:
		if shocked:
			shocked = false
		turn_over.emit()

func turn_start_damage():
	if $AnimatedSprite2D2.animation != "default":
		await $AnimatedSprite2D2.animation_finished
	if bleed_count > 0 and health > 0:
		$AnimatedSprite2D2.play("bleeding")
		await $AnimatedSprite2D2.animation_finished
		bleed()
	if burn_count > 0 and health > 0:
		$AnimatedSprite2D2.play("burnt")
		await $AnimatedSprite2D2.animation_finished
		burn()
	if frostbite_count > 0 and health > 0:
		$AnimatedSprite2D2.play("frostbit")
		await $AnimatedSprite2D2.animation_finished
		freeze()
	return

func attack(players):
	$AnimationPlayer.play("attack")
	var player = players[randi() % players.size()]
	var dodge_success = await player._dodges()
	if !dodge_success:
		players[randi() % players.size()]._take_damage(strength) 
	await $AnimationPlayer.animation_finished
	turn_over.emit()

func defend(_players):
	$AnimatedSprite2D2.play("defending")
	await $AnimatedSprite2D2.animation_finished
	defense *= 2
	turn_over.emit()

func dodges():
	var dodged = randi() % 100 >= 100 - dodge
	if dodged:
		$AnimatedSprite2D2.play("miss")
	return dodged

func select_move():
	return Callable(self, possible_moves[randi() % possible_moves.size()])

func take_physical_hit(value):
	var damage = defense - value
	if defense > base_defense:
		$AnimatedSprite2D2.play("defending")
	take_damage(abs(damage) if damage < 0 else 0)

func take_magical_hit(value, colour = Color.BLACK):
	take_damage(value, colour)

func take_damage(damage, colour = Color.BLACK):
	health -= damage
	if health <= 0:
		end_fight()
	
	var damage_label = generate_damage_label(damage, colour)
	damage_label.global_position = global_position + Vector2((-50 * randi_range(0,3)), -50)

	var tween = get_tree().create_tween().set_parallel(true)

	tween.tween_property(damage_label, "global_position", global_position + Vector2(0, -100), 1.0).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(damage_label, "modulate", Color(damage_label.modulate.r, damage_label.modulate.g, damage_label.modulate.b, 0), 1.0).set_delay(1.5)
	
	tween.chain().tween_callback(damage_label.queue_free)

func generate_damage_label(value, colour):
	var damage_label = Label.new()
	damage_label.text = str(value)
	damage_label.add_theme_font_size_override("font_size", 32)
	get_parent().get_parent().add_child(damage_label)
	damage_label.modulate = colour
	return damage_label

func start_fight():
	fight_UI.start_fight(self)

func end_fight():
	dead.emit()
	visible = false

func end_interaction():
	fight_UI.end = false
	interaction_finished.emit()
	queue_free()

func take_bleed(value):
	bleed_count += value
	
func take_burn(value):
	burn_count += value
	
func take_frostbite(value):
	frostbite_count += value

func bleed():
	if bleed_count > 0:
		take_damage(bleed_count, Color.WEB_MAROON)
		bleed_count -= 1

func burn():
	if burn_count > 0:
		take_damage(burn_count, Color.ORANGE_RED)
		burn_count -= 1

func freeze():
	if frostbite_count > 0:
		take_damage(frostbite_count, Color.DODGER_BLUE)
		frostbite_count -= 1
