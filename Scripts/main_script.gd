extends HBoxContainer

@export var username : String = ""
@onready var songs_container = %SongsContainer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_environment("USERNAME"):
		username = OS.get_environment("USERNAME")
	elif OS.has_environment("USER"):
		username = OS.get_environment("USER")
	print(username)
	load_imported_songs_list()





func _remove_all_loaded_songs():
	for i in songs_container.get_children():
		i.queue_free()

func load_imported_songs_list():
	_remove_all_loaded_songs()
	var songs_directory = "C:/Users/%s/AppData/Local/Pagoda/Saved/ImportedSongs" % username
	var _songs = DirAccess.get_directories_at(songs_directory)
	print(_songs)
	if _songs.is_empty():
		print("Empty Songs")
		return
	for i in _songs:
		var _new_song : BaseSong = preload("uid://dk4la8k31vvpq").instantiate()
		_new_song.song_folder = songs_directory + "/%s" % i
		songs_container.add_child(_new_song)
		
