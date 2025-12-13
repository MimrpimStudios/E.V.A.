extends Control

# Adresa k uložišti e-mailů
const MAIL_DIR = "user://DATA/MAILS/"
# Adresa k souboru pro sledování přečtených e-mailů
const READ_MAIL_FILE = "user://DATA/READ_MAILS.json"

# Cesty k ikonám - ZAJIŠTĚNO, ŽE VŠECHNY JSOU CESTY (STRINGY)
const ICON_UNREAD = "res://assets/mail/mail-exclamation-svgrepo-com.svg" # Předpokládaná výchozí/nepřečtená ikona
const ICON_READ = "res://assets/mail/mail-open-alt-svgrepo-com.svg" # Ikona pro přečtený e-mail

# Maximální délka předmětu e-mailu pro zobrazení v seznamu (včetně elipsy)
const MAX_SUBJECT_LENGTH = 20

# Referenční uzly z Godot scény - POUŽÍVÁME ZJEDNODUŠENÉ CESTY DLE VAŠEHO PŘÁNÍ
# Předpokládáme tuto hierarchii:
# MailMenu (skript)
# ├── ColorRect
# ├── Back
# ├── NoMailsLabel
# ├── Control (Rodič pro e-maily)
# │   └── MailPlaceholder (šablona e-mailu)
# └── MailReader (Čtečka)
@onready var mail_menu: Control = $"."
@onready var color_rect: ColorRect = $ColorRect
@onready var back: Button = $Back
@onready var no_mails_label: Label = $NoMailsLabel

# NOVÝ RODIČOVSKÝ KONTEJNER PRO DYNAMICKÉ PŘIDÁVÁNÍ E-MAILŮ (nahrazuje VBoxContainer)
@onready var mail_parent_node_for_items: Control = $Control

# UZLY SEZNAMU (Jsou potomky $Control)
@onready var mail_placeholder: Button = $Control/MailPlaceholder # Placeholder
@onready var placeholder_mail_name: Label = $Control/MailPlaceholder/MailName 
@onready var mail_button: Button = $Control/MailPlaceholder/MailButton

# Uzly čtečky (Jsou přímí potomci MailMenu)
@onready var mail_reader: Control = $MailReader
@onready var reader_mail_name: RichTextLabel = $MailReader/MailName 
@onready var mail_text: RichTextLabel = $MailReader/MailText
@onready var back_mail_list: Button = $MailReader/BackMailList


# Nastavíme rodičovský uzel pro přidávání dynamických e-mailů
var mail_parent_node: Node

# Datová struktura pro ukládání stavu přečtených e-mailů (klíč: název souboru, hodnota: true/false)
var read_mail_status: Dictionary = {}
# Seznam pro uchování referencí na dynamicky vytvořené e-maily pro snadnou správu viditelnosti
var dynamically_created_mails: Array[Button] = []

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
					# print("NAČTEN STAV PŘEČTENÝCH E-MAILŮ: ", read_mail_status) # Odkomentujte pro debug
				else:
					print("CHYBA: SOUBOR STAVU E-MAILŮ NENÍ PLATNÝ JSON DICTIONARY.")
			else:
				print("SOUBOR STAVU E-MAILŮ JE PRAZDNÝ, INICIALIZUJI NOVÝ STAV.")
	else:
		print("SOUBOR STAVU E-MAILŮ NENALEZEN, INICIALIZUJI NOVÝ STAV.")

