extends Node

const SCENE_LOADING = "res://scenes/loading_01.tscn"
const SCENE_MENU = "res://scenes/menu.tscn"

const SAVE_FILE_PATH = "user://DATA/SAVE/SAVE01.DAT"
const SAVE_DIRECTORY = "user://DATA/SAVE" # Nová konstanta pro cestu ke složce

func _process(_delta: float) -> void:
	pass
func write_to_mail():
	# 1. Definuj cestu a text
	var content = "DOBRY DEN

Vzhledem k vasi hodnosti a dosavadnim zasluham Vam posilame nejnovejsi vyvojovou verzi Electronic Video Agent (E.V.A.). Pokud mate jakekoliv dotazy, obratte se na nejblizsiho technika nebo na vyvojare (Martin Kudlacek mimrpim@gmail.com)

S pozdravem
Global Defense Initiative (GDI) velitelstvi ARK"
	var path = "user://DATA/MAILS/E.V.A. UPDATE.TXT"
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

func ready_run():
	# 1. Kontrola existence souboru
	var file_check = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	
	if file_check == null:
		# Soubor NEEXISTUJE (stejný stav jako předtím)
		print("Ukládací soubor nenalezen. Vytvářím nový...")

		# --- NOVÝ KROK: Vytvoření potřebných adresářů ---
		var dir = DirAccess.open(SAVE_DIRECTORY)
		if dir == null:
			# Složka neexistuje, je nutné ji vytvořit
			var dir_access = DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)
			
			if dir_access != OK:
				# Kritická chyba: Selhalo vytvoření složky!
				printerr("KRITICKÁ CHYBA: Nelze vytvořit adresář: " + SAVE_DIRECTORY + " Error code: " + str(dir_access))
				# Zde byste měl zvážit ukončení hry nebo jinou obsluhu chyby
				get_tree().change_scene_to_file(SCENE_LOADING) # Prozatímní nouzové načtení
				return
			else:
				print("Adresář vytvořen: " + SAVE_DIRECTORY)
		
		# 2. Vytvoření souboru (Nyní by mělo být úspěšné)
		var new_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		
		if new_file != null:
			# Soubor byl úspěšně vytvořen
			new_file.store_string("Default Save Data\n")
			new_file.close()
			print("Ukládací soubor byl vytvořen: " + SAVE_FILE_PATH)
			
			# 3. Načtení scény pro první spuštění
			write_to_mail()
			get_tree().change_scene_to_file(SCENE_LOADING)
		else:
			# Chyba při vytváření souboru (I po vytvoření složky, což je vzácné)
			printerr("CHYBA: Selhalo vytvoření souboru i po vytvoření složky: " + SAVE_FILE_PATH)
			get_tree().change_scene_to_file(SCENE_LOADING) 
			
	else:
		# Soubor EXISTUJE
		file_check.close()
		print("Ukládací soubor nalezen. Načítám menu...")
		
		# 4. Načtení scény Menu
		get_tree().change_scene_to_file(SCENE_MENU)


func _on_timer_timeout() -> void:
	ready_run()
