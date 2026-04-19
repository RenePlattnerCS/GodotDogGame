extends Node

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

const RARITY_WEIGHTS = {
	Rarity.COMMON: 1.0,
	Rarity.UNCOMMON: 0.5,
	Rarity.RARE: 0.2,
	Rarity.LEGENDARY: 0.05
}
