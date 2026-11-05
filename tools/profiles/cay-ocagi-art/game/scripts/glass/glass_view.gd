class_name GlassView
extends Node2D
## One tea glass from the Çay Ocağı art kit, drawn the way the trailer draws it:
## saucer · back tint · liquid layers clipped to the glass (with cylinder
## shading and optional colour-blind symbols) · outline and highlights.
##
## Origin = bottom centre of the glass (stand it on the counter there).
## Size with glass_width (px). Layers bottom → top as drink indices 0..7
## (see DRINKS). While the glass tilts (pouring), the liquid stays level.
##
##   var g := GlassView.new()
##   g.glass_width = 96
##   add_child(g)
##   g.set_layers([0, 4, 4])         # demli, kuşburnu, kuşburnu
##   g.top_fill = 0.5                 # top layer half poured (animations)

## Drink index → [token, colour-blind symbol, light drink?]
const DRINKS := [
	[&"drink_demli", "leaf", false],
	[&"drink_acik", "drop", true],
	[&"drink_ihlamur", "flower", true],
	[&"drink_adacayi", "sprig", false],
	[&"drink_kusburnu", "heart", false],
	[&"drink_elma", "apple", false],
	[&"drink_sahlep", "star", true],
	[&"drink_kahve", "bean", false],
]
const CAPACITY := 4

# Geometry of the kit's glass SVGs (220×480 canvas, glass 200×460, bottom
# centre at (110, 470)) and the trailer's liquid proportions.
const DESIGN_W := 200.0
const DESIGN_H := 460.0
const CANVAS_OFFSET := Vector2(0.0, -230.0)
const LIQUID_BOTTOM := 0.05
const UNIT := 0.82 / 4.0
const ASSETS := "res://assets/"

@export var glass_width: float = 100.0:
	set(value):
		glass_width = maxf(1.0, value)
		scale = Vector2.ONE * glass_width / DESIGN_W
@export var symbols_visible: bool = false:
	set(value):
		symbols_visible = value
		_refresh()
@export var show_saucer: bool = true:
	set(value):
		show_saucer = value
		if _saucer != null:
			_saucer.visible = value

## How full the top layer is, 0..1 (pour animations). Other layers are full.
var top_fill: float = 1.0:
	set(value):
		top_fill = clampf(value, 0.0, 1.0)
		_refresh()

var layers: Array[int] = []

var _saucer: Sprite2D
var _liquid: Node2D
var _bands: Array[ColorRect] = []
var _symbols: Array[Sprite2D] = []


func _ready() -> void:
	scale = Vector2.ONE * glass_width / DESIGN_W
	_saucer = _sprite("glass/saucer.svg", Vector2.ZERO)
	_saucer.visible = show_saucer
	add_child(_saucer)
	add_child(_sprite("glass/glass_back.svg", CANVAS_OFFSET))
	var mask := _sprite("glass/glass_mask.svg", CANVAS_OFFSET)
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	add_child(mask)
	_liquid = Node2D.new()
	_liquid.position = -CANVAS_OFFSET   # back to the glass bottom centre
	mask.add_child(_liquid)
	mask.add_child(_sprite("glass/glass_shade.svg", Vector2.ZERO))
	add_child(_sprite("glass/glass_front.svg", CANVAS_OFFSET))
	_refresh()


func _process(_delta: float) -> void:
	# Keep the liquid level while the glass rotates: counter-rotate the
	# liquid and squash band heights by cos(angle), as the trailer does.
	if _liquid == null:
		return
	_liquid.rotation = -rotation
	_layout_bands(cos(rotation))


func set_layers(drinks: Array) -> void:
	layers.clear()
	for d in drinks:
		layers.append(clampi(int(d), 0, DRINKS.size() - 1))
	_refresh()


func is_full_single_colour() -> bool:
	if layers.size() != CAPACITY:
		return false
	for d in layers:
		if d != layers[0]:
			return false
	return true


## World position of the liquid surface's centre (pour stream target).
func surface_global_position() -> Vector2:
	var level := (LIQUID_BOTTOM + (layers.size() - 1 + top_fill) * UNIT) * DESIGN_H if not layers.is_empty() else LIQUID_BOTTOM * DESIGN_H
	return to_global(Vector2(0.0, -level))


## World position of the glass rim's centre.
func rim_global_position() -> Vector2:
	return to_global(Vector2(0.0, -DESIGN_H))


func _sprite(path: String, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	var full := ASSETS + path
	if ResourceLoader.exists(full):
		s.texture = load(full)
	else:
		push_warning("GlassView: %s missing — run bash tools/svg-build.sh" % full)
	s.position = pos
	return s


func _refresh() -> void:
	if _liquid == null:
		return
	while _bands.size() < layers.size():
		var band := ColorRect.new()
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sym := Sprite2D.new()
		_liquid.add_child(band)
		_liquid.add_child(sym)
		_bands.append(band)
		_symbols.append(sym)
	for i in _bands.size():
		var used := i < layers.size()
		_bands[i].visible = used
		_symbols[i].visible = used and symbols_visible
		if not used:
			continue
		var drink: Array = DRINKS[layers[i]]
		_bands[i].color = DesignTokens.color(drink[0])
		var tex_path := "%ssymbols/sym_%s.svg" % [ASSETS, drink[1]]
		if ResourceLoader.exists(tex_path):
			_symbols[i].texture = load(tex_path)
		_symbols[i].modulate = DesignTokens.color(&"sym_on_light" if drink[2] else &"sym_on_dark")
	_layout_bands(cos(rotation))


func _layout_bands(squash: float) -> void:
	var unit_h := UNIT * DESIGN_H
	var bottom := LIQUID_BOTTOM * DESIGN_H
	for i in layers.size():
		if i >= _bands.size():
			break
		var amount := top_fill if i == layers.size() - 1 else 1.0
		var y_top := -(bottom + (i + amount) * unit_h) * squash
		var y_bot := -(bottom + i * unit_h) * squash
		if i == 0:
			y_bot = 20.0   # under the glass bottom; the mask trims it
		_bands[i].position = Vector2(-DESIGN_W, y_top)
		_bands[i].size = Vector2(DESIGN_W * 2.0, y_bot - y_top + 1.0)
		var sym_size := minf(unit_h * 0.62, DESIGN_W * 0.34)
		_symbols[i].position = Vector2(0.0, (y_top + y_bot) * 0.5 if i > 0 else -(bottom + (i + amount * 0.5) * unit_h) * squash)
		_symbols[i].scale = Vector2.ONE * sym_size / 100.0
		_symbols[i].rotation = 0.0
		_symbols[i].visible = symbols_visible and amount > 0.3
