@tool
extends OptionButton

var loaded_locales: PackedStringArray
var selected_locale: String
# Initialized in plugin.gd
var undo_redo: EditorUndoRedoManager
var _handlers := {
	"Label": tr_text_prop,
	"RichTextLabel": tr_text_prop,
	"Button": tr_text_prop,
	"CheckButton": tr_text_prop,
	"MenuButton": tr_text_prop,
	"OptionButton": tr_popmenu,
	"LinkButton": tr_text_prop,
	"LineEdit": tr_line_edit,
	"MenuBar": tr_menubar,
	"PopupMenu": tr_popmenu,
	"TabBar": tr_tabbar,
	"GraphFrame": tr_title_prop,
	"GraphNode": tr_title_prop,
	"TabContainer": tr_tabcontainer,
}
var _nodes_data := {}
var _custom_handlers := {}
var _custom_handlers_instance: Object


func _ready() -> void:
	selected = 0
	ProjectSettings.settings_changed.connect(_on_project_settings_changed)

	var project_locales := TranslationService.get_translations()
	if project_locales:
		update_items(PackedStringArray(project_locales.keys()))
	else:
		clear()
		add_item("None")
		add_separator()


func update_items(locales: PackedStringArray) -> void:
	if loaded_locales == locales:
		return
	loaded_locales = locales

	clear()
	add_item("None")
	add_separator()
	for locale in loaded_locales:
		add_item(locale)


func cancel_preview() -> void:
	selected = 0
	translate_node(EditorInterface.get_edited_scene_root(), false)
	_nodes_data.clear()


func enable_translation(locale: String) -> void:
	TranslationServer.set_locale(locale)
	selected = loaded_locales.find(locale) + 2
	translate_node(EditorInterface.get_edited_scene_root())

	var _custom_translation_handlers_path := ProjectSettings.get_setting("translation_preview/translation_handlers_path")
	if _custom_translation_handlers_path:
		if FileAccess.file_exists(_custom_translation_handlers_path):
			var _custom_handlers_file := load(_custom_translation_handlers_path)
			_custom_handlers_instance = _custom_handlers_file.new()
			if _custom_handlers_instance and _custom_handlers_instance.get("handlers"):
				_custom_handlers = _custom_handlers_instance.handlers
			else:
				_custom_handlers = {}


func translate_node(node: Node, translation_mode := true) -> void:
	var node_class := node.get_class()
	if node.get_script() and node.get_script().get_global_name():
		var node_class_name := node.get_script().get_global_name() as StringName
		if _custom_handlers.has(node_class_name):
			var tr_func := _custom_handlers[node_class_name] as Callable
			_nodes_data = tr_func.call(node, translation_mode, _nodes_data)

	if node.has_method("tr_editor"):
		_nodes_data = node.tr_editor(translation_mode, _nodes_data)
	elif _handlers.has(node_class):
		(_handlers[node_class] as Callable).call(node, translation_mode)

	for child in node.get_children():
		translate_node(child, translation_mode)


#region TranslationHandlers
func tr_text_prop(node: Control, translation_mode: bool) -> void:
	if translation_mode:
		if !_nodes_data.has(node):
			_nodes_data[node] = node.text
		node.text = TranslationService.translate(_nodes_data[node])
	else:
		if _nodes_data.has(node):
			node.text = _nodes_data[node]
			_nodes_data.erase(node)


func tr_title_prop(node: Control, translation_mode: bool) -> void:
	if translation_mode:
		if !_nodes_data.has(node):
			_nodes_data[node] = node.title
		node.title = TranslationService.translate(_nodes_data[node])
	else:
		if _nodes_data.has(node):
			node.title = _nodes_data[node]
			_nodes_data.erase(node)


