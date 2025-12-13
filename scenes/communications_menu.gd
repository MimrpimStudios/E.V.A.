extends Control

@onready var communications_menu: Control = $"."
@onready var color_rect: ColorRect = $ColorRect
@onready var back: Button = $Back
@onready var comunication_label: Label = $ComunicationLabel
@onready var comunication_button: TextureButton = $ComunicationLabel/ComunicationButton
@onready var timer: Timer = $ComunicationLabel/Timer
@onready var timer_2: Timer = $Timer2
@onready var content: Control = $Content
@onready var video_stream_player: VideoStreamPlayer = $Content/VideoStreamPlayer

var count = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	content.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_pressed() -> void:
	communications_menu.hide()
	$"../menu".show()
	


func _on_timer_2_timeout() -> void:
	if count == 1:
		comunication_label.set_text("downloading...")
		timer_2.wait_time = 10
		timer_2.start()
		count = 2
		comunication_label.phase_satelite = 0
		comunication_label._on_timer_timeout()
	elif count == 2:
		comunication_label.set_text("indexing...")
		comunication_label.phase_satelite = 0
		comunication_label._on_timer_timeout()
		count = 3
		timer_2.wait_time = 3
		timer_2.start()
	elif count == 3:
		comunication_label.hide()
		content.show()
		video_stream_player.play()



func _on_comunication_button_pressed() -> void:
	timer.start()
	timer_2.start()
