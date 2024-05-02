@tool
extends Control
class_name Card

@export var perform_automatic_layout: bool:
	set(new_val):
		auto_lay_out()

static var dimensions: Vector2 = Vector2(600,1050)
static var bleed_width: float = 3 # 0 while drafting. WIll need to be 40 for print
static var border_width: float = 40

@export_enum("Mine", "RP", "Investigate", "Storage", "Housing", "Terra", "Energy", "Other") var card_type: String = "Other"
@export var cost: String = "1Fe 1Ti"
@export var card_name: String = "Default"
@export_multiline var body_text: String = "Default"

static var COLOR_MAP: Dictionary = {
	"Mine":         Color("#e67e22"),
	"RP":           Color("#2980b9"), #research points
	"Investigate":  Color("#2980b9"),
	"Storage":      Color("#95a5a6"),
	"Housing":      Color("#95a5a6"),
	"Terra":        Color("#27ae60"),
	"Energy":       Color("#f1c40f"),
	"Other":        Color("#e74c3c"),
}

const ICON_MAP: Dictionary = {
	"H2O": preload("res://Icons/Icons_Water.png"),
	"Fe": preload("res://Icons/Icons_Iron.png"),
	"Ti": preload("res://Icons/Icons_Titatnium.png"),
	"U": preload("res://Icons/Icons_Uranimum.png"),
	"Au": preload("res://Icons/Icons_Gold.png"),
	"RP" : preload("res://Icons/Icons_Data.png"),
	"Berra" : preload("res://Icons/Icons_Berra.png"),
	"Terra" : preload("res://Icons/Icons_Terra.png"),
}

func _ready() -> void:
	setup_card_shape()

func auto_lay_out() -> void:
	var card_title: Label = %"Card Title" as Label
	card_name = scene_file_path.get_basename().split("/")[-1].replace("card_","")
	card_title.text = card_name
	card_title.self_modulate = COLOR_MAP[card_type]
	
	setup_card_shape()
	setup_cost_bar()
	
	var terraform_label: Control = %"Terraform Label" as Control
	var terraform_body: Control = %"Terraform Body" as Control
	var terraform_v_box: Control = %"Terraform VBox" as Control

	var split_text: PackedStringArray = body_text.split("-TF-")
	var has_terraform_text: bool = split_text.size() > 1
	if has_terraform_text:
		terraform_label.visible = true
		terraform_body.visible = true

		await setup_body(split_text[0],body_v_box)
		await setup_body(split_text[1],terraform_v_box)
	else:
		terraform_label.visible = false
		terraform_body.visible = false
		await setup_body(body_text,body_v_box)
		await setup_body("",terraform_v_box)
	
	%"Main Body".self_modulate = COLOR_MAP[card_type]
	
	if Engine.is_editor_hint(): #if we're in the editor make sure all of our changes we make to the prefabs stick
		for c in get_all_children(%Bleed):
			c.scene_file_path = ""
			c.owner = get_tree().edited_scene_root
		queue_redraw()

func get_all_children(in_node: Node, arr: Array[Node]=[]) -> Array[Node]:
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child,arr)
	return arr

@onready var body_v_box: VBoxContainer = %"Body VBox"
const SPACER_PREFAB: PackedScene = preload("uid://ofksefnmwjxu")

func setup_body(text: String, parent: Node) -> void:
	for c: Node in parent.get_children():
		if c.is_in_group("Do Not Delete"): continue
		c.queue_free()
	
	await  get_tree().process_frame #wait to make sure the old ones are deleted first. This keeps naming errors from popping up
	
	if not parent.get_node_or_null("Card Cost Spacer"): #if there's no spacer at the beginning, put one there
			parent.add_child(SPACER_PREFAB.instantiate())
	else:
		if not parent.get_node_or_null("Card Cost Spacer").visible:
			parent.add_child(SPACER_PREFAB.instantiate())
	
	for line in text.split("\n"):
		line = line.strip_edges()
		if line == "": continue #skip empty lines
		
		if line.begins_with("RPT:"):
			parent.add_child(setup_repeating_effect(line.right(-4)))
			parent.add_child(SPACER_PREFAB.instantiate())
		elif line.begins_with("D:"):
			parent.add_child(setup_data_storage(line.to_int()))
			parent.add_child(SPACER_PREFAB.instantiate())
		elif line.begins_with("C:"):
			parent.add_child(setup_colonist_storage(line.to_int()))
			parent.add_child(SPACER_PREFAB.instantiate())
		elif line.begins_with("M:"):
			parent.add_child(setup_material_storage(line.to_int()))
		elif line.begins_with("Reminder:"): #Reminder text
			if parent.get_child(-1).is_in_group("Spacer"):
				parent.get_child(-1).queue_free()
				
			line = line.replace("Reminder:","")
			const BODY_TEXT_PREFAB = preload("res://Prefabs/reminder_text.tscn")
			var body_text_label: RichTextLabel = BODY_TEXT_PREFAB.instantiate() as RichTextLabel
			body_text_label.text = dress_up_text(line)
			parent.add_child(body_text_label)
			parent.add_child(SPACER_PREFAB.instantiate())
		else: #Normal Line
			const BODY_TEXT_PREFAB = preload("res://Prefabs/body_text_prefab.tscn")
			var body_text_label: RichTextLabel = BODY_TEXT_PREFAB.instantiate() as RichTextLabel
			body_text_label.text = dress_up_text(line)
			parent.add_child(body_text_label)
			parent.add_child(SPACER_PREFAB.instantiate())

func dress_up_text(input: String) -> String:
	var bold_keywords: Array[String] = [
		"Mine",
		"Colonist",
		"Generate",
		"Material",
		"Odd",
		"Even",
		"Arboretum",
		"Investigate",
		"Region",
		"Taking Off",
		"Energy",
		"Blue",
		"Building",
		"U-Reactor",
		"VP",
		"Mothership",
	]
	
	for keyword: String in bold_keywords.duplicate():
		bold_keywords.append(keyword + "s")
	bold_keywords.reverse() #reverse so we check the plurals fit
	for keyword: String in bold_keywords:
		input = input.replace(keyword, "[b]" + keyword + "[/b]")
	
	for icon_key: String in ICON_MAP.keys():
		var searched_to: int = 0
		for i in range(20): #could be while, but I'm a scardy cat
			searched_to = input.find(icon_key, searched_to)
			var icon: Texture2D = ICON_MAP[icon_key] as Texture2D
			var img_string: String = "[img]"+ icon.resource_path +"[/img]"
			if searched_to == -1:
				break
			var count: int = input[searched_to - 1].to_int()
			if count == 0:
				continue
			var inserted_string: String = img_string.repeat(count)
			input = input.substr(0,searched_to - 1) + inserted_string + input.substr(searched_to + icon_key.length())
			searched_to = searched_to + inserted_string.length()
		
	var output: String = ""
	output += "[center]"
	output += input
	return output

func setup_repeating_effect(text: String) -> Control:
	const REPEATING_EFFECT_PREFAB = preload("uid://dkv74n22ugpc8")
	var repeating_effect: Control = REPEATING_EFFECT_PREFAB.instantiate() as Control
	
	var repeating_effect_box: Control = repeating_effect.get_node("%Repeating Effect Box") as Control
	var repeating_effect_text: RichTextLabel = repeating_effect.get_node("%Repeating Effect Text") as RichTextLabel
	var repeating_effect_icon: TextureRect = repeating_effect.get_node("%Repeating Effect Icon") as TextureRect
	repeating_effect_box.self_modulate = COLOR_MAP[card_type]
	#repeating_effect_icon.self_modulate = COLOR_MAP[card_type]
	repeating_effect_text.text = dress_up_text(text)
	
	return repeating_effect

func setup_data_storage(count: int) -> Control:
	if count == 0:
		return null
	
	const DATA_STORAGE_PREFAB = preload("uid://cyu24w3s4i0vh")
	var data_storage: HFlowContainer = DATA_STORAGE_PREFAB.instantiate() as Container
	
	var data_socket_template: TextureRect = data_storage.get_node("%Data Socket Template") as TextureRect
	data_socket_template.visible = false
	for c in data_storage.get_children():
		if c != data_socket_template:
			c.queue_free()
	
	for i in range(count):
		var new_socket: TextureRect = data_socket_template.duplicate() as TextureRect
		new_socket.unique_name_in_owner = false
		new_socket.visible = true
		data_storage.add_child(new_socket)
	
	return data_storage

func setup_colonist_storage(count: int) -> Control:
	const HEX_GRID_MAP: Dictionary = {
		3: preload("res://Icons/Hex Grids/hex_grids_3.png"),
		4: preload("res://Icons/Hex Grids/hex_grids_4.png"),
		5: preload("res://Icons/Hex Grids/hex_grids_5.png"),
		7: preload("res://Icons/Hex Grids/hex_grids_7.png"),
		8: preload("res://Icons/Hex Grids/hex_grids_8.png"),
		10: preload("res://Icons/Hex Grids/hex_grids_10.png"),
		12: preload("res://Icons/Hex Grids/hex_grids_12.png")
	}
	
	if count == 0: return null
	const COLONIST_GRID_PREFAB = preload("uid://2yyykbjwt1lj")
	var colonist_storage: Control = COLONIST_GRID_PREFAB.instantiate() as Control
	colonist_storage.texture = HEX_GRID_MAP[count]
	return colonist_storage

func setup_material_storage(count: int) -> Control:
	if count == 0:
		return null
	const MATERIAL_STORAGE_PREFAB = preload("uid://bewiewfl0gnwe")
	var material_storage: Control = MATERIAL_STORAGE_PREFAB.instantiate() as Control
	
	var material_socket_container: Container = material_storage.get_node("%Material Socket Container") as Container
	var material_socket_template: TextureRect = material_storage.get_node("%Material Socket Template") as TextureRect
	
	material_socket_template.visible = false
	for c in material_socket_container.get_children():
		if c != material_socket_template:
			c.queue_free()
	
	var i: int = 0
	while i < count:
		var new_socket: TextureRect = material_socket_template.duplicate() as TextureRect
		new_socket.visible = true
		new_socket.unique_name_in_owner = false
		material_socket_container.add_child(new_socket)
		if count - i >= 5:
			i += 5
			const X5_MATERIAL_ICON = preload("res://Icons/Icons_x5 Materials.png")
			new_socket.texture = X5_MATERIAL_ICON
		else:
			i += 1
			const X1_MATERIAL_ICON = preload("res://Icons/Icons_x1 Materials.png")
			new_socket.texture = X1_MATERIAL_ICON
	
	return material_storage

func setup_cost_bar() -> void:
	var card_cost_spacer: Control = %"Card Cost Spacer" as Control
	var cost_bar: MarginContainer = %"Cost Bar" as MarginContainer
	
	var has_cost: bool = cost.strip_edges() != ""
	cost_bar.visible = has_cost
	card_cost_spacer.visible = has_cost
	
	
	var cost_container: Control = %"Cost Container" as Control
	var cost_icon_template: TextureRect = %"Cost Icon Template" as TextureRect
	
	cost_icon_template.visible = false
	for cost_icon: Control in cost_container.get_children():
		if cost_icon != cost_icon_template:
			cost_icon.queue_free()
	
	if not has_cost: return
	
	
	for c in cost.split(" "):
		var count: int = int(c[0])
		var type: String = c.right(-1)
		for i in range(count):
			var new_cost_icon: TextureRect = cost_icon_template.duplicate() as TextureRect
			cost_container.add_child(new_cost_icon)
			new_cost_icon.unique_name_in_owner = false
			new_cost_icon.visible = true
			new_cost_icon.texture = ICON_MAP[type]

func setup_card_shape() -> void:
	size = dimensions + Vector2(bleed_width *2, bleed_width*2)
	ProjectSettings.set_setting("display/window/size/viewport_width",size.x)
	ProjectSettings.set_setting("display/window/size/viewport_height",size.y)
	
	var bleed: MarginContainer = %Bleed as MarginContainer
	bleed.add_theme_constant_override("margin_left", bleed_width)
	bleed.add_theme_constant_override("margin_right", bleed_width)
	bleed.add_theme_constant_override("margin_top", bleed_width)
	bleed.add_theme_constant_override("margin_bottom", bleed_width)
	
	var border: MarginContainer = %Border as MarginContainer
	border.add_theme_constant_override("margin_left", border_width)
	border.add_theme_constant_override("margin_right", border_width)
	border.add_theme_constant_override("margin_top", border_width)
	border.add_theme_constant_override("margin_bottom", border_width)

