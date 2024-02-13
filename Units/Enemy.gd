extends Unit

class_name Enemy

@onready var fight_UI = get_parent().get_parent().get_parent().get_node("GameUI/VBoxContainer/FightingPanel")

var count = 0
var bleed_count = 0
var burn_count = 0
var frostbite_count = 0

var strength = 20
var defense = 4
var magic = 0
var base_defense = 4
var mana = 1
var max_mana = 1
var dodge = 1
var health = 50
var max_health = 50
var possible_moves = ["attack", "defend"]
var shocked = false

signal turn_start
signal turn_over
signal reset_done

func _ready():
	fight_UI.fight_over.connect(end_fight)
	turn_start.connect(reset)
	dialogue_tree = {
	"text": "Prepare to go down!!",
	"options": [
		{
			"text": "En garde!",
			"callback": "start_fight"
		}	]	}

func handle_response(arg):
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

func call_dialogue_callback(callback_name):
	var new_callable = Callable(self, callback_name)
	if new_callable.is_valid():
		new_callable.call()
	else:
		show_huh()

func reset():
	defense = base_defense
	reset_done.emit()

func decide(players):
	turn_start.emit()
	turn_start_damage()
	await get_tree().create_timer(1).timeout
	if health > 0 and !shocked:
		var move = select_move()
		move.call(players)
	else:
		turn_over.emit()

func turn_start_damage():
	await get_tree().create_timer(0.5).timeout
	bleed()
	await get_tree().create_timer(0.5).timeout	
	burn()
	await get_tree().create_timer(0.5).timeout
	freeze()

func attack(players):
	$AnimationPlayer.play("attack")
	var player = players[randi() % players.size()]
	if !player._dodges():
		players[randi() % players.size()]._take_damage(strength) 
	turn_over.emit()

func defend(_players):
	defense *= 2
	turn_over.emit()

func dodges():
	return randi() % 100 >= 100 - dodge

func select_move():
	return Callable(self, possible_moves[randi() % possible_moves.size()])

func take_physical_hit(value):
	var damage = defense - value
	take_damage(abs(damage) if damage < 0 else 0)

func take_magical_hit(value, colour = Color.BLACK):
	take_damage(value, colour)

func take_damage(damage, colour = Color.BLACK):
	health -= damage
	
	var damage_label = generate_damage_label(damage, colour)
	damage_label.global_position = global_position + Vector2(0, (-50 * randi_range(1,5)))

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
