extends HBoxContainer


var version = "0.1.2"

@export var username : String = ""
@onready var songs_container = %SongsContainer

#tabs buttons:
@onready var songs_tab_button = $TabsMainContainer/TabsContainer/SongsTabButton
#songs tab buttons:
@onready var reload_button = $TabContainer/SongsTab/VBoxContainer/PanelContainer/HBoxContainer/Reload_Button
@onready var export_button = $TabContainer/SongsTab/VBoxContainer/PanelContainer/HBoxContainer/Export_Button
@onready var import_button = $TabContainer/SongsTab/VBoxContainer/PanelContainer/HBoxContainer/Import_Button
@onready var delete_button = $TabContainer/SongsTab/VBoxContainer/PanelContainer/HBoxContainer/Delete_Button

var selected_folders : Array[String]
var songs_directory
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$TabsMainContainer/Version.text = "V" + version
	set_default_locale()
	if OS.has_environment("USERNAME"):
		username = OS.get_environment("USERNAME")
	elif OS.has_environment("USER"):
		username = OS.get_environment("USER")
	print(username)
	songs_directory = "C:/Users/%s/AppData/Local/Pagoda/Saved/ImportedSongs" % username
	load_imported_songs_list()
	reload_button.pressed.connect(load_imported_songs_list)
	export_button.pressed.connect(_save_selected_songs_prompt)
	import_button.pressed.connect(_import_songs_prompt)
	delete_button.pressed.connect(_delete_songs_prompt)
	update_translations()
	%SongsContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	%SongsContainer.size_flags_vertical = SIZE_EXPAND_FILL
	%SongsContainer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _delete_songs_prompt():
	if selected_folders.is_empty() or MainAcceptDialog.in_use:
		return
	MainAcceptDialog.canceled.connect(_delete_cancel)
	MainAcceptDialog.confirmed.connect(_delete_songs)
	MainAcceptDialog.in_use = true
	MainAcceptDialog.delete_prompt(selected_folders.size())
	MainAcceptDialog.popup_centered()

func _delete_songs():
	MainAcceptDialog.in_use = false
	MainAcceptDialog.canceled.disconnect(_delete_cancel)
	MainAcceptDialog.confirmed.disconnect(_delete_songs)
	for i in selected_folders:
		var err = OS.move_to_trash(i)
		if err != OK:
			MainAcceptDialog.failed_delete_prompt(i, err)
			MainAcceptDialog.popup_centered()
	load_imported_songs_list()

func _delete_cancel():
	MainAcceptDialog.in_use = false
	MainAcceptDialog.canceled.disconnect(_delete_cancel)
	MainAcceptDialog.confirmed.disconnect(_delete_songs)

func _import_songs_prompt():
	if MainFileDialog.in_use:
		return
	MainFileDialog.in_use = true
	MainFileDialog.canceled.connect(_import_cancel)
	MainFileDialog.file_selected.connect(_import_song)
	
	MainFileDialog.import_song_dialog()
	MainFileDialog.popup_centered()
	#MainFileDialog.show()

func _import_song(path):
	print("importing, location: ", path)
	MainFileDialog.in_use = false
	MainFileDialog.canceled.disconnect(_import_cancel)
	MainFileDialog.file_selected.disconnect(_import_song)
	if path.ends_with(".zip"):
		print("importing2")
		extract_all_from_zip(path, songs_directory)
	load_imported_songs_list()
		

func _import_cancel():
	MainFileDialog.canceled.disconnect(_import_cancel)
	MainFileDialog.file_selected.disconnect(_import_song)
	MainFileDialog.in_use = false

func _save_selected_songs_prompt():
	if selected_folders.is_empty() or MainFileDialog.in_use:
		return
	MainFileDialog.in_use = true
	var _name
	if selected_folders.size() > 1:
		_name = str(selected_folders.size()) + "_%s" % Time.get_unix_time_from_system()
	else:
		_name = selected_folders[0].replace(songs_directory + "/", "")
	MainFileDialog.canceled.connect(_save_cancel)
	MainFileDialog.file_selected.connect(_save_selected_songs)
	
	MainFileDialog.save_song_dialog(_name)
	MainFileDialog.popup_centered()
	#MainFileDialog.show()

func _save_selected_songs(path):
	MainFileDialog.canceled.disconnect(_save_cancel)
	MainFileDialog.file_selected.disconnect(_save_selected_songs)
	MainFileDialog.in_use = false
	print("salvando")
	var writer = ZIPPacker.new() #ZIP PACKER CODE WAS GOT FROM GODOT DOCS TY!!!
	var err = writer.open(path)
	if err != OK:
		print("Error saving songs: ", err)
		return
	for i in selected_folders:
		var files = DirAccess.get_files_at(i)
		var song_folder = i.replace(songs_directory + "/", "")
		print("Song Folder: ", song_folder)
		for v in files:
			writer.start_file(song_folder + "/" + v)
			writer.write_file(FileAccess.get_file_as_bytes(i + "/%s" % v))
			writer.close_file()
	writer.close()

func _save_cancel():
	MainFileDialog.canceled.disconnect(_save_cancel)
	MainFileDialog.file_selected.disconnect(_save_selected_songs)
	MainFileDialog.in_use = false


func _remove_all_loaded_songs():
	for i in songs_container.get_children():
		i.queue_free()

func load_imported_songs_list():
	MusicPlayer.stop()
	selected_folders = []
	reload_button.text = tr("reloading")
	_remove_all_loaded_songs()
	var _songs = DirAccess.get_directories_at(songs_directory)
	print(_songs)
	if _songs.is_empty():
		print("Empty Songs")
		return
	for i in _songs:
		var _new_song : BaseSong = preload("uid://dk4la8k31vvpq").instantiate()
		_new_song.song_folder = songs_directory + "/%s" % i
		songs_container.add_child(_new_song)
	reload_button.text = tr("reload_button")

func update_translations():
	$TabsMainContainer/TabsContainer/Title.text = tr("app_name")
	$TabContainer/TitleMainContainer/TitleContainerContainer/TitleMargin/TitleLabel.text = tr("imported_songs")
	songs_tab_button.text = tr("songs")
	reload_button.text = tr("reload_button")
	export_button.text = tr("export_button")
	import_button.text = tr("import_button")
	delete_button.text = tr("delete_button")


#EXTRACT CODE FROM GODOT DOCS:
# Extract all files from a ZIP archive, preserving the directories within.
# This acts like the "Extract all" functionality from most archive managers.
func extract_all_from_zip(zippath, destination):
	var reader = ZIPReader.new()
	reader.open(zippath)

	# Destination directory for the extracted files (this folder must exist before extraction).
	# Not all ZIP archives put everything in a single root folder,
	# which means several files/folders may be created in `root_dir` after extraction.
	var root_dir = DirAccess.open(destination)

	var files = reader.get_files()
	print("Files to import/unzip: ", files)
	for file_path in files:
		# If the current entry is a directory.
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		# Write file contents, creating folders automatically when needed.
		# Not all ZIP archives are strictly ordered, so we need to do this in case
		# the file entry comes before the folder entry.
		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)

func set_default_locale():
	var locale = OS.get_locale()
	if TranslationServer.get_loaded_locales().has(locale):
		TranslationServer.set_locale(locale)
	else:
		TranslationServer.set_locale("en")
		print("Language not found: ", locale)
	print("Locale set to ", TranslationServer.get_locale())
