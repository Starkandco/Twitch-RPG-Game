extends BasePanel

signal fight_started
signal fight_over

var players
var enemy
var fight_list
var end = false
@onready var container = $MarginContainer/HBoxContainer
@onready var stats = $MarginContainer/HBoxContainer/Stats
@onready var debuffs = $MarginContainer/HBoxContainer/Debuffs
@onready var inventory = get_parent().get_node("Inventory")

var dialogue_tree = {}

func fight_loop():
	enemy.dead.connect(enemy_dead)
	while visible:
		players = get_parent().get_parent().get_parent().get_child(1).get_node("Players").get_children()
		for i in range(players.size()):
			if players[i].is_queued_for_deletion() or players[i] is Projectile:
				players.erase(i)
		for player in players:
			if end: break
			if !is_instance_valid(player): continue
			enemy.set_colour(player.colour)
			inventory.display_user(player)
			update_UI(player)
			player._await_attack(enemy)
			await player.turn_over
		if is_instance_valid(enemy):
			update_UI(enemy)
			enemy.decide(players)
			await enemy.turn_over

func update_UI(entity):
	var attacks = container.get_node("AttackPanel")
	var magic = container.get_node("MagicPanel")
	var misc = container.get_node("MiscPanel")
	var experience = stats.get_node("Experience")
	var health = stats.get_node("Health")
	var mana = stats.get_node("Mana")
	var bleed = debuffs.get_node("HBoxContainer/BleedCounter")
	var burn = debuffs.get_node("HBoxContainer2/BurnCounter")
	var frostbite = debuffs.get_node("HBoxContainer3/FrostbiteCounter")
	if entity is Player:
		debuffs.visible = false
		attacks.visible = true
		magic.visible = true
		misc.visible = true
		attacks.get_node("Attacks").text = ""
		magic.get_node("Magic").text = ""
		for skillset in entity.skills:
			for skill in entity.skills[skillset]:
				match skillset:
					"Attacks":
						attacks.get_node("Attacks").text += skill + "\n"
					"Magic":
						magic.get_node("Magic").text += skill + (" (5)" if skill == "Fire" else (" (3)" if skill == "Ice" else " (4)")) + "\n"
		experience.value = entity.experience
		experience.max_value = entity.next_level
		experience.visible = true
	else:
		attacks.visible = false
		magic.visible = false
		misc.visible = false
		experience.visible = false
		debuffs.visible = true
		bleed.text = str(entity.bleed_count)
		burn.text = str(entity.burn_count)
		frostbite.text = str(entity.frostbite_count)
	mana.max_value = entity.max_mana
	mana.value = entity.mana
	health.max_value = entity.max_health
	health.value = entity.health

func start_fight(entity):
	enemy = entity
	inventory.toggle_visibility()
	visible = true
	fight_started.emit()
	fight_loop()

func enemy_dead():
	end = true
	fight_over.emit(enemy.experience)
	enemy.dialogue_tree = {
	"text": "EXP: " +str(enemy.experience),
	"options": [
		{
			"text": "Continue",
			"callback": "end_interaction"
		}	]	}
	enemy.interact()
	visible = false
	inventory.toggle_visibility()
