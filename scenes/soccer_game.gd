class_name SoccerGame
extends Node

enum ScreenType {MAIN_MENU, TEAM_SELECTION, TOURNAMENT, IN_GAME}

@onready var brand_overlay: CanvasLayer = $BrandOverlay
@onready var game_viewport: SubViewport = $GameViewportContainer/GameViewport

var current_screen: Screen = null
var current_screen_type: ScreenType = ScreenType.MAIN_MENU
var screen_factory := ScreenFactory.new()

func _init() -> void:
	switch_screen(ScreenType.MAIN_MENU)

func _ready() -> void:
	attach_current_screen()

func switch_screen(screen: ScreenType, data: ScreenData = ScreenData.new()) -> void:
	if current_screen != null:
		current_screen.queue_free()
	current_screen = screen_factory.get_fresh_screen(screen)
	current_screen_type = screen
	current_screen.setup(self, data)
	current_screen.screen_transition_requested.connect(switch_screen.bind())
	if is_node_ready():
		attach_current_screen()

func attach_current_screen() -> void:
	if current_screen != null and current_screen.get_parent() == null:
		game_viewport.add_child(current_screen)
	brand_overlay.visible = current_screen_type == ScreenType.MAIN_MENU