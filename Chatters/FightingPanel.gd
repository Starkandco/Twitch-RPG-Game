extends BasePanel

signal fight_started
signal fight_over

var players
var enemy
var fight_list
var default_misc = "Item <Name>\nDefend\nRun"
@onready var container = $MarginContainer/HBoxContainer
@onready var stats = $MarginContainer/HBoxContainer/Stats
@onready var debuffs = $MarginContainer/HBoxContainer/Debuffs

func fight_loop():
	while visible:
		players = get_parent().get_parent().get_parent().get_node("GameScene/Players").get_children()
		for player in players:
			update_UI(player)
			player._await_attack(enemy)
			await player.turn_over
			if enemy.health <= 0:
				enemy_dead()
				return
		if is_instance_valid(enemy):
			update_UI(enemy)
			enemy.decide(players)
			await enemy.turn_over

func update_UI(entity):
	var attacks = container.get_node("Attacks")
	var magic = container.get_node("Magic")
	var misc = container.get_node("Misc")
	var experience = stats.get_node("Experience")
	var health = stats.get_node("Health")
	var mana = stats.get_node("Mana")
	var bleed = debuffs.get_node("HBoxContainer/BleedCounter")
	var burn = debuffs.get_node("HBoxContainer2/BurnCounter")
	if entity is Player:
		debuffs.visible = false
		attacks.visible = true
		container.get_node("Magic").visible = true
		container.get_node("Misc").visible = true
		attacks.text = ""
		magic.text = ""
		for skillset in entity.skills:
			for skill in entity.skills[skillset]:
				match skillset:
					"Attacks":
						attacks.text += skill + "\n"
					"Magic":
						magic.text += skill + (" (5)" if skill == "Fire" else (" (3)" if skill == "Ice" else " (4)")) + "\n"
		misc.text = default_misc
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
	mana.max_value = entity.max_mana
	mana.value = entity.mana
	health.max_value = entity.max_health
	health.value = entity.health

func start_fight(entity):
	enemy = entity
	visible = true
	fight_started.emit()
	fight_loop()

func enemy_dead():
	visible = false
	fight_over.emit()
