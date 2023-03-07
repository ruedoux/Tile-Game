### ----------------------------------------------------
### Input management for MapEditor
### Key inputs:
### 	Q and E - Switch TileMap
### 	Z and X - Switch tile
### 	Alt     - Load current map
### 	Ctrl    - Save current map
### 	F       - Add filter to listed tiles
### ----------------------------------------------------

extends Node2D

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

onready var TileSelect := {
	filter = "",			# Item filter keyword
	allTileMaps = [],		# List of all tilemaps
	tileData = [],			# Data regarding tiles (same order as all tilemaps)
	shownTiles = [],		# List of all show tiles (in TileList)
	TMIndex = 0,			# TileMap index (allTileMaps)
	listIndex = 0,			# Index of selected item
}

onready var UIElement := {
	Parent =         $UIElements/MC,
	TileScroll =     $UIElements/MC/GC/TileScroll,
	TMSelect =       $UIElements/MC/GC/TileScroll/TMSelect,
	TileList =       $UIElements/MC/GC/TileScroll/ItemList,
	SaveEdit =       $UIElements/MC/GC/Info/SaveEdit,
	LoadEdit =       $UIElements/MC/GC/Info/LoadEdit,
	FilterEdit =     $UIElements/MC/GC/Info/FilterEdit,
	GotoEdit =       $UIElements/MC/GC/Info/Goto,
	ChunkLabel =     $UIElements/MC/GC/Info/Chunk,
	ElevationLabel = $UIElements/MC/GC/Info/Elevation,
	CellLabel =      $UIElements/MC/GC/Info/Cell,
	Filter =         $UIElements/MC/GC/Info/Filter,
}

var EditorStateMachine := StateMachine.new(true)

var inputActive := true

const EDITOR_SAVE_NAME := "EDITOR"
var EditedMap:SQLSave

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _ready() -> void:
	var isOK := true
	EditorStateMachine.add_state(NORM_STATE.new(self))
	EditorStateMachine.add_state(FLTR_STATE.new(self))
	EditorStateMachine.add_state(SAVE_STATE.new(self))
	EditorStateMachine.add_state(LOAD_STATE.new(self))
	EditorStateMachine.add_state(GOTO_STATE.new(self))
	isOK = isOK and EditorStateMachine.set_state(NORM_STATE.get_name())
	isOK = isOK and EditorStateMachine.add_default_state(NORM_STATE.get_name())
	if(not isOK):
		push_error("Failed to init EditorStateMachine")
		get_tree().quit()
	
	VisualServer.set_default_clear_color(Color.darkslateblue)
	TileSelect.allTileMaps = $TileMapManager.get_tilemaps()
	
	EditedMap = SQLSave.new(EDITOR_SAVE_NAME, SaveManager.MAP_FOLDER)
	if(not EditedMap.create_new_save(TileSelect.allTileMaps)):
		push_error("Failed to init MapEditor")
		get_tree().quit()
	if(not EditedMap.load(TileSelect.allTileMaps)):
		push_error("Failed to init MapEditor")
		get_tree().quit()
	
	_init_TM_selection()
	_init_tile_select()
	
	if(EditorStateMachine.force_call(NORM_STATE.get_name(), "switch_TM_selection", [0]) == null):
		push_error("Failed to init EditorStateMachine")
		get_tree().quit()

### ----------------------------------------------------
# Init
### ----------------------------------------------------

func _init_TM_selection():
	for tileMap in TileSelect.allTileMaps:
		var TMName:String = tileMap.get_name()
		UIElement.TMSelect.add_item (TMName)

func _init_tile_select():
	for tileMap in TileSelect.allTileMaps:
		TileSelect.tileData.append(LibK.TS.get_tile_names_and_IDs(tileMap.tile_set))

### ----------------------------------------------------
# Drawing
### ----------------------------------------------------
func _draw():
	var mousePos:Vector2 = get_global_mouse_position()
	_draw_selection_square(mousePos)
	_draw_selection_chunk(mousePos)
	_draw_loaded_chunks()

# Draws a square to indicate current cell pointed by mouse cursor
func _draw_selection_square(mousePos:Vector2):
	var size = Vector2(GLOBAL.TILEMAPS.BASE_SCALE,GLOBAL.TILEMAPS.BASE_SCALE)
	var cellPosV2:Vector2 = LibK.Vectors.scale_down_vec2(mousePos, GLOBAL.TILEMAPS.BASE_SCALE)
	var posV2:Vector2 = cellPosV2 * GLOBAL.TILEMAPS.BASE_SCALE
	
	var rect = Rect2(posV2,size)
	UIElement.CellLabel.text = "Cell: " + str(cellPosV2)
	
	draw_rect(rect,Color.crimson,false,1)

