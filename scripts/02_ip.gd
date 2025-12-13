extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var line_edit: LineEdit = $ColorRect/LineEdit
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var button: Button = $AudioStreamPlayer/Button
@onready var label: Label = $AudioStreamPlayer/Label
@onready var reader: Panel = $Reader
@onready var rich_text_label: RichTextLabel = $Reader/RichTextLabel
@onready var label2: Label = $Reader/Label
@onready var back: Button = $Reader/Back

const scene_correct = "res://scenes/loading_03.tscn"
const scene_incorrect = "res://scenes/incorrect_03.tscn"
var content = "IP for old EVA: 192.168.0.1
IP for new EVA: 192.168.1.1"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reader.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Called every frame. '_delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_line_edit_text_submitted(new_text: String) -> void:
	print(str(line_edit.text))
	line_edit.hide()
	if line_edit.text == "192.168.1.1":
		print("correct")
		get_tree().change_scene_to_file(scene_correct)
	else:
		print("incorrect")
		get_tree().change_scene_to_file(scene_incorrect)


func _on_button_pressed() -> void:
	write_to_readme()
	rich_text_label.set_text(content)
	reader.show()
	line_edit.hide()
	button.hide()
	label.hide()

func write_to_readme():
	# 1. Definuj cestu a text
	var path = "user://README.TXT"
	var content = "IP for old EVA: 192.168.0.1
IP for new EVA: 192.168.1.1"
	# 2. Vytvoř nový objekt FileAccess
	var file = FileAccess.open(path, FileAccess.WRITE)
	# Zkontroluje, jestli se soubor otevřel správně
	if file == null:
		print("Chyba při otevírání souboru: ", FileAccess.get_open_error())
		return
	# 3. Zapiš obsah do souboru
	file.store_string(content)
	print("Text úspěšně zapsán do: ", path)
	# 4. Uzavři soubor
	file.close()

func _on_back_pressed() -> void:
	reader.hide()
	line_edit.show()
	button.show()
	label.show()
