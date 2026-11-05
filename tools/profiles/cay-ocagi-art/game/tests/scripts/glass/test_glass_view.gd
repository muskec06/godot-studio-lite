extends GdUnitTestSuite
## GlassView: layers, colours from the design tokens, symbols, sizing.


func _glass() -> GlassView:
	var g: GlassView = auto_free(GlassView.new())
	add_child(g)
	return g


func test_width_sets_scale() -> void:
	var g := _glass()
	g.glass_width = 50.0
	assert_float(g.scale.x).is_equal_approx(0.25, 0.0001)


func test_layers_use_token_colours() -> void:
	var g := _glass()
	g.set_layers([0, 4])
	assert_int(g.layers.size()).is_equal(2)
	assert_bool(g._bands[0].color.is_equal_approx(DesignTokens.color(&"drink_demli"))).is_true()
	assert_bool(g._bands[1].color.is_equal_approx(DesignTokens.color(&"drink_kusburnu"))).is_true()


func test_layers_stack_upwards() -> void:
	var g := _glass()
	g.set_layers([1, 2, 3])
	assert_float(g._bands[1].position.y).is_less(g._bands[0].position.y)
	assert_float(g._bands[2].position.y).is_less(g._bands[1].position.y)


func test_symbols_follow_toggle() -> void:
	var g := _glass()
	g.set_layers([6, 7])
	assert_bool(g._symbols[0].visible).is_false()
	g.symbols_visible = true
	assert_bool(g._symbols[0].visible).is_true()
	# light drink (sahlep) gets the dark symbol colour
	assert_bool(g._symbols[0].modulate.is_equal_approx(DesignTokens.color(&"sym_on_light"))).is_true()


func test_full_single_colour() -> void:
	var g := _glass()
	g.set_layers([3, 3, 3, 3])
	assert_bool(g.is_full_single_colour()).is_true()
	g.set_layers([3, 3, 3])
	assert_bool(g.is_full_single_colour()).is_false()


func test_unused_bands_hide_when_layers_shrink() -> void:
	var g := _glass()
	g.set_layers([0, 0, 0])
	g.set_layers([0])
	assert_bool(g._bands[1].visible).is_false()
