extends Resource
class_name Upgrade

@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var button_text_color: Color = Color.WHITE 
@export var button_text_border_color: Color = Color.BLACK 
@export var rarity: rarities.Rarity = rarities.Rarity.COMMON
# override this in each upgrade
func apply(player: CharacterBody2D):
	pass
