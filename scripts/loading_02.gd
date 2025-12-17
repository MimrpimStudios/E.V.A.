extends Control

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer

const scene_next = "res://scenes/02_ip.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. '_delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)



func _on_video_stream_player_finished() -> void:
	get_tree().change_scene_to_file(scene_next)

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		_on_video_stream_player_finished()
