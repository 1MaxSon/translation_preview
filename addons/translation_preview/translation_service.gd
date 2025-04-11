# This script is based on a project found on GitHub.
# Original source: https://github.com/AnidemDex/Godot-TranslationService
# Author: AnidemDex
#
#
# Original code is licensed under MIT license, see LICENSE file in the repository.
class_name TranslationService
## Alternative to [TranslationServer] that works inside the editor


## Translates a message using translation catalogs configured in the Project Settings.
static func translate(message: String) -> String:
	var translation: String
	if Engine.is_editor_hint():
		translation = _get_translation(message)
	else:
		translation = TranslationServer.translate(message)

	return translation


## Returns a dictionary using translation catalogs configured in the Project Settings.
## Each key correspond to [locale](https://docs.godotengine.org/en/stable/tutorials/i18n/locales.html).
## Each value is an Array of [Translation].
static func get_translations() -> Dictionary:
	var translations_resources: PackedStringArray = ProjectSettings.get_setting("internationalization/locale/translations")
	var translations := {}

	for resource in translations_resources:
		var t: Translation = load(resource)
		if translations.has(t.locale):
			translations[t.locale].append(t)
		else:
			translations[t.locale] = [t]
	return translations


static func _get_translation(_msg: String) -> String:
	var _returned_translation := _msg
	var _translations := get_translations()
	var _default_fallback := ProjectSettings.get_setting("internationalization/locale/fallback")
	var _test_locale := ProjectSettings.get_setting("internationalization/locale/test")
	var _locale := TranslationServer.get_locale()

	if _test_locale:
		_locale = _test_locale

	var cases = _translations.get(_locale, _translations.get(_default_fallback, [Translation.new()]))
	for case: Translation in cases:
		_returned_translation = case.get_message(_msg)
		if _returned_translation:
			break
		else:
			_returned_translation = _msg

	return _returned_translation
