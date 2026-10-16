class_name CardArt
extends RefCounted
## Découpe la planche « Carte et icône.png » en textures réutilisables :
## le cadre de carte et les icônes de statistiques (PV, puissance,
## vitesse, défense).

const SHEET: Texture2D = preload("res://Carte et icône.png")

## Zone du cadre de carte dans la planche (en pixels).
const FRAME_REGION := Rect2(196, 110, 606, 786)

## Zones des icônes dans la planche (en pixels).
const ICON_REGIONS := {
	&"hp": Rect2(816, 718, 160, 148),
	&"power": Rect2(844, 388, 104, 114),
	&"speed": Rect2(22, 752, 190, 134),
	&"defense": Rect2(820, 542, 158, 160),
}

## Bandeaux gris du cadre, en fractions du cadre (gauche, haut, droite, bas).
const BAR_NAME := Rect2(0.081, 0.073, 0.836, 0.159)
const BAR_RARITY := Rect2(0.081, 0.267, 0.836, 0.159)
const ART_AREA := Rect2(0.081, 0.43, 0.836, 0.36)
const BAR_STATS := Rect2(0.081, 0.794, 0.836, 0.159)

static var _cache: Dictionary = {}


static func frame() -> AtlasTexture:
	return _atlas(&"frame", FRAME_REGION)


static func icon(stat: StringName) -> AtlasTexture:
	return _atlas(stat, ICON_REGIONS.get(stat, Rect2()))


static func _atlas(key: StringName, region: Rect2) -> AtlasTexture:
	if _cache.has(key):
		return _cache[key]
	var tex := AtlasTexture.new()
	tex.atlas = SHEET
	tex.region = region
	_cache[key] = tex
	return tex


## Place un Control sur une zone exprimée en fractions de son parent.
static func place(control: Control, area: Rect2) -> void:
	control.anchor_left = area.position.x
	control.anchor_top = area.position.y
	control.anchor_right = area.position.x + area.size.x
	control.anchor_bottom = area.position.y + area.size.y
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0
