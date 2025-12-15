extends Label

@onready var comunication_button: TextureButton = $ComunicationButton
@onready var timer: Timer = $Timer

var phase_satelite = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_timer_timeout() -> void:
	if phase_satelite == 0:
		comunication_button.set_texture_normal(preload("uid://cowull0ush6fm"))
		phase_satelite += 1
	elif phase_satelite == 1:
		comunication_button.set_texture_normal(preload("uid://f1flsr5fumm6"))
		phase_satelite += 1
	elif phase_satelite == 2:
		comunication_button.set_texture_normal(preload("uid://dg8xulhreu54r"))
		phase_satelite += 1
	elif phase_satelite == 3:
		comunication_button.set_texture_normal(preload("uid://6cmkoenlfqnr"))
		phase_satelite = 0
	else:
		comunication_button.set_texture_normal(preload("uid://cowull0ush6fm"))
		phase_satelite = 0
	timer.start()


func _on_comunication_button_mouse_entered() -> void:
	timer.start()
	phase_satelite += 1
	_on_timer_timeout()
func _on_comunication_button_mouse_exited() -> void:
	timer.stop()
	comunication_button.set_texture_normal(preload("uid://cowull0ush6fm"))
	phase_satelite = 0
