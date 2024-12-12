@tool
extends EditorPlugin

const TranslationOptionButton = preload("./translation_option_button.tscn")
const TranslationOptionButtonClass = preload("./translation_option_button.gd")
var option_button: TranslationOptionButtonClass


func _enter_tree() -> void:
	option_button = TranslationOptionButton.instantiate()
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, option_button)
	self.scene_changed.connect(_on_scene_changed)
	self.scene_closed.connect(_on_scene_closed)

	option_button.undo_redo = get_undo_redo()
	if !ProjectSettings.has_setting("translation_preview/translation_handlers_path"):
		ProjectSettings.set_setting("translation_preview/translation_handlers_path", "res://translation_handlers.gd")
		ProjectSettings.set_initial_value("translation_preview/translation_handlers_path", "res://translation_handlers.gd")


func _exit_tree() -> void:
	if option_button.selected > 0:
		option_button.cancel_preview()
		get_editor_interface().save_all_scenes()
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, option_button)
	option_button.free()


func _on_scene_changed(_scene_root: Node) -> void:
	if option_button.selected > 0:
		option_button.cancel_preview()


func _on_scene_closed(_file_path: String) -> void:
	if option_button.selected > 0:
		option_button.cancel_preview()
