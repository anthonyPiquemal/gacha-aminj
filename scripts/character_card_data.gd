class_name CharacterCardData
extends Resource

enum Rarity {
	C,
	R,
	SR,
	SSR,
	UR,
}

enum ActionType {
	FRAPPER,
	SOIGNER,
	BUFFER,
	IMMO,
}


@export_group("Identité")
@export var id: StringName = &""
@export var display_name: String = "Personnage"
@export var portrait: Texture2D
@export var rarity: Rarity = Rarity.C
@export_multiline var description: String = ""


@export_group("Statistiques")
@export_range(1, 99999) var hp: int = 100
@export_range(1, 99999) var power: int = 10
@export_range(1, 99999) var speed: int = 10
@export_range(0, 99999) var defense: int = 5


@export_group("Compétence 1")
@export var skill_1_name: String = "Attaque"
@export_multiline var skill_1_description: String = ""
@export var skill_1_action: ActionType = ActionType.FRAPPER

## Délai de réutilisation en tours.
@export_range(0, 99) var skill_1_cooldown: int = 0

## Multiplicateur appliqué par la future logique de combat.
@export_range(0.0, 100.0, 0.05) var skill_1_multiplier: float = 1.0


@export_group("Compétence 2")
@export var skill_2_name: String = "Compétence spéciale"
@export_multiline var skill_2_description: String = ""
@export var skill_2_action: ActionType = ActionType.FRAPPER

## Délai de réutilisation en tours.
@export_range(0, 99) var skill_2_cooldown: int = 3

## Multiplicateur appliqué par la future logique de combat.
@export_range(0.0, 100.0, 0.05) var skill_2_multiplier: float = 1.5


func rarity_name() -> String:
	match rarity:
		Rarity.C:
			return "Common"
		Rarity.R:
			return "Rare"
		Rarity.SR:
			return "Super Rare"
		Rarity.SSR:
			return "Super Super Rare"
		Rarity.UR:
			return "Ultra Rare"
		_:
			return "?"


func rarity_color() -> Color:
	match rarity:
		Rarity.C:
			return Color("#bac4d0")
		Rarity.R:
			return Color("#65baff")
		Rarity.SR:
			return Color("#c48aff")
		Rarity.SSR:
			return Color("#ffd166")
		Rarity.UR:
			return Color("#ff758f")
		_:
			return Color.WHITE
