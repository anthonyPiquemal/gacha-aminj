class_name CardLibrary
extends RefCounted
## Les cartes AMINJ du jeu (images dans assets/cartes/).
## Les PV, dégâts et soins sont ceux écrits sur les cartes. La recharge des
## cartes est en secondes : en combat elle devient des tours (1 tour ≈ 4 s,
## arrondi au supérieur : 5 s → 2, 10-12 s → 3, 20 s → 5).
## La puissance (attaque de base) n'est pas sur les cartes : choisie ici.

const SECONDS_PER_TURN := 4.0


static func seconds_to_turns(seconds: float) -> int:
	return maxi(1, ceili(seconds / SECONDS_PER_TURN))


## Nouvelle copie des 5 cartes (chaque appel crée des CardData neuves).
static func aminj_cards() -> Array[CardData]:
	return [
		CardData.create("Davidou", 8, 130, Color("6a8aff"))
				.with_art(load("res://assets/cartes/carte1.png"))
				.with_style(CardData.AttackStyle.MAGIC)
				.with_skill(SkillSupport.create_support("Soin au beurre salé", seconds_to_turns(12),
						SkillSupport.SupportType.BUFF, SkillSupport.Stat.HEALTH, 25)),
		CardData.create("Louis", 14, 90, Color("ff8a70"))
				.with_art(load("res://assets/cartes/carte2.png"))
				.with_style(CardData.AttackStyle.SWORD)
				.with_skill(SkillAttack.create_flat("Inventaire", seconds_to_turns(10), 32)),
		CardData.create("Aëlig", 11, 150, Color("ffab70"))
				.with_art(load("res://assets/cartes/carte3.png"))
				.with_style(CardData.AttackStyle.SMASH)
				.with_skill(SkillStun.create_stun("Giffle de Guacamole", seconds_to_turns(5))),
		CardData.create("Hòa", 12, 100, Color("ffe870"))
				.with_art(load("res://assets/cartes/carte4.png"))
				.with_style(CardData.AttackStyle.DAGGER)
				.with_skill(SkillAttack.create_flat("Mu bàn chân", seconds_to_turns(5), 20)),
		CardData.create("Marieme", 15, 80, Color("6ae8ff"))
				.with_art(load("res://assets/cartes/carte5.png"))
				.with_style(CardData.AttackStyle.SWORD)
				.with_skill(SkillAttack.create_flat("Sabre", seconds_to_turns(20), 40)),
	]
