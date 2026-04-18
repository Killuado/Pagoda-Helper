extends AudioStreamPlayer

var last_button
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _finished():
	print("oi")
	last_button.texture_normal = preload("uid://4av6wmow3713")
	last_button = null

func load_song(path, button):
	print(last_button)
	if last_button:
		if button == last_button:
			last_button.texture_normal = preload("uid://4av6wmow3713")
			last_button = null
			stop()
			return false
		else:
			last_button.texture_normal = preload("uid://4av6wmow3713")
	last_button = button
	var _stream = AudioStreamOggVorbis.load_from_file(path)
	if _stream is AudioStreamOggVorbis:
		set_stream(_stream)
		play()
		return true
	return false