# Draws a square to indicate current chunk pointed by mouse cursor
func _draw_selection_chunk(mousePos:Vector2):
	var chunkScale:int = GLOBAL.TILEMAPS.BASE_SCALE * GLOBAL.TILEMAPS.CHUNK_SIZE
	var chunkV2:Vector2 = LibK.Vectors.scale_down_vec2(mousePos, GLOBAL.TILEMAPS.CHUNK_SIZE*GLOBAL.TILEMAPS.BASE_SCALE)
	var posV2:Vector2 = chunkV2 * chunkScale
	var rect = Rect2(posV2, Vector2(chunkScale, chunkScale))
	
	UIElement.ChunkLabel.text = "Chunk: " + str(chunkV2)
	draw_rect(rect, Color.black, false, 1)

# Draws squares around all loaded chunks
func _draw_loaded_chunks():
	for posV3 in $TileMapManager.RenderedChunks:
		var chunkScale:int = GLOBAL.TILEMAPS.BASE_SCALE * GLOBAL.TILEMAPS.CHUNK_SIZE
		var posV2:Vector2 = LibK.Vectors.vec3_vec2(posV3) * chunkScale
		var rect = Rect2(posV2, Vector2(chunkScale, chunkScale))
		draw_rect(rect, Color.red, false, 1)


### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _input(event:InputEvent) -> void:
	if(not inputActive): return
	EditorStateMachine.update_state_input(event)