func tr_popmenu(node: Node, translation_mode: bool) -> void:
	var popmenu: PopupMenu
	if node is OptionButton:
		popmenu = node.get_popup()
	else:
		popmenu = node as PopupMenu

	var items_native_texts: PackedStringArray = []
	if _nodes_data.has(node):
		items_native_texts = _nodes_data[node]
	else:
		for idx in range(popmenu.item_count):
			items_native_texts.append(popmenu.get_item_text(idx))
	_nodes_data[node] = items_native_texts

	if translation_mode:
		var translated_items_native_texts: PackedStringArray = []
		for item_text in items_native_texts:
			translated_items_native_texts.append(TranslationService.translate(item_text))
		for idx in range(popmenu.item_count):
			if node is OptionButton:
				node.set_item_text(idx, translated_items_native_texts[idx])
				continue
			popmenu.set_item_text(idx, translated_items_native_texts[idx])
	else:
		if _nodes_data.has(node):
			for idx in range(popmenu.item_count):
				if node is OptionButton:
					node.set_item_text(idx, items_native_texts[idx])
					continue
				popmenu.set_item_text(idx, items_native_texts[idx])
			_nodes_data.erase(node)


func tr_menubar(node: MenuBar, translation_mode: bool) -> void:
	if !_nodes_data.has(node):
		_nodes_data[node] = []

	var _node_data := _nodes_data[node] as PackedStringArray
	var node_children := node.find_children("*", "PopupMenu", false)
	if translation_mode:
		if _node_data.is_empty():
			for child in node_children:
				if child is PopupMenu:
					_node_data.append(child.name)
			_nodes_data[node] = _node_data
		var idx := 0
		for child in node_children:
			child.name = TranslationService.translate(_node_data[idx])
			idx += 1
	else:
		if _node_data:
			var idx := 0
			for child in node_children:
				child.name = _node_data[idx]
				idx += 1
			_nodes_data.erase(node)
	node.queue_redraw()


func tr_line_edit(node: LineEdit, translation_mode: bool) -> void:
	if translation_mode:
		var what_needtr_anslate := node.placeholder_text as String
		if _nodes_data.has(node):
			what_needtr_anslate = _nodes_data[node]
		_nodes_data[node] = what_needtr_anslate
		node.placeholder_text = TranslationService.translate(what_needtr_anslate)
	else:
		if _nodes_data.has(node):
			var node_data: Variant = _nodes_data[node]
			node.placeholder_text = node_data


func tr_tabbar(node: TabBar, translation_mode: bool) -> void:
	var tabs_native_titles: PackedStringArray = []
	if _nodes_data.has(node):
		tabs_native_titles = _nodes_data[node]
	else:
		for idx in range(node.tab_count):
			tabs_native_titles.append(node.get_tab_title(idx))
	_nodes_data[node] = tabs_native_titles

	if translation_mode:
		var translated_tabs_native_titles: PackedStringArray = []
		for item_text in tabs_native_titles:
			translated_tabs_native_titles.append(TranslationService.translate(item_text))
		for idx in range(node.tab_count):
			node.set_tab_title(idx, translated_tabs_native_titles[idx])
	else:
		if _nodes_data.has(node):
			for idx in range(node.tab_count):
				node.set_tab_title(idx, tabs_native_titles[idx])
			_nodes_data.erase(node)


func tr_tabcontainer(node: TabContainer, translation_mode: bool) -> void:
	if !_nodes_data.has(node):
		_nodes_data[node] = []

	var _node_data := _nodes_data[node] as PackedStringArray
	var node_children := node.get_children()
	if translation_mode:
		if _node_data.is_empty():
			for child in node_children:
				_node_data.append(child.name)
			_nodes_data[node] = _node_data
		var idx := 0
		for child in node_children:
			child.name = TranslationService.translate(_node_data[idx])
			idx += 1
	else:
		if _node_data:
			var idx := 0
			for child in node_children:
				child.name = _node_data[idx]
				idx += 1
			_nodes_data.erase(node)
#endregion


func _on_item_selected(index: int) -> void:
	selected_locale = get_item_text(index)
	if index == 0:
		cancel_preview()
		return
	undo_redo.create_action("Enable translation preview: " + selected_locale)
	undo_redo.add_do_method(self, &"enable_translation", selected_locale)
	undo_redo.add_undo_method(self, &"cancel_preview")
	undo_redo.commit_action()


func _on_project_settings_changed() -> void:
	var new_locales := PackedStringArray(TranslationService.get_translations().keys())
	if loaded_locales != new_locales:
		update_items(new_locales)
