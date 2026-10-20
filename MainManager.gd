extends Node

enum Difficulty {
	EASY, NORMAL, HARD, HARDCORE
}
enum FlickerType {
	LOW, MEDIUM, HIGH
}


const SAVEFILE_PATH = "user://savefile.json"
const DEFAULT_SAVE_DATA = {
	"difficulty": Difficulty.NORMAL,
	"is_flicker_enabled": true,
	"is_controls_ui_enabled": true,
	"flicker_type": FlickerType.MEDIUM
}

var isFlickerEnabled: bool
var difficulty: Difficulty
var isControlsUiEnabled: bool
var flicker_type: FlickerType

# Battle data
var ldoor_closed: bool
var rdoor_closed: bool
var power: float
var money: int
var where_lynx: GameManager.Where
var where_bars: GameManager.Where
var where_tofy: GameManager.Where
var where_cool: GameManager.Where

func reset():
	ldoor_closed = false
	rdoor_closed = false
	power = 100
	money = 500
	where_lynx = GameManager.Where.NONE
	where_bars = GameManager.Where.DRUMS
	where_tofy = GameManager.Where.SCENE
	where_cool = GameManager.Where.SCENE

func loadgame() -> void:
	var file = FileAccess.open(SAVEFILE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	isFlickerEnabled = data["is_flicker_enabled"]
	difficulty = data["difficulty"]
	isControlsUiEnabled = data["is_controls_ui_enabled"]
	flicker_type = data["flicker_type"]
	
func savegame() -> void:
	var file = FileAccess.open(SAVEFILE_PATH, FileAccess.WRITE)
	var data = {
		"difficulty": difficulty,
		"is_flicker_enabled": isFlickerEnabled,
		"is_controls_ui_enabled": isControlsUiEnabled,
		"flicker_type": flicker_type
	}
	
	file.store_string(JSON.stringify(data))
	
func _ready() -> void:
	reset()
	if FileAccess.file_exists(SAVEFILE_PATH):
		loadgame()
	else:
		var file = FileAccess.open(SAVEFILE_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(DEFAULT_SAVE_DATA))
