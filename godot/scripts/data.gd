class_name MooData
extends RefCounted
## Chapter data copied from prototype/index.html (the frozen spec).
## STAGES[0..2] = Farm Kid, Farmer and Baker, with PM/TUNE price rescale.
## Out of scope for the slice: the V (vehicle shop), W (armory) and K (bank)
## modules keep their cells (they shape the revealed world) but have no pads yet.

const TUNE := [1, 1.4, 0.9, 0.8, 1.15, 2.5, 1.4, 1.55, 2.0]
const PM := [1, 2, 4, 10, 25, 60, 150, 400, 1000]
const STAGE_COUNT := 3

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

static func stage1() -> Dictionary:
	var st := {
		"title": "Farmer", "rank": "🧑‍🌾",
		"intro": "The dairy is yours. Press milk into cheese — it sells for a lot more.",
		"mods": [
			{"id": "A", "c": 0, "r": 1, "type": "field", "item": "corn", "name": "Corn field"},
			{"id": "B", "c": 1, "r": 1, "type": "machine", "name": "Dairy barn", "in": "corn", "out": "milk", "kind": "cow", "n": 3, "period": 4.0},
			{"id": "C", "c": 1, "r": 0, "type": "machine", "name": "Cheese press", "in": "milk", "out": "cheese", "kind": "station", "icon": "⚙️", "color": "#d9a441", "n": 1, "period": 3.0},
			{"id": "D", "c": 2, "r": 0, "type": "counter", "name": "Cheese shop", "item": "cheese", "price": 14},
			{"id": "E", "c": 1, "r": 2, "type": "machine", "name": "Big coop", "in": "corn", "out": "egg", "kind": "hen", "n": 4, "period": 3.0, "locked": 1},
			{"id": "F", "c": 0, "r": 2, "type": "counter", "name": "Egg stand", "item": "egg", "price": 8, "locked": 1},
			{"id": "G", "c": 2, "r": 1, "type": "gate"},
		],
		"pads": [
			{"m": "B", "s": 0, "fx": "feed", "cost": 150, "name": "Corn conveyor", "icon": "⚙️"},
			{"m": "A", "s": 0, "fx": "cap", "v": 14, "cost": 200, "name": "Stronger arms", "icon": "💪"},
			{"m": "C", "s": 0, "fx": "helper", "f": "B", "t": "C", "cost": 300, "name": "Dairy hand", "icon": "🧑‍🌾"},
			{"m": "C", "s": 1, "fx": "more", "v": 1, "cost": 350, "name": "Second press", "icon": "⚙️"},
			{"m": "B", "s": 1, "fx": "more", "v": 2, "cost": 450, "name": "+2 cows", "icon": "🐄"},
			{"fx": "unlock", "t": "E", "cost": 450, "name": "Big coop", "icon": "🐔"},
			{"fx": "unlock", "t": "F", "cost": 250, "name": "Egg stand", "icon": "🥚"},
			{"m": "E", "s": 0, "fx": "helper", "f": "A", "t": "E", "cost": 350, "name": "Corn picker", "icon": "👨‍🌾"},
			{"m": "D", "s": 0, "fx": "helper", "f": "C", "t": "D", "cost": 500, "name": "Shop clerk", "icon": "🧑‍💼"},
			{"m": "F", "s": 0, "fx": "helper", "f": "E", "t": "F", "cost": 450, "name": "Egg runner", "icon": "🧑‍🌾"},
			{"m": "D", "s": 1, "fx": "price", "v": 1.5, "cost": 600, "name": "Aged cheese", "icon": "✨"},
			{"m": "G", "fx": "gate", "cost": 3000, "name": "Open a bakery", "icon": "🥖"},
		],
	}
	# Night taco production is deferred with the day/night and combat systems.
	_rescale(st, 1)
	return st

static func stage2() -> Dictionary:
	var st := {
		"title": "Baker", "rank": "🧑‍🍳",
		"intro": "The whole town lines up for your bread. Plant an orchard and bake apple pies too.",
		"mods": [
			{"id": "A", "c": 0, "r": 1, "type": "field", "item": "wheat", "name": "Wheat field"},
			{"id": "B", "c": 1, "r": 1, "type": "machine", "name": "Bread ovens", "in": "wheat", "out": "bread", "kind": "station", "icon": "🔥", "color": "#b5543a", "n": 2, "period": 3.0},
			{"id": "C", "c": 2, "r": 1, "type": "counter", "name": "Bread counter", "item": "bread", "price": 12},
			{"id": "D", "c": 0, "r": 2, "type": "field", "item": "apple", "name": "Apple orchard", "locked": 1},
			{"id": "E", "c": 1, "r": 2, "type": "machine", "name": "Pie ovens", "in": "apple", "out": "pie", "kind": "station", "icon": "🔥", "color": "#b5543a", "n": 2, "period": 3.5, "locked": 1},
			{"id": "F", "c": 2, "r": 2, "type": "counter", "name": "Pie counter", "item": "pie", "price": 22, "locked": 1},
			{"id": "G", "c": 1, "r": 0, "type": "gate"},
		],
		"pads": [
			{"m": "A", "s": 0, "fx": "cap", "v": 16, "cost": 500, "name": "Baker arms", "icon": "💪"},
			{"m": "B", "s": 0, "fx": "feed", "cost": 600, "name": "Wheat conveyor", "icon": "⚙️"},
			{"m": "B", "s": 1, "fx": "more", "v": 2, "cost": 800, "name": "+2 ovens", "icon": "🔥"},
			{"m": "C", "s": 0, "fx": "helper", "f": "B", "t": "C", "cost": 900, "name": "Bread runner", "icon": "🧑‍🍳"},
			{"fx": "unlock", "t": "D", "cost": 1000, "name": "Apple orchard", "icon": "🍎"},
			{"fx": "unlock", "t": "E", "cost": 800, "name": "Pie ovens", "icon": "🥧"},
			{"fx": "unlock", "t": "F", "cost": 600, "name": "Pie counter", "icon": "🧁"},
			{"m": "E", "s": 0, "fx": "feed", "cost": 1100, "name": "Apple conveyor", "icon": "⚙️"},
			{"m": "F", "s": 0, "fx": "helper", "f": "E", "t": "F", "cost": 1200, "name": "Pie runner", "icon": "🧑‍🍳"},
			{"m": "C", "s": 1, "fx": "price", "v": 1.5, "cost": 1200, "name": "Sourdough", "icon": "✨"},
			{"m": "E", "s": 1, "fx": "more", "v": 2, "cost": 1400, "name": "+2 pie ovens", "icon": "🔥"},
			{"m": "G", "fx": "gate", "cost": 7000, "name": "Open a supermarket", "icon": "🛒"},
		],
	}
	_rescale(st, 2)
	return st

static func stage_at(index: int) -> Dictionary:
	match index:
		0:
			return stage0()
		1:
			return stage1()
		2:
			return stage2()
		_:
			return {}

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
	"cheese": {"dx": 24, "dy": 17, "h": 12, "sh": 14, "e": "🧀"},
	"wheat": {"dx": 20, "dy": 13, "h": 12, "sh": 14, "e": "🌾"},
	"bread": {"dx": 20, "dy": 13, "h": 9, "sh": 11, "e": "🍞"},
	"apple": {"dx": 20, "dy": 13, "h": 10, "sh": 12, "e": "🍎"},
	"pie": {"dx": 20, "dy": 13, "h": 7, "sh": 9, "e": "🥧"},
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
