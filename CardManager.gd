extends Control

const CARD_POOL_DIR: String = "res://Card Pool/"
const EXPORT_DIR: String = "res://Output PNGs/"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var card_paths: Array[String] = dir_contents(CARD_POOL_DIR)
	
	for card_path: String in card_paths:
		await get_tree().change_scene_to_file(card_path)
		await get_tree().create_timer(0.2).timeout
		#await get_tree().root.ready
		var img: Image = get_viewport().get_texture().get_image()
		var export_path: String = EXPORT_DIR.path_join(card_path.get_file().replace(".tscn",".png"))
		print(export_path)
		img.save_png(export_path)
	
	get_tree().quit()

func dir_contents(path: String) ->  Array[String]:
	var dir: DirAccess = DirAccess.open(path)
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	var files: Array[String] = []
	while file_name != "":
		var file:= dir.get_current_dir().path_join(file_name)
		files.append(file)
		file_name = dir.get_next()
	
	return files

