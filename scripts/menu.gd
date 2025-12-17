extends Control

# Uzel TextureButton, na který se načítají ikony
# POZOR: Zkontrolujte, že cesta $MailLabel/MailButton je ve vaší scéně správná!
@onready var color_rect: ColorRect = $ColorRect
@onready var mail_menu: Control = $MailMenu
@onready var menu: Control = $menu
@onready var mail_label: Label = $menu/MailLabel
@onready var mail_button: TextureButton = $menu/MailLabel/MailButton
@onready var exit: Button = $menu/Exit
@onready var comunication_label: Label = $menu/ComunicationLabel
@onready var comunication_button: TextureButton = $menu/ComunicationLabel/ComunicationButton
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var communications_menu: Control = $CommunicationsMenu
@onready var explorer_label: Label = $menu/ExplorerLabel
@onready var explorer_button: TextureButton = $menu/ExplorerLabel/ExplorerButton


# Konstanta pro cestu k adresáři
const MAIL_DIR = "user://DATA/MAILS/"
const mail_scene = "res://scenes/mail_menu.tscn"

# --- Ikony ---
# Ikona, když jsou nové e-maily (nepřečtené)
const ICON_NEW_MAIL = preload("res://assets/mail/mail-exclamation-svgrepo-com.svg")
# Ikona pro případ, že jsou všechny e-maily přečtené (nebo pro prázdnou schránku)
const ICON_NO_MAIL = preload("res://assets/mail/mail-alt-3-svgrepo-com.svg")
# Ikona pro stav hover, když je schránka prázdná nebo vše přečteno
const ICON_HOVER = preload("res://assets/mail/mail-open-alt-svgrepo-com.svg")
# Ikona pro stav hover, když je NEW MAIL aktivní
const ICON_HOVER_NEW = preload("res://assets/mail/mail-open-alt-1-svgrepo-com.svg")

# --- NOVÉ KONSTANTY A PROMĚNNÉ PRO STAV PŘEČTENÍ ---
# Adresa k souboru pro sledování přečtených e-mailů (přidáno z mail_placeholder.gd)
const READ_MAIL_FILE = "user://DATA/READ_MAILS.json"
var read_mail_status: Dictionary = {}

# Načte stav přečtených e-mailů ze souboru JSON
func _load_read_status() -> void:
	if FileAccess.file_exists(READ_MAIL_FILE):
		var file = FileAccess.open(READ_MAIL_FILE, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			if not content.is_empty():
				var result = JSON.parse_string(content)
				if result is Dictionary:
					read_mail_status = result
				# else: print("CHYBA: SOUBOR STAVU E-MAILŮ NENÍ PLATNÝ JSON DICTIONARY.")
			# else: print("SOUBOR STAVU E-MAILŮ JE PRAZDNÝ.")
	# else: print("SOUBOR STAVU E-MAILŮ NENALEZEN.")


# --- Funkce pro zjištění souborů a aktualizaci stavu ---

# Tato funkce se postará o zjištění existence e-mailů a aktualizaci ikon.
func _update_mail_state() -> void:
	# DŮLEŽITÁ KONTROLA NULL: ŘEŠÍ CHYBU 'null instance'
	if not is_instance_valid(mail_button):
		# Zobrazíme varování a ukončíme funkci, aby nedošlo k chybě
		print("CHYBA: Uzel 'MailButton' nebyl nalezen nebo inicializován!")
		return
		
	# 0. Načtení stavu přečtení
	_load_read_status()
	
	# 1. Zajištění adresáře (Godot 4)
	if not DirAccess.dir_exists_absolute(MAIL_DIR):
		var error = DirAccess.make_dir_recursive_absolute(MAIL_DIR)
		if error != OK:
			# Zpracování chyby
			print("CHYBA: Nepodařilo se vytvořit adresář pro poštu.")
			return

	# 2. Zjištění počtu souborů a nepřečtených souborů
	var file_count = 0
	var unread_mail_count = 0 
	var dir = DirAccess.open(MAIL_DIR)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Započítá jen soubory, ignoruje složky a skryté soubory
			if not dir.current_is_dir() and not file_name.begins_with("."):
				file_count += 1
				
				# KONTROLA, ZDA JE E-MAIL NEPŘEČTENÝ
				# read_mail_status má klíč=název souboru. Pokud se klíč nenajde, předpokládáme, že je NEpřečtený (false)
				var is_read = read_mail_status.get(file_name, false)
				if not is_read:
					unread_mail_count += 1
					
			file_name = dir.get_next()
		dir.list_dir_end()

	# 3. Nastavení ikon podle stavu
	if unread_mail_count > 0:
		# Máme nepřečtené e-maily (chceme ikonu s vykřičníkem)
		mail_button.texture_normal = ICON_NEW_MAIL
		mail_button.texture_hover = ICON_HOVER_NEW
		print("Stav: ", unread_mail_count, " nepřečtených e-mailů.")
	elif file_count > 0 and unread_mail_count == 0:
		# Máme e-maily, ale VŠECHNY JSOU PŘEČTENÉ (použijeme standardní, ne-varovnou ikonu)
		mail_button.texture_normal = ICON_NO_MAIL
		mail_button.texture_hover = ICON_HOVER 

		print("Stav: Schránka obsahuje ", file_count, " přečtených e-mailů.")
	else:
		# Schránka je prázdná (file_count je 0)
		mail_button.texture_normal = ICON_NO_MAIL
		mail_button.texture_hover = ICON_HOVER 
		print("Stav: Schránka je prázdná.")
		


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_mail_state()


func _process(_delta: float) -> void:
	# Volitelné: Můžeš tuto funkci volat periodicky, pokud se e-maily objevují za běhu hry.
	# Nebo lépe: Volej _update_mail_state() z jiného skriptu, když víš, že přišel nový e-mail.
	pass

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("esc"):
		if mail_menu.visible:
			if $MailMenu/MailReader.visible:
				mail_menu._go_to_main_view()
			else:
				mail_menu.hide()
				menu.show()
		elif communications_menu.visible:
			communications_menu.hide()
			menu.show()
		else:
			get_tree().quit()





func _on_mail_button_pressed() -> void:
	# Před přepnutím scény se ujisti, že se stav aktualizuje, pokud dojde ke změně.
	# Toto není nutné, ale je to dobrý zvyk.
	_update_mail_state() 
	print("mail menu show")
	mail_menu.show()
	menu.hide()
	


func _on_exit_button_up() -> void:
	get_tree().quit()


func _on_comunication_button_pressed() -> void:
	communications_menu.show()
	menu.hide()


func _on_explorer_button_pressed() -> void:
	pass # Replace with function body.
