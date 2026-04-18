extends AcceptDialog

var in_use = false
var text_label : Label

var cancel_button : Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func failed_delete_prompt(_name,path,error):
	if cancel_button:
		remove_button(cancel_button)
		cancel_button = null
	ok_button_text = tr("popup_ok")
	dialog_text = tr("popup_delete_song_failed") % [_name, error]

func delete_prompt(_amount : int):
	ok_button_text = tr("popup_confirm")
	if not cancel_button:
		cancel_button = add_cancel_button(tr("popup_cancel"))
	else:
		cancel_button.text = tr("popup_cancel")
	title = tr("popup_warning")
	dialog_text = tr("popup_delete_song") % _amount
