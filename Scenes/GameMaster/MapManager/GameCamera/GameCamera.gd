### ----------------------------------------------------
### Controls camera
### ----------------------------------------------------

extends Camera2D

### ----------------------------------------------------
# VARIABLES
### ----------------------------------------------------

### ----------------------------------------------------
# FUNCTIONS
### ----------------------------------------------------

func _on_PlayerMoved(pos:Vector2) -> void:
	self.position = pos
	