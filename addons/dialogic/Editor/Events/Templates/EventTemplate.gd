tool
extends HBoxContainer

export(StyleBoxFlat) var event_style : StyleBoxFlat
export(Texture) var event_icon : Texture
export(String) var event_name : String
export(PackedScene) var header_scene : PackedScene
export(PackedScene) var body_scene : PackedScene

signal option_action(action_name)

onready var panel = $PanelContainer
onready var title_label = $PanelContainer/MarginContainer/VBoxContainer/Header/TitleMarginContainer/TitleLabel
onready var icon_texture  = $PanelContainer/MarginContainer/VBoxContainer/Header/IconMarginContainer/IconTexture
onready var expand_control = $PanelContainer/MarginContainer/VBoxContainer/Header/ExpandControl
onready var options_control = $PanelContainer/MarginContainer/VBoxContainer/Header/OptionsControl
onready var header_content_container = $PanelContainer/MarginContainer/VBoxContainer/Header/Content
onready var body_container = $PanelContainer/MarginContainer/VBoxContainer/Body
onready var body_content_container = $PanelContainer/MarginContainer/VBoxContainer/Body/Content

var header_node
var body_node


## *****************************************************************************
##								PUBLIC METHODS
## *****************************************************************************


func set_event_style(style: StyleBoxFlat):
	panel.set('custom_styles/panel', style)
	

func set_event_icon(icon: Texture):
	icon_texture.texture = icon


func set_event_name(text: String):
	title_label.text = text


func set_header(scene: PackedScene):
	header_node = _set_content(header_content_container, scene)


func set_body(scene: PackedScene):
	body_node = _set_content(body_content_container, scene)


func get_body():
	return body_node

func get_header():
	return header_node


## *****************************************************************************
##								PRIVATE METHODS
## *****************************************************************************


func _setup_event():
	print('set props')
	if event_style != null:
		set_event_style(event_style)
	if event_icon != null:
		set_event_icon(event_icon)
	if event_name != null:
		set_event_name(event_name)
	if header_scene != null:
		set_header(header_scene)
	if body_scene != null:
		set_body(body_scene)


func _set_content(container: Control, scene: PackedScene):
	for c in container.get_children():
		container.remove_child(c)
	var node = scene.instance()
	container.add_child(node)
	node.set_owner(get_tree().get_edited_scene_root())
	return node


func _on_ExpandControl_state_changed(expanded: bool):
	if expanded:
		body_container.show()
	else:
		body_container.hide()


func _on_OptionsControl_action(action_name: String):
	# Simply transmit the signal to the timeline editor
	emit_signal("option_action", action_name)


## *****************************************************************************
##								OVERRIDES
## *****************************************************************************


func _ready():
	_setup_event()
	expand_control.set_enabled(body_scene != null)
	expand_control.connect("state_changed", self, "_on_ExpandControl_state_changed")
	options_control.connect("action", self, "_on_OptionsControl_action")
