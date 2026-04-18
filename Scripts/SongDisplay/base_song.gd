extends Panel
class_name BaseSong


@export var wait_ready : bool = false
@export var song_folder : String

@onready var play_stop_button = $PlayStopButton
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#assert(not song_folder == "", "Invalid Song Folder") -- Enable for error throwing in editor
	if wait_ready:
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
	play_stop_button.pressed.connect(_play_song)
	pass


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
	print(files)
	
	if files.is_empty() or not files.has("Audio.ogg") or not files.has("Meta.json"): #NO SONG DATA
		push_error("NO SONG DATA")
		queue_free()
		return
	
	var meta_path = song_folder + "/Meta.json"
	var file = FileAccess.open(meta_path, FileAccess.READ)
	if not file:
		print("Error loading metadata file: ", FileAccess.get_open_error())
		return
	var bytes = file.get_buffer(file.get_length())
	var json_string = bytes.get_string_from_utf16()
	var json = JSON.new()
	var error = json.parse(json_string)
	var metadata
	if error == OK:
		metadata = json.data
		print(metadata)
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line()) #error print from godot documentation
		queue_free()
		return
	$SongName.text = metadata.songName
	$AuthorNames.text = "No Authors Set"
	#$BPM.text = tr("bpm") % metadata.tempo
	$BPM.text = "BPM: %d" % metadata.tempo
	for i in metadata.performedBy.size():
		match i:
			0:
				$AuthorNames.text = metadata.performedBy[i]
			_:
				$AuthorNames.text += ", %s" % metadata.performedBy[i]
