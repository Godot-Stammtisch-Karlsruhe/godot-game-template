extends Control

@export var credits: String

func _ready() -> void:
	
	
	var credit_button_scene = load("res://ui/screens/credit-screen/credit_element.tscn")
	
	var creds: Array[CreditEntry] = _dicts_to_entry(_read_credits())
	for c in creds:
		var b: CreditButton = credit_button_scene.instantiate()
		b.display_license.connect(display_license)
		b.set_credit(c)
		$VBoxContainer/ScrollContainer/VBoxContainer/VBoxContainer.add_child(b)
	$VBoxContainer/ScrollContainer.scroll_vertical = 0

func _on_return_pressed() -> void:
	queue_free()

func _read_credits() -> Array:
	var text = FileAccess.open(credits, FileAccess.READ).get_as_text()
	var content_as_dictionary: Array = JSON.parse_string(text)
	return content_as_dictionary


func _dicts_to_entry(array: Array) -> Array[CreditEntry]:
	var item_array: Array[CreditEntry] = []
	for dict in array:
		var item = CreditEntry.new()
		item.name = dict["name"]
		item.descriptor = dict["descriptor"] if dict.has("descriptor") else ""
		if dict.has("license"):
			item.license = dict["license"] if dict["license"] else ""
		elif dict.has("license_file"):
			item.license = FileAccess.open(dict["license_file"], FileAccess.READ).get_as_text()\
				if FileAccess.file_exists(dict["license_file"]) else ""
		else:
			item.license = ""
		item.url = dict["url"] if dict.has("url") else ""
		item_array.append(item)
	return item_array

func _on_detailed_g_credits_pressed() -> void:
	if not $VBoxContainer/ScrollContainer/Godot3PCredits.text:
		var copyright_info = Engine.get_copyright_info()
		var copyright_text = "Godot Engine Copyright Information:"
		for entry in copyright_info:
			copyright_text += "\n\n" + entry["name"] + ":\n"
			var parts = entry["parts"]
			for part in parts:
				copyright_text += "Files:\n"
				for file in part["files"]:
					copyright_text += "    " + file + "\n"
				for copyright_owner in part["copyright"]:
					copyright_text += "© " + copyright_owner + "\n"
				copyright_text += "License:" + part["license"] + "\n"
		# Append full license texts
		var license_texts = Engine.get_license_info()	
		copyright_text += "\n\n\n\nFull license texts:"
		for license in license_texts:
			copyright_text += "\n\n" + license + ":\n"
			copyright_text += license_texts[license]
			
		$VBoxContainer/ScrollContainer/Godot3PCredits.text = copyright_text
	
	$VBoxContainer/ScrollContainer/Godot3PCredits.visible = \
		not $VBoxContainer/ScrollContainer/Godot3PCredits.visible
	
	$VBoxContainer/ScrollContainer/VBoxContainer.visible = \
		not $VBoxContainer/ScrollContainer/VBoxContainer.visible
	
	if $VBoxContainer/ScrollContainer/Godot3PCredits.visible:
		$DetailedGCredits.text = "Return to Credits"
	else:
		$DetailedGCredits.text = "Show detailed Godot Credits"

func display_license(credit: CreditEntry) -> void:
	$LicenseText.visible = true
	$LicenseText/VBoxContainer/Label.text = credit.name
	$LicenseText/VBoxContainer/ScrollContainer/Label.text = credit.license

func _on_close_licence_text_pressed() -> void:
	$LicenseText.visible = false
