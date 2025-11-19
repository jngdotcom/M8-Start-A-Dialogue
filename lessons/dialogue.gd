extends Control

var expressions := {
	"happy": preload ("res://assets/emotion_happy.png"),
	"regular": preload ("res://assets/emotion_regular.png"),
	"sad": preload ("res://assets/emotion_sad.png"),
}

var bodies := {
	"sophia": preload ("res://assets/sophia.png"),
	"pink": preload ("res://assets/pink.png")
}

## An array of dictionaries. Each dictionary has three properties:
## - expression: a [code]Texture[/code] containing an expression
## - text: a [code]String[/code] containing the text the character says
## - character: a [code]Texture[/code] representing the character
var dialogue_items: Array[Dictionary] = [
	{
		"expression": expressions["regular"],
		"text": "I've been learning about [/wave]fish",
		"character": bodies["sophia"],
		"choice": {
			"oh": 2,
			"cool!": 1
		}
	},
	{
		"expression": expressions["regular"],
		"text": "How has it been going?",
		"character": bodies["pink"],
		"choice": {
			"bad": 2,
			"good":1
		}
	},
	{
		"expression": expressions["sad"],
		"text": "... Well... it is a little bit [shake]complicated[/shake]!",
		"character": bodies["sophia"],
		"choice": {
			"have you thought aboutlear": 2,
			"maybe you should quit": 1
		}
	},
	{
		"expression": expressions["sad"],
		"text": "fish are evil",
		"character": bodies["pink"],
		"choice": {
			"idk..": 2,
			"thank you": 1
		}
	},
]
var current_item_index := 0

## UI element that shows the texts
@onready var rich_text_label: RichTextLabel = %RichTextLabel
## UI element that progresses to the next text

@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
## The character
@onready var body: TextureRect = %Body
## The Expression
@onready var expression: TextureRect = %Expression

@onready var action_buttons_v_box_container: VBoxContainer = %ActionButtonsVBoxContainer

func _ready() -> void:
	show_text(0)
	
func create_button(choices_data: Dictionary) -> void:
	for button in action_buttons_v_box_container.get_children():
		button.queue_free()
		
	for choice_text in choices_data:
		var button := Button.new()
		action_buttons_v_box_container.add_child(button)
		
		button.text = choice_text
		
		var target_line_idx: int = choices_data[choice_text]
		
		if target_line_idx == -1:
			button.pressed.connect(get_tree().quit)
		else: 
			button.pressed.connect(show_text.bind(target_line_idx))
			
		
			
## Draws the current text to the rich text element
func show_text(current_item_index: int) -> void:
	# We retrieve the current item from the array
	var current_item := dialogue_items[current_item_index]
	# from the item, we extract the properties.
	# We set the text to the rich text control
	# And we set the appropriate expression texture
	rich_text_label.text = current_item["text"]
	expression.texture = current_item["expression"]
	body.texture = current_item["character"]
	create_button(current_item["choice"])
	# We set the initial visible ratio to the text to 0, so we can change it in the tween
	rich_text_label.visible_ratio = 0.0
	# We create a tween that will draw the text
	var tween := create_tween()
	# A variable that holds the amount of time for the text to show, in seconds
	# We could write this directly in the tween call, but this is clearer.
	# We will also use this for deciding on the sound length
	var text_appearing_duration: float = current_item["text"].length() / 30.0
	# We show the text slowly
	tween.tween_property(rich_text_label, "visible_ratio", 1.0, text_appearing_duration)
	# We randomize the audio playback's start time to make it sound different
	# every time.
	# We obtain the last possible offset in the sound that we can start from
	var sound_max_offset := audio_stream_player.stream.get_length() - text_appearing_duration
	# We pick a random position on that length
	var sound_start_position := randf() * sound_max_offset
	# We start playing the sound
	audio_stream_player.play(sound_start_position)
	# We make sure the sound stops when the text finishes displaying
	tween.finished.connect(audio_stream_player.stop)

	# We animate the character sliding in.
	slide_in()


	for button: Button in action_buttons_v_box_container.get_children():
		button.disabled = true
	
	tween.finished.connect(func() -> void:
		for button: Button in action_buttons_v_box_container.get_children():
			button.disabled = false
)


## Animates the character when they start talking
func slide_in() -> void:
	var slide_tween := create_tween()
	slide_tween.set_ease(Tween.EASE_OUT)
	body.position.x = get_viewport_rect().size.x / 7
	slide_tween.tween_property(body, "position:x", 0, 0.3)
	body.modulate.a = 0
	slide_tween.parallel().tween_property(body, "modulate:a", 1, 0.2)
