extends FileDialog

var in_use = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_path = OS.get_executable_path()
	mode_overrides_title = false
	

func load_image_dialog():
	clear_filters()
	add_filter("*.png, *.jpg", tr("image_file_prompt"))
	current_path = OS.get_executable_path()
	current_file = ""
	title = tr("load_image")
	set_file_mode(FileDialog.FILE_MODE_OPEN_FILE)
	use_native_dialog = true
	set_access(FileDialog.ACCESS_FILESYSTEM)

func import_song_dialog():
	clear_filters()
	add_filter("*.zip", "Zip File")
	current_path = OS.get_executable_path()
	current_file = ""
	title = tr("import_button")
	set_file_mode(FileDialog.FILE_MODE_OPEN_FILE)
	use_native_dialog = true
	set_access(FileDialog.ACCESS_FILESYSTEM)

func save_song_dialog(_name):
	clear_filters()
	add_filter("*.zip", "Zip File")
	current_path = OS.get_executable_path()
	current_file = _name + ".zip"
	title = tr("export_title")
	set_file_mode(FileDialog.FILE_MODE_SAVE_FILE)
	use_native_dialog = true
	set_access(FileDialog.ACCESS_FILESYSTEM)