# Default editor state
class NORM_STATE extends SMState:
	var TileSelect:Dictionary
	var UIElement:Dictionary
	var TileMapManager:Node2D
	var EditedMap:SQLSave
	var UIZone:bool
	var Cam:Camera2D
	
	func _init(caller:Node2D).(caller) -> void:
		pass

	static func get_name() -> String:
		return "NORM_STATE"
	
	# This could be an input map but doing it with ifs is good enough
	func update_input(event:InputEvent) -> void:
		UIZone = LibK.UI.is_mouse_on_ui(UIElement.TileScroll, UIElement.Parent)

		if(((event is InputEventMouseButton) or (event is InputEventMouseMotion)) and not UIZone):
			if not TileSelect.shownTiles.size() > 0: return # If list empty dont pick
			if event.button_mask == BUTTON_MASK_LEFT:  
				var tileID:int = TileSelect.shownTiles[TileSelect.listIndex][1]
				set_selected_tile(tileID)
			if event.button_mask == BUTTON_MASK_RIGHT: 
				set_selected_tile(-1)
		
		if(not UIZone):
			if(event is InputEventMouseButton):
				if(event.button_index == BUTTON_WHEEL_UP):
					Cam.zoom_camera(-Cam.zoomValue)
				elif(event.button_index == BUTTON_WHEEL_DOWN):
					Cam.zoom_camera(Cam.zoomValue)
			if(event is InputEventMouseMotion):
				if(event.button_mask == BUTTON_MASK_MIDDLE):
					Cam.position -= event.relative * Cam.zoom
		
		if(event.is_action_pressed(GLOBAL.INPUT.MAP["E"])): 
			switch_TM_selection(TileSelect.TMIndex + 1)
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["Q"])): 
			switch_TM_selection(TileSelect.TMIndex - 1)
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["X"])):
			switch_tile_selection(TileSelect.listIndex + 1)
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["Z"])): 
			switch_tile_selection(TileSelect.listIndex - 1)
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["-"])):
			change_elevation(-1)
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["="])):
			change_elevation(1)
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["F"])):
			StateMaster.set_state(Caller.FLTR_STATE.get_name())
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["LCtrl"])):
			StateMaster.set_state(Caller.SAVE_STATE.get_name())
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["LAlt"])):
			StateMaster.set_state(Caller.LOAD_STATE.get_name())
		elif(event.is_action_pressed(GLOBAL.INPUT.MAP["G"])):
			StateMaster.set_state(Caller.GOTO_STATE.get_name())
	
	func switch_TM_selection(value:int) -> void:
		TileSelect.TMIndex = value
		if(TileSelect.TMIndex > (TileSelect.allTileMaps.size() - 1)): 
			TileSelect.TMIndex = 0
		if(TileSelect.TMIndex < 0): 
			TileSelect.TMIndex = (TileSelect.allTileMaps.size() - 1)
		
		TileSelect.listIndex = 0
		fill_item_list()
		
		UIElement.TMSelect.select(TileSelect.TMIndex)
		switch_tile_selection(TileSelect.listIndex)
	
	func switch_tile_selection(value:int) -> void:
		TileSelect.listIndex = value
		if(TileSelect.listIndex > (UIElement.TileList.get_item_count() - 1)): 
			TileSelect.listIndex = 0
		if(TileSelect.listIndex < 0): 
			TileSelect.listIndex = (UIElement.TileList.get_item_count() - 1)
		
		UIElement.TileList.select(TileSelect.listIndex)
	
	func set_selected_tile(tileID:int) -> void:
		var tileMap:TileMap = TileSelect.allTileMaps[TileSelect.TMIndex]
		var mousePos:Vector2 = tileMap.world_to_map(Caller.get_global_mouse_position())
		var posV3:Vector3 = LibK.Vectors.vec2_vec3(mousePos, Cam.currentElevation)
		var chunkV3:Vector3 = LibK.Vectors.vec2_vec3(
			LibK.Vectors.scale_down_vec2(mousePos, GLOBAL.TILEMAPS.CHUNK_SIZE),
			Cam.currentElevation)
		if(not chunkV3 in TileMapManager.RenderedChunks): return
		var TMName = tileMap.get_name()
		
		if(tileID == -1):
			EditedMap.remove_tile_from_TileData(TMName,posV3)
		else:
			if(not EditedMap.add_tile_to_TileData_on(posV3, TMName, tileID)):
				Logger.logErr(["Failed to set tile: ", [posV3, TMName, tileID]], get_stack())
		TileMapManager.refresh_tile_on(posV3, EditedMap.get_TileData_on(posV3))
	
	func change_elevation(direction:int) -> void:
		Cam.currentElevation += direction
		UIElement.ElevationLabel.text = "Elevation: " + str(Cam.currentElevation)
		TileMapManager.unload_all_chunks()

	# Fills item list with TileMap tiles
	func fill_item_list() -> void:
		UIElement.TileList.clear()
		TileSelect.shownTiles.clear()
		
		var tileMap:TileMap = TileSelect.allTileMaps[TileSelect.TMIndex]
		for packed in TileSelect.tileData[TileSelect.TMIndex]:
			var tileName:String = packed[0]
			var tileID:int = packed[1]
			var tileTexture:Texture = LibK.TS.get_tile_texture(tileID, tileMap.tile_set)

			if(TileSelect.filter != ""):
				if(not TileSelect.filter.to_lower() in tileName.to_lower()): 
					continue
			UIElement.TileList.add_item(tileName,tileTexture,true)
			TileSelect.shownTiles.append([tileName,tileID])

class FLTR_STATE extends SMState:
	var UIElement:Dictionary
	
	func _init(caller:Node2D).(caller) -> void:
		pass

	static func get_name() -> String:
		return "FLTR_STATE"
	
	func _state_set() -> void:
		Caller._show_lineEdit("addingFilter", UIElement.FilterEdit)
	
	func update_input(event:InputEvent) -> void:
		if(event.is_action_pressed(GLOBAL.INPUT.MAP["ESC"])):
			Caller._hide_lineEdit("addingFilter", UIElement.FilterEdit)
			StateMaster.set_default_state()

class SAVE_STATE extends SMState:
	var UIElement:Dictionary

	func _init(caller:Node).(caller) -> void:
		pass

	static func get_name() -> String:
		return "SAVE_STATE"
	
	func _state_set() -> void:
		Caller._show_lineEdit("isSaving", UIElement.SaveEdit)
	
	func update_input(event:InputEvent) -> void:
		if(event.is_action_pressed(GLOBAL.INPUT.MAP["ESC"])):
			Caller._hide_lineEdit("isSaving", UIElement.SaveEdit)
			StateMaster.set_default_state()

class LOAD_STATE extends SMState:
	var UIElement:Dictionary
	
	func _init(caller:Node2D).(caller) -> void:
		pass

	static func get_name() -> String:
		return "LOAD_STATE"
	
	func _state_set() -> void:
		Caller._show_lineEdit("isLoading", UIElement.LoadEdit)
	
	func update_input(event:InputEvent) -> void:
		if(event.is_action_pressed(GLOBAL.INPUT.MAP["ESC"])):
			Caller._hide_lineEdit("isLoading", UIElement.LoadEdit)
			StateMaster.set_default_state()

