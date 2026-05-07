extends Panel
class_name BaseSong


@export var wait_ready : bool = false
@export var song_folder : String

@onready var play_stop_button = $PlayStopButton

@onready var main_container = get_tree().get_first_node_in_group("MainContainer")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#assert(not song_folder == "", "Invalid Song Folder") -- Enable line for error throwing in editor
	if wait_ready: #if testing in editor as MainContainer is not an autoload, could be swapped to OS.has_feature("Engine") or something like that
		await(get_tree().create_timer(0.01).timeout)
	var parent = get_parent()
	if not parent is MarginContainer:
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_top", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_bottom", 4)
		margin.name = "SongMargin"
		parent.add_child(margin)
		reparent(margin)
	#song_folder = song_folder.replace("%username%", %MainContainer.username)
	_init_song_data()
	$Selected.disabled = false
	$Selected.toggled.connect(on_selected_toggle)
	$SongImg.pressed.connect(select_image_prompt)
	play_stop_button.pressed.connect(_play_song)
	pass

func select_image_prompt():
	if MainFileDialog.in_use:
		return
	MainFileDialog.in_use = true
	MainFileDialog.load_image_dialog()
	MainFileDialog.canceled.connect(cancel_select_image)
	MainFileDialog.file_selected.connect(select_image)
	MainFileDialog.popup_centered()

func select_image(path):
	MainFileDialog.in_use = false
	MainFileDialog.canceled.disconnect(cancel_select_image)
	MainFileDialog.file_selected.disconnect(select_image)
	var img = Image.load_from_file(path)
	if img:
		$SongImg.texture_normal = ImageTexture.create_from_image(img)
		img.save_jpg(song_folder + "/logo.jpg", 0.8)

func cancel_select_image():
	MainFileDialog.in_use = false
	MainFileDialog.canceled.disconnect(cancel_select_image)
	MainFileDialog.file_selected.disconnect(select_image)

func on_selected_toggle(toggled_on : bool):
	if toggled_on:
		main_container.selected_folders.push_back(song_folder)
	else:
		main_container.selected_folders.erase(song_folder)
	#print(main_container.selected_folders)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			$Selected.button_pressed = not $Selected.button_pressed #pass the click in the panel to the Selected checkbox


func _play_song():
	var song = song_folder + "/Audio.ogg"
	if MusicPlayer.load_song(song_folder + "/Audio.ogg", play_stop_button):
		play_stop_button.texture_normal = preload("uid://vedvvm5koxwd")


func _init_song_data():
	var files = DirAccess.get_files_at(song_folder) #returns array with Filen
	#print(files)
	
	if files.is_empty() or not files.has("Audio.ogg") or not files.has("Meta.json"): #NO SONG DATA
		push_error("NO SONG DATA")
		queue_free()
		return
	
	
	var meta_path = song_folder + "/Meta.json"
	var file = FileAccess.open(meta_path, FileAccess.READ)
	if not file:
		print("Error loading metadata file: ", FileAccess.get_open_error())
		queue_free()
		return
	var bytes = file.get_buffer(file.get_length())
	var json_string = main_container.get_json_string_with_utf_detection(bytes)
	
	if json_string == "":
		print("Error loading JSON file: File is empty or unsupported format")
		queue_free()
		return
	var json = JSON.new()
	var error = json.parse(json_string)
	var metadata
	if error == OK:
		metadata = json.data
		#print(metadata)
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line()) #error print from godot documentation
		queue_free()
		return
	$SongName.text = metadata.songName
	$AuthorNames.text = tr("authors_empty")
	#$BPM.text = tr("bpm") % metadata.tempo
	$BPM.text = "BPM: %d" % metadata.tempo
	for i in metadata.performedBy.size():
		match i:
			0:
				$AuthorNames.text = metadata.performedBy[i]
			_:
				$AuthorNames.text += ", %s" % metadata.performedBy[i]
	
	if files.has("logo.jpg"):
		var img = Image.load_from_file(song_folder + "/logo.jpg")
		var logo = ImageTexture.create_from_image(img)
		if logo:
			$SongImg.texture_normal = logo
	else:
		$SongImg.texture_normal = preload("uid://ci00mh2x8u1rk")