# Uloží stav přečtených e-mailů do souboru JSON
func _save_read_status() -> void:
	var file = FileAccess.open(READ_MAIL_FILE, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(read_mail_status)
		file.store_string(json_string)
		file.close()
		# print("ULOŽEN STAV PŘEČTENÝCH E-MAILŮ: ", read_mail_status) # Odkomentujte pro debug
	else:
		print("CHYBA: NELZE OTEVŘÍT SOUBOR PRO ZÁPIS STAVU E-MAILŮ.")

# Aktualizuje ikonu e-mailu na základě stavu
# mail_node: Hlavní tlačítko (MailPlaceholder duplikát)
# is_read: True pro přečtený, False pro nepřečtený
func _update_mail_icon(mail_node: Button, is_read: bool) -> void:
	# Ikona se nastavuje na vnořeném tlačítku MailButton, které slouží jako kontejner pro ikonu
	var icon_button: Button = mail_node.get_node_or_null("MailButton")
	if icon_button:
		var icon_path: String
		
		if is_read:
			icon_path = ICON_READ
		else:
			icon_path = ICON_UNREAD
			
		# Načítáme Texture2D z cesty (String)
		var texture = load(icon_path)
		if texture:
			icon_button.icon = texture
		else:
			print("CHYBA: NELZE NAČÍST IKONU: ", icon_path)
	else:
		print("VAROVÁNÍ: UZEL MailButton NENALEZEN V DUPLIKÁTU ", mail_node.name)


# Funkce volaná při prvním vstupu uzlu do scény
func _ready() -> void:
	# Nastavíme rodičovský uzel na $Control
	mail_parent_node = mail_parent_node_for_items 
	
	# KONSTANTY PRO ROZESTUP POZICE
	const INITIAL_Y_POSITION: float = 76.0 # Počáteční pozice prvního e-mailu
	const MAIL_SPACING: float = 100.0       # Rozestup mezi e-maily (102 - 76 = 26)

	# 0. Načteme stav přečtených e-mailů
	_load_read_status()
	
	# 1. Skryjeme původní uzel (šablonu) a label
	mail_placeholder.hide()
	no_mails_label.hide()
	
	# 2. Skryjeme čtečku e-mailů na začátku
	mail_reader.hide()
	
	# 3. Připojení signálu tlačítka Zpět k funkci pro přepnutí pohledu
	back_mail_list.pressed.connect(_go_to_main_view)
	
	# POZNÁMKA: Abyste mohli číst soubory, musíte se ujistit, že složka 'user://DATA/MAILS/' existuje.
	var dir = DirAccess.open(MAIL_DIR)
	var file_count = 0
	
	if dir:
		# Získání seznamu souborů
		var file_names = []
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Započítá jen soubory, ignoruje složky a skryté soubory
			if not dir.current_is_dir() and not file_name.begins_with("."):
				file_names.append(file_name)
				file_count += 1
			file_name = dir.get_next()
		dir.list_dir_end()
		
		print("NALEZENO SOUBORŮ: " + str(file_count))
		
		if file_count == 0:
			no_mails_label.show()
			_hide_dynamically_created_mails() # Skryjeme případné dříve vytvořené e-maily
		else:
			# Iterace přes nalezené soubory pro vytvoření uzlů
			for i in file_names.size():
				var full_mail_name = file_names[i] # Ukládáme celé jméno souboru jako klíč
				
				# 1. Duplikování uzlu
				var new_mail = mail_placeholder.duplicate() as Button
				
				# 2. Nastavení unikátního jména pro duplikát
				new_mail.name = "mail_" + str(i)
				
				# 3. Aktualizace textu a připojení akce - ZÍSKÁVÁME UZLY Z DUPLIKÁTU
				var new_mail_name_label: Label = new_mail.get_node("MailName")
				var new_mail_button: Button = new_mail.get_node("MailButton")
				
				if new_mail_name_label:
					# Převedení textu na velká písmena
					var mail_subject = full_mail_name.trim_suffix(".txt").to_upper()
					
					# RUČNÍ ZKRÁCENÍ TEXTU, ABY NEUTÍKAL:
					if mail_subject.length() > MAX_SUBJECT_LENGTH:
						mail_subject = mail_subject.left(MAX_SUBJECT_LENGTH) + "..."
						
					new_mail_name_label.text = mail_subject
					
					# Zjištění stavu přečtení a nastavení ikony
					var is_read = read_mail_status.get(full_mail_name, false)
					_update_mail_icon(new_mail, is_read) 
					
					# Nastavení metadat pro snadnou aktualizaci ikony později
					new_mail.set_meta("mail_file_name", full_mail_name)
					
					# Připojení signálu k hlavnímu tlačítku (MailPlaceholder)
					# BIND musíme provést až po nastavení metadat
					new_mail.pressed.connect(_go_to_reader.bind(full_mail_name))
					
					# Připojení signálu pressed i k vnořenému MailButton
					if new_mail_button:
						new_mail_button.pressed.connect(_go_to_reader.bind(full_mail_name))

				
				# 4. Přidání duplikátu do rodičovského uzlu ($Control) a zviditelnění
				mail_parent_node.add_child(new_mail)
				
				# 5. Nastavení pozice: Vypočítáme pozici Y na základě indexu a rozestupu
				new_mail.position.y = INITIAL_Y_POSITION + (i * MAIL_SPACING)
				
				new_mail.show()
				
				# Uložit referenci do seznamu pro snadnou správu viditelnosti
				dynamically_created_mails.append(new_mail)
				
				# Volitelné: Kontrolní výpis do konzole
				# print("VYTVOŘEN UZEL: ", new_mail.name, " S NÁZVY: ", full_mail_name, " NA POZICI Y:", new_mail.position.y) # Odkomentujte pro debug
	
	# Zabezpečení: Skrytí placeholderu po vytvoření seznamu
	mail_placeholder.hide()

# Helper pro skrytí dynamicky vytvořených e-mailů
func _hide_dynamically_created_mails():
	for mail_node in dynamically_created_mails:
		mail_node.hide()

# Helper pro zobrazení dynamicky vytvořených e-mailů
func _show_dynamically_created_mails():
	for mail_node in dynamically_created_mails:
		mail_node.show()

# Skryje prvky seznamu e-mailů (hlavní pohled)
func _hide_main_view_elements():
	no_mails_label.hide()
	_hide_dynamically_created_mails() # Skrýváme jednotlivé e-mailové položky

# Zobrazí prvky seznamu e-mailů (hlavní pohled)
func _show_main_view_elements():
	# Zkontrolujeme, zda se má zobrazit NoMailsLabel nebo dynamické e-maily
	if dynamically_created_mails.is_empty():
		no_mails_label.show()
		_hide_dynamically_created_mails()
	else:
		_show_dynamically_created_mails()
		no_mails_label.hide()

# Přejde do pohledu čtečky (Zprávy) a načte obsah
func _go_to_reader(mail_file_name: String) -> void:
	# 1. Skrýt hlavní pohled
	_hide_main_view_elements()
	
	# 2. Označení e-mailu jako přečteného, pokud ještě není
	# Aktualizujeme status, ale NEVOLÁME hned _save_read_status(). To by mohlo zpomalit.
	# Ukládání proběhne až v dalším kroku.
	if not read_mail_status.get(mail_file_name, false):
		read_mail_status[mail_file_name] = true
		_save_read_status() # Uložíme hned, aby se status zachoval
		
	# 3. Načíst obsah e-mailu
	var file_path = MAIL_DIR + mail_file_name
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file:
		if file.get_length() > 0:
			# Používáme text z e-mailu
			mail_text.text = file.get_as_text().to_upper()
		else:
			mail_text.text = "E-MAIL JE PRAZDNY."
			
		file.close()
		
		# 4. Nastavit jméno (subject) - Používáme novou referenci: reader_mail_name
		reader_mail_name.text = mail_file_name.trim_suffix(".txt").to_upper()
		
		# 5. Zobrazit čtečku
		mail_reader.show()
	else:
		print("CHYBA: NEPOVEDLO SE NAČÍST SOUBOR: ", file_path)
		# Vrátit se na hlavní pohled, pokud se nepodařilo načíst
		_show_main_view_elements()

# Přejde zpět na hlavní pohled (seznam e-mailů)
func _go_to_main_view() -> void:
	# 1. Skrýt čtečku
	mail_reader.hide()
	
	# 2. Zobrazit hlavní pohled (seznam e-mailů)
	_show_main_view_elements()
	
	# 3. Aktualizace ikon v seznamu
	_load_read_status() # Zajišťujeme, že načteme nejaktuálnější stav z disku
	for mail_node in dynamically_created_mails:
		var file_name = mail_node.get_meta("mail_file_name")
		if file_name:
			# Zjištění stavu přečtení z aktuálně načteného slovníku
			var is_read = read_mail_status.get(file_name, false)
			# Vizuální aktualizace uzlu
			_update_mail_icon(mail_node, is_read)
		else:
			print("VAROVÁNÍ: Uzel ", mail_node.name, " postrádá metadata 'mail_file_name'.")


func _on_back_pressed() -> void:
	#get_tree().change_scene_to_file("res://scenes/menu.tscn")
	mail_menu.hide()
	$"../menu".show()
