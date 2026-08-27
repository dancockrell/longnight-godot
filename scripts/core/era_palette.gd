class_name EraPalette
extends RefCounted

## One place this game gets its visual identity from, so every screen reads
## the same way for the same place. Concept doc (docs/CONCEPT.md): Camp Iron
## Bell should feel like humming fluorescent paperwork; Whitechapel should
## feel like cold, fog and gaslight. Two palettes, not a generic dark theme
## reused everywhere, is the cheapest way to make two screens feel like two
## different places rather than two screens.

class Palette extends RefCounted:
	var bg: Color
	var paper: Color
	var ink: Color
	var dim: Color
	var stamp: Color       ## Headers, the accent colour unique to this place.
	var rule: Color        ## Hairlines and dividers.
	var hum_hz: float      ## 0 = silent. See scripts/core/ambience.gd.
	var noise_amount: float


static func camp_iron_bell() -> Palette:
	var p := Palette.new()
	# Recruitment-poster stock, per LORE-BIBLE.md section 6: cream newsprint,
	# flag red, navy, effects in electric cyan-white, "like a photograph
	# taken with too much flash." Read here through a night-shift lens
	# instead of daylight poster art, because the player is always at Iron
	# Bell after hours.
	p.bg = Color("#0c0f14")
	p.paper = Color("#171c24")
	p.ink = Color("#e7ecf2")
	p.dim = Color("#7c8b9c")
	p.stamp = Color("#8fd4e8")      # electric cyan-white
	p.rule = Color("#2a3644")
	p.hum_hz = 60.0                 # the bible's own spec: a mains hum bed
	p.noise_amount = 0.02
	return p


static func london_1888() -> Palette:
	var p := Palette.new()
	# No bible entry for this era's palette - Long Night predates the
	# Werk Nachtigall / Hyakki Yakō treaty era the bible's art direction
	# covers. Built to the concept doc's own brief: cold, fog, gaslight.
	p.bg = Color("#0e1013")
	p.paper = Color("#1a1d22")
	p.ink = Color("#dcd6c8")
	p.dim = Color("#7d7869")
	p.stamp = Color("#c9a227")      # gaslight amber, matches the old canvas game's P.gold
	p.rule = Color("#33322c")
	p.hum_hz = 0.0                  # no mains hum in 1888; fog instead
	p.noise_amount = 0.05
	return p


static func for_era(era_id: String) -> Palette:
	match era_id:
		"london_1888":
			return london_1888()
		_:
			return camp_iron_bell()
