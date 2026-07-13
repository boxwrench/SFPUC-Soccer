class_name FlagHelper

const FLAG_PATHS: Dictionary[String, String] = {
	"WATER": "res://assets/art/ui/flags/flag_water.png",
	"POWER": "res://assets/art/ui/flags/flag_power.png",
	"SEWER": "res://assets/art/ui/flags/flag_sewer.png",
	"HETCH HETCHY WATER AND POWER": "res://assets/art/ui/flags/flag_hhwp.png",
}
const SELECTION_FLAG_PATHS: Dictionary[String, String] = {
	"WATER": "res://assets/art/ui/flags/team-card_water.png",
	"POWER": "res://assets/art/ui/flags/team-card_power.png",
	"SEWER": "res://assets/art/ui/flags/team-card_sewer.png",
	"HETCH HETCHY WATER AND POWER": "res://assets/art/ui/flags/team-card_hhwp.png",
}
const PLACEHOLDER_PATH := "res://assets/art/ui/flags/flag-placeholder.png"

static var flag_textures: Dictionary[String, Texture2D] = {}
static var selection_textures: Dictionary[String, Texture2D] = {}

static func get_texture(country: String) -> Texture2D:
	if not flag_textures.has(country):
		var path: String = FLAG_PATHS.get(country.to_upper(), PLACEHOLDER_PATH)
		flag_textures.set(country, load(path))
	return flag_textures[country]

static func get_selection_texture(country: String) -> Texture2D:
	if not selection_textures.has(country):
		var path: String = SELECTION_FLAG_PATHS.get(country.to_upper(), PLACEHOLDER_PATH)
		selection_textures.set(country, load(path))
	return selection_textures[country]