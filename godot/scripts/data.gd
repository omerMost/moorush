class_name MooData
extends RefCounted
## Chapter data copied from prototype/index.html (the frozen spec).
## STAGES[0] = Farm Kid (L104-128), PM/TUNE price rescale (L301-307).
## Out of scope for the slice: the V (vehicle shop), W (armory) and K (bank)
## modules keep their cells (they shape the revealed world) but have no pads yet.

const TUNE := [1, 1.4, 0.9, 0.8, 1.15, 2.5, 1.4, 1.55, 2.0]
const PM := [1, 2, 4, 10, 25, 60, 150, 400, 1000]

const RANKS := ["👦", "🧑‍🌾", "🧑‍🍳", "🛒", "🏭", "🏛️", "🗺️", "⚖️", "🇺🇸"]
const TITLES := ["Farm Kid", "Farmer", "Baker", "Store Owner", "Tycoon", "Mayor", "Governor", "Senator", "Candidate"]

static func stage0() -> Dictionary:
	var st := {
		"title": "Farm Kid", "rank": "👦",
		"intro": "Grandpa left you a corn patch and three cows. Sell milk and eggs until you can buy the dairy next door.",
		"mods": [
			{"id": "A", "c": 0, "r": 1, "type": "field", "item": "corn", "name": "Corn field"},
			{"id": "B", "c": 1, "r": 1, "type": "machine", "name": "Cow barn", "in": "corn", "out": "milk", "kind": "cow", "n": 3, "period": 4.0},
			{"id": "C", "c": 0, "r": 2, "type": "counter", "name": "Milk stand", "item": "milk", "price": 4},
			{"id": "D", "c": 1, "r": 0, "type": "machine", "name": "Chicken coop", "in": "corn", "out": "egg", "kind": "hen", "n": 3, "period": 3.2, "locked": 1},
			{"id": "E", "c": 0, "r": 0, "type": "counter", "name": "Egg stand", "item": "egg", "price": 6, "locked": 1},
			{"id": "G", "c": 2, "r": 1, "type": "gate"},
			{"id": "V", "c": 1, "r": 2, "type": "garage", "name": "Vehicle shop"},
			{"id": "W", "c": 2, "r": 2, "type": "armory", "name": "Farm armory"},
			{"id": "K", "c": 2, "r": 0, "type": "bank", "name": "Bank"},
		],
		"pads": [
			{"m": "B", "s": 0, "fx": "feed", "cost": 50, "name": "Corn conveyor", "icon": "⚙️"},
			{"m": "A", "s": 0, "fx": "cap", "v": 12, "cost": 80, "name": "Bigger arms", "icon": "💪"},
			{"m": "B", "s": 1, "fx": "more", "v": 2, "cost": 120, "name": "+2 cows", "icon": "🐄"},
			{"fx": "unlock", "t": "D", "cost": 150, "name": "Chicken coop", "icon": "🐔"},
			{"fx": "unlock", "t": "E", "cost": 100, "name": "Egg stand", "icon": "🥚"},
			{"m": "C", "s": 0, "fx": "helper", "f": "B", "t": "C", "cost": 200, "name": "Milk runner", "icon": "🧑‍🌾"},
			{"m": "D", "s": 0, "fx": "helper", "f": "A", "t": "D", "cost": 220, "name": "Corn picker", "icon": "👨‍🌾"},
			{"m": "C", "s": 1, "fx": "price", "v": 1.5, "cost": 250, "name": "Fancy bottles", "icon": "✨"},
			{"m": "E", "s": 0, "fx": "helper", "f": "D", "t": "E", "cost": 260, "name": "Egg runner", "icon": "🧑‍🌾"},
			{"m": "G", "fx": "gate", "cost": 800, "name": "Buy the dairy", "icon": "🏡"},
		],
	}
	_rescale(st, 0)
	return st

## nice(): prototype L303 — round to 2 significant digits above 100.
static func nice(v: float) -> int:
	if v < 100.0:
		return int(round(v))
	var p := pow(10.0, floor(log(v) / log(10.0)) - 1.0)
	return int(round(v / p) * p)

static func _rescale(st: Dictionary, i: int) -> void:
	for m in st.mods:
		if m.type == "counter" and str(m.get("pay", "coin")) == "coin":
			m.price = nice(m.price * PM[i])
	for p in st.pads:
		if p.get("cur", "") == "vote":
			continue
		p.cost = nice(p.cost * TUNE[i] * PM[i])

## ITEMS (prototype L404-409): pile spacing dx/dy, layer height h, stack height sh.
const ITEMS := {
	"corn": {"dx": 22, "dy": 10, "h": 7, "sh": 7, "e": "🌽"},
	"milk": {"dx": 16, "dy": 13, "h": 15, "sh": 15, "e": "🥛"},
	"egg": {"dx": 14, "dy": 11, "h": 9, "sh": 10, "e": "🥚"},
	"coin": {"dx": 18, "dy": 10, "h": 4, "sh": 4, "e": "🪙"},
}

const HAPPY_LINES := ["Moo-velous!", "Worth every coin!", "Yum yum!", "Best farm ever!", "I'll be back!", "5 stars!", "Delicious!", "My grandma loves this"]
const LOST_LINES := ["Too slow! Bye!", "Hmph!", "Worst service ever"]
const SHIRTS := ["#c0504d", "#3b6ea5", "#6a4c93", "#2e8b57", "#d17a22", "#8e44ad", "#2c7da0", "#b5485d"]
const PANTS := ["#2f4b7c", "#3d3d5c", "#4a5a8a", "#5b4636"]
const SKINS := ["#f1c27d", "#e0ac69", "#c68642", "#8d5524", "#ffdbac"]
const HAIRS := ["#5a3825", "#2b1b10", "#a0522d", "#1b1b1b", "#d9a441"]
const PLAYER_LOOK := {"shirt": "#fbfbf7", "vest": "#d23b2e", "pants": "#4a6fa5", "skin": "#f6cfa8", "hair": "#e0702a", "bun": true}
const HELPER_LOOKS := [
	{"shirt": "#3e8e5a", "pants": "#5b4636", "skin": "#c68642", "hair": "#2b1b10", "cap": "#2f6fd6"},
	{"shirt": "#e0a030", "pants": "#3d3d5c", "skin": "#f1c27d", "hair": "#5a3825", "cap": "#c0392b"},
	{"shirt": "#6a4c93", "pants": "#2f4b7c", "skin": "#8d5524", "hair": "#1b1b1b", "cap": "#2e8b57"},
]
