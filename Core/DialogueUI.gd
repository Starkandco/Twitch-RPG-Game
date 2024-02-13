extends BasePanel

class_name DialogueManager

## Manages display for any in game text interactions with objects or characters.

## Ref to [Label] that is the container for any dialogue tetx 
@onready var dialogueText : Label = %DialogueText
## Ref to the [GridContainer] that holds any options necessary for the dialogue
@onready var optionsContainer : GridContainer = %OptionHolder
## Empty [Dictionary] to store the provided data for an interaction
var dialogueTree : Dictionary
## Empty ref for the calling object to callback to
var calling_object

## Calls the base panel stuff for the gradient shader and hides the panel
func _ready(): 
	super()
	hide() 

## Handles showing the panel, storing dialogue tree/calling object, and sets up the first text
func show_dialogue(object_that_called, dialogue_data : Dictionary):
	calling_object = object_that_called
	if dialogue_data == {}: 
		on_option_selected("end")
		return
	# Show the panel 
	show() 
	# Store the dialogue tree 
	dialogueTree = dialogue_data 
	# Set initial dialogue text 
	set_dialogue_text(dialogueTree["text"]) 
	# Generate option labels 
	generate_options_and_labels(dialogueTree["options"])

## Sets the text of the dialogue label
func set_dialogue_text(text : String): 
	# Set the text of the dialogue label 
	dialogueText.text = text 

## Calls the original objects method to handle the callbacks
func on_option_selected(callback_name : String): 
	# Hide the dialogue panel 
	hide()
	#Store the calling object and set it to null, so it can readd itself in call dialogue callback if necessary
	var temp = calling_object
	calling_object = null
	# Assuming the parent is the interactable object 
	temp.call_dialogue_callback(callback_name) 

## Clears any previous options and sets up buttons and labels for each new options
func generate_options_and_labels(options : Array): 
	# Clear existing option labels 
	for child in optionsContainer.get_children():
		child.queue_free()
		
	for option in options:
		# Create a new Button node
		var button = Button.new()
		optionsContainer.add_child(button)
		button.flat = true
		button.custom_minimum_size = Vector2(125, 30)
		button.pressed.connect(on_option_selected.bind(option["callback"])) 
		
		# Create a new Label node as a child of the Button node
		var label = Label.new()
		button.add_child(label)
		
		# Set the text of the Label node
		label.text = option["text"]
		
		# Apply the same shadow settings as the dialogueText Label
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_constant_override("shadow_outline_size", 2)

	var option_size = Vector2(125, 30)
	var margin = Vector2(15, 15)  # Margin size
	var container_min_size = option_size * Vector2(1, options.size()) + 2 * margin
	%OptionPanel.custom_minimum_size = container_min_size