class GOTO_STATE extends SMState:
	var UIElement:Dictionary
	
	func _init(caller:Node2D).(caller) -> void:
		pass

	static func get_name() -> String:
		return "GOTO_STATE"

	func _state_set() -> void:
		Caller._show_lineEdit("goto", UIElement.GotoEdit)
	
	func update_input(event:InputEvent) -> void:
		if(event.is_action_pressed(GLOBAL.INPUT.MAP["ESC"])):
			Caller._hide_lineEdit("goto", UIElement.GotoEdit)
			StateMaster.set_default_state()

### ----------------------------------------------------
# Signals
### ----------------------------------------------------

func _on_ItemList_item_selected(index:int) -> void:
	EditorStateMachine.redirect_signal("TM_STATE", "switch_tile_selection", [index])

func _on_TMSelect_item_selected(index:int) -> void:
	EditorStateMachine.redirect_signal("TM_STATE", "switch_TM_selection", [index])

func _on_Filter_text_entered(new_text: String) -> void:
	TileSelect.filter = new_text
	_hide_lineEdit(UIElement.FilterEdit)
	UIElement.Filter.text = "Filter: " + "\"" + TileSelect.filter + "\""
	EditorStateMachine.force_call("TM_STATE", "switch_TM_selection", [0])

func _on_SaveEdit_text_entered(mapName:String) -> void:
	if(not EditedMap.save(SaveManager.MAP_FOLDER + mapName + ".db")):
		Logger.logErr(["Failed to save: ", mapName], get_stack())
	_hide_lineEdit(UIElement.SaveEdit)

func _on_LoadEdit_text_entered(MapName: String) -> void:
	var Temp := SQLSave.new(MapName, SaveManager.MAP_FOLDER)
	if(Temp.load(TileSelect.allTileMaps)):
		EditedMap = Temp
	else:
		Logger.logErr(["Failed to load: ", MapName], get_stack())
	
	$TileMapManager.unload_all_chunks()
	_hide_lineEdit(UIElement.LoadEdit)

func _on_GOTO_text_entered(new_text: String) -> void:
	var coords:Array = new_text.split(" ")
	if(not coords.size() >= 2): return
	if(not coords[0].is_valid_integer() and coords[1].is_valid_integer()):
		return
	
	var x:int = int(coords[0]) * GLOBAL.TILEMAPS.BASE_SCALE
	var y:int = int(coords[1]) * GLOBAL.TILEMAPS.BASE_SCALE
	$Cam.global_position = Vector2(x,y)
	
	_hide_lineEdit(UIElement.GotoEdit)

### ----------------------------------------------------
# Update chunks
### ----------------------------------------------------

# Renders chunks as in normal game based on camera position (as simulated entity)
func update_EditedMap_chunks() -> void:
	var camChunk := LibK.Vectors.scale_down_vec2($Cam.global_position, GLOBAL.TILEMAPS.CHUNK_SIZE*GLOBAL.TILEMAPS.BASE_SCALE)
	var chunksToRender := LibK.Vectors.vec3_get_range_2d(LibK.Vectors.vec2_vec3(camChunk, $Cam.currentElevation), 1)

	# Loading chunks that are not yet rendered
	for chunkV3 in chunksToRender:
		if($TileMapManager.RenderedChunks.has(chunkV3)): continue
		$TileMapManager.load_chunk_to_tilemap(chunkV3, 
			EditedMap.get_TileData_on_chunk(chunkV3, GLOBAL.TILEMAPS.CHUNK_SIZE))
	
	# Unload old chunks that are not meant to be seen
	for i in range($TileMapManager.RenderedChunks.size() - 1, -1, -1):
		var chunkV3:Vector3 = $TileMapManager.RenderedChunks[i]
		if(chunksToRender.has(chunkV3)): continue
		$TileMapManager.RenderedChunks.remove(i)
		$TileMapManager.unload_chunk_from_tilemap(chunkV3)
	
	$TileMapManager.update_all_TM_bitmask()

### ----------------------------------------------------
# MISC
### ----------------------------------------------------

func _show_lineEdit(LENode:Control) -> void:
	$Cam.inputActive = false
	LENode.show()
	LENode.grab_focus()

func _hide_lineEdit(LENode:Control) -> void:
	$Cam.inputActive = true
	LENode.hide()
