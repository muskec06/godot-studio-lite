extends SceneTree
## Headless image processing for generated 2D assets. Uses only Godot's Image
## class, so no Python or ImageMagick is needed. Installed by
## tools/setup-godot.sh to res://addons/gsl_tools/.
##
##   godot --headless --path game -s res://addons/gsl_tools/image_tool.gd -- <command> <args>
##
## All paths are absolute file paths (not res://).
##
## Commands
##   info     <in>
##   trim     <in> <out> [pad]                crop to non-transparent pixels, keep pad px
##   pixelate <in> <out> <height> [palette.hex] [alpha_cut]
##            downscale so the image is <height> px tall (area average), snap alpha
##            to 0/255 at alpha_cut (default 0.5), map colours to the palette if given
##   palette  <in> <out> <palette.hex>       map every colour to the nearest palette colour
##   scale    <in> <out> <factor>            nearest-neighbour upscale (previews)
##   fit      <in> <out> <width> <height>    resize (Lanczos) to exactly width × height
##   slice    <in> <out_prefix> <cols> <rows> split a sheet into frames: <prefix>_00.png …
##   extract  <in> <out.hex> [colours]       derive a palette (k-means, default 16 colours)
##                                           from an approved style image
##   svg      <in.svg> <out.png> [width]     rasterize with Godot's SVG renderer
##                                           (ThorVG); width 0 = the SVG's own width
##   cvd      <in> <out_prefix>              colour-vision-deficiency previews:
##                                           <prefix>_protan.png, _deutan.png, _tritan.png
##   cvdcheck <palette.hex> [min_delta_e]    colour pairs that become hard to tell
##                                           apart (CIE76 ΔE below min, default 15)
##                                           for normal vision and each deficiency
##
## CVD simulation: Machado, Oliveira & Fernandes (2009), severity 1.0, applied
## in linear RGB.
##
## A .hex palette is one RRGGBB per line (the Lospec download format).
## Exit 0 = done · 1 = failed · 2 = bad arguments.


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.is_empty():
		_fail(2, "image_tool: no command. See the header of image_tool.gd.")
		return
	var cmd := a[0]
	var code := 2
	match cmd:
		"info":
			code = _info(a)
		"trim":
			code = _trim(a)
		"pixelate":
			code = _pixelate(a)
		"palette":
			code = _palette_cmd(a)
		"scale":
			code = _scale(a)
		"fit":
			code = _fit(a)
		"slice":
			code = _slice(a)
		"extract":
			code = _extract(a)
		"svg":
			code = _svg(a)
		"cvd":
			code = _cvd(a)
		"cvdcheck":
			code = _cvdcheck(a)
		_:
			printerr("image_tool: unknown command ", cmd)
	quit(code)


func _fail(code: int, msg: String) -> void:
	printerr(msg)
	quit(code)


func _load(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		printerr("image_tool: cannot read ", path)
		return null
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _save(img: Image, path: String) -> int:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := img.save_png(path)
	if err != OK:
		printerr("image_tool: cannot write ", path, " (error ", err, ")")
		return 1
	print("wrote ", path, " ", img.get_width(), "x", img.get_height())
	return 0


func _info(a: PackedStringArray) -> int:
	if a.size() < 2:
		return 2
	var img := _load(a[1])
	if img == null:
		return 1
	var used := img.get_used_rect()
	print("size ", img.get_width(), "x", img.get_height(), " used_rect ", used, " colours ", _count_colours(img))
	return 0


func _trim(a: PackedStringArray) -> int:
	if a.size() < 3:
		return 2
	var img := _load(a[1])
	if img == null:
		return 1
	var pad := a[3].to_int() if a.size() > 3 else 0
	var used := img.get_used_rect()
	if used.size.x == 0 or used.size.y == 0:
		printerr("image_tool: image is fully transparent")
		return 1
	var out := Image.create_empty(used.size.x + pad * 2, used.size.y + pad * 2, false, Image.FORMAT_RGBA8)
	out.blit_rect(img, used, Vector2i(pad, pad))
	return _save(out, a[2])


func _pixelate(a: PackedStringArray) -> int:
	if a.size() < 4:
		return 2
	var img := _load(a[1])
	if img == null:
		return 1
	var target_h := a[3].to_int()
	if target_h < 1:
		return 2
	var target_w := maxi(1, int(round(float(img.get_width()) * target_h / img.get_height())))
	var small := _area_downscale(img, target_w, target_h)
	var cut := a[5].to_float() if a.size() > 5 else 0.5
	_snap_alpha(small, cut)
	if a.size() > 4 and not a[4].is_empty():
		var pal := _read_palette(a[4])
		if pal.is_empty():
			return 1
		_apply_palette(small, pal)
	return _save(small, a[2])


func _palette_cmd(a: PackedStringArray) -> int:
	if a.size() < 4:
		return 2
	var img := _load(a[1])
	if img == null:
		return 1
	var pal := _read_palette(a[3])
	if pal.is_empty():
		return 1
	_apply_palette(img, pal)
	return _save(img, a[2])


func _scale(a: PackedStringArray) -> int:
	if a.size() < 4:
		return 2
	var img := _load(a[1])
	if img == null:
		return 1
	var f := maxi(1, a[3].to_int())
	img.resize(img.get_width() * f, img.get_height() * f, Image.INTERPOLATE_NEAREST)
	return _save(img, a[2])


func _fit(a: PackedStringArray) -> int:
	if a.size() < 5:
		return 2
	var img := _load(a[1])
	if img == null:
		return 1
	img.resize(maxi(1, a[3].to_int()), maxi(1, a[4].to_int()), Image.INTERPOLATE_LANCZOS)
	return _save(img, a[2])


func _slice(a: PackedStringArray) -> int:
	if a.size() < 5:
		return 2
	var img := _load(a[1])
	if img == null:
		return 1
	var cols := maxi(1, a[3].to_int())
	var rows := maxi(1, a[4].to_int())
	var fw := img.get_width() / cols
	var fh := img.get_height() / rows
	var n := 0
	for r in rows:
		for c in cols:
			var frame := img.get_region(Rect2i(c * fw, r * fh, fw, fh))
			if _save(frame, "%s_%02d.png" % [a[2], n]) != 0:
				return 1
			n += 1
	return 0


func _extract(a: PackedStringArray) -> int:
	if a.size() < 3:
		return 2
	var img := _load(a[1])
	if img == null:
		return 1
	var k := clampi(a[3].to_int() if a.size() > 3 else 16, 2, 64)
	# Work on a small copy: palette extraction needs colour statistics, not detail.
	var scale := minf(1.0, 96.0 / maxf(img.get_width(), img.get_height()))
	if scale < 1.0:
		img = _area_downscale(img, maxi(1, int(img.get_width() * scale)), maxi(1, int(img.get_height() * scale)))
	var px: Array[Color] = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a >= 0.5:
				px.append(c)
	if px.size() < k:
		printerr("image_tool: too few opaque pixels to extract ", k, " colours")
		return 1
	# Deterministic start: evenly spaced samples sorted by luminance.
	px.sort_custom(func(p: Color, q: Color) -> bool: return p.get_luminance() < q.get_luminance())
	var centres: Array[Color] = []
	for i in k:
		centres.append(px[int((i + 0.5) * px.size() / k)])
	for _iter in 12:
		var sums: Array[Vector3] = []
		var counts: Array[int] = []
		sums.resize(k)
		counts.resize(k)
		for i in k:
			sums[i] = Vector3.ZERO
			counts[i] = 0
		for c in px:
			var best := 0
			var best_d := INF
			for i in k:
				var d := _dist(c, centres[i])
				if d < best_d:
					best_d = d
					best = i
			sums[best] += Vector3(c.r, c.g, c.b)
			counts[best] += 1
		for i in k:
			if counts[i] > 0:
				var m := sums[i] / counts[i]
				centres[i] = Color(m.x, m.y, m.z)
	centres.sort_custom(func(p: Color, q: Color) -> bool: return p.get_luminance() < q.get_luminance())
	var lines := PackedStringArray()
	for c in centres:
		var h := c.to_html(false)
		if not lines.has(h):
			lines.append(h)
	var f := FileAccess.open(a[2], FileAccess.WRITE)
	if f == null:
		printerr("image_tool: cannot write ", a[2])
		return 1
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("wrote ", a[2], " ", lines.size(), " colours")
	return 0


func _svg(a: PackedStringArray) -> int:
	if a.size() < 3:
		return 2
	var text := FileAccess.get_file_as_string(a[1])
	if text.is_empty():
		printerr("image_tool: cannot read ", a[1])
		return 1
	var scale := 1.0
	var want := a[3].to_int() if a.size() > 3 else 0
	if want > 0:
		var re := RegEx.create_from_string("<svg[^>]*\\swidth=\"([0-9.]+)\"")
		var m := re.search(text)
		if m == null:
			printerr("image_tool: no width=\"N\" on the <svg> root")
			return 1
		scale = want / m.get_string(1).to_float()
	var img := Image.new()
	var err := img.load_svg_from_string(text, scale)
	if err != OK or img.is_empty():
		printerr("image_tool: SVG did not render (error ", err, ")")
		return 1
	return _save(img, a[2])


const CVD := {
	"protan": [Vector3(0.152286, 1.052583, -0.204868), Vector3(0.114503, 0.786281, 0.099216), Vector3(-0.003882, -0.048116, 1.051998)],
	"deutan": [Vector3(0.367322, 0.860646, -0.227968), Vector3(0.280085, 0.672501, 0.047413), Vector3(-0.011820, 0.042940, 0.968881)],
	"tritan": [Vector3(1.255528, -0.076749, -0.178779), Vector3(-0.078411, 0.930809, 0.147602), Vector3(0.004733, 0.691367, 0.303900)],
}


func _simulate(c: Color, kind: String) -> Color:
	if not CVD.has(kind):
		return c
	var m: Array = CVD[kind]
	var lin := c.srgb_to_linear()
	var v := Vector3(lin.r, lin.g, lin.b)
	var r := clampf((m[0] as Vector3).dot(v), 0.0, 1.0)
	var g := clampf((m[1] as Vector3).dot(v), 0.0, 1.0)
	var b := clampf((m[2] as Vector3).dot(v), 0.0, 1.0)
	var out := Color(r, g, b, c.a).linear_to_srgb()
	out.a = c.a
	return out


func _cvd(a: PackedStringArray) -> int:
	if a.size() < 3:
		return 2
	var src := _load(a[1])
	if src == null:
		return 1
	# Previews only: keep it fast (per-pixel GDScript) by capping the height.
	if src.get_height() > 640:
		var f := 640.0 / src.get_height()
		src.resize(maxi(1, int(src.get_width() * f)), 640, Image.INTERPOLATE_BILINEAR)
	for kind in ["protan", "deutan", "tritan"]:
		var img := src.duplicate() as Image
		for y in img.get_height():
			for x in img.get_width():
				img.set_pixel(x, y, _simulate(img.get_pixel(x, y), kind))
		if _save(img, "%s_%s.png" % [a[2], kind]) != 0:
			return 1
	return 0


func _cvdcheck(a: PackedStringArray) -> int:
	if a.size() < 2:
		return 2
	var pal := _read_palette(a[1])
	if pal.size() < 2:
		return 1
	var min_de := a[2].to_float() if a.size() > 2 else 15.0
	var problems := 0
	for kind in ["normal", "protan", "deutan", "tritan"]:
		var sim: Array[Color] = []
		for c in pal:
			sim.append(c if kind == "normal" else _simulate(c, kind))
		var lines := PackedStringArray()
		for i in pal.size():
			for j in range(i + 1, pal.size()):
				var de := _delta_e(sim[i], sim[j])
				if de < min_de:
					lines.append("  %s ~ %s  ΔE %.1f" % [pal[i].to_html(false), pal[j].to_html(false), de])
		print("%s: %s" % [kind, "ok" if lines.is_empty() else "%d confusable pair(s)" % lines.size()])
		for l in lines:
			print(l)
		problems += lines.size()
	print("cvdcheck: %d colours, %d pair(s) below ΔE %.0f" % [pal.size(), problems, min_de])
	return 0


func _delta_e(c1: Color, c2: Color) -> float:
	return _lab(c1).distance_to(_lab(c2))


func _lab(c: Color) -> Vector3:
	var l := c.srgb_to_linear()
	var x := (0.4124 * l.r + 0.3576 * l.g + 0.1805 * l.b) / 0.95047
	var y := (0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b) / 1.0
	var z := (0.0193 * l.r + 0.1192 * l.g + 0.9505 * l.b) / 1.08883
	var fx := _lab_f(x)
	var fy := _lab_f(y)
	var fz := _lab_f(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


func _lab_f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0


func _dist(c: Color, p: Color) -> float:
	var rm := (c.r + p.r) * 0.5
	var dr := c.r - p.r
	var dg := c.g - p.g
	var db := c.b - p.b
	return (2.0 + rm) * dr * dr + 4.0 * dg * dg + (3.0 - rm) * db * db


## Box-filter downscale: each target pixel is the alpha-weighted average of the
## source pixels it covers. Keeps shapes better than nearest, and does not
## blur like Lanczos, which matters at sprite sizes.
func _area_downscale(src: Image, w: int, h: int) -> Image:
	var out := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var sw := src.get_width()
	var sh := src.get_height()
	for y in h:
		var y0 := int(floor(float(y) * sh / h))
		var y1 := maxi(y0 + 1, int(floor(float(y + 1) * sh / h)))
		for x in w:
			var x0 := int(floor(float(x) * sw / w))
			var x1 := maxi(x0 + 1, int(floor(float(x + 1) * sw / w)))
			var r := 0.0
			var g := 0.0
			var b := 0.0
			var alpha := 0.0
			var count := 0
			for sy in range(y0, mini(y1, sh)):
				for sx in range(x0, mini(x1, sw)):
					var c := src.get_pixel(sx, sy)
					r += c.r * c.a
					g += c.g * c.a
					b += c.b * c.a
					alpha += c.a
					count += 1
			if count == 0 or alpha <= 0.0:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				out.set_pixel(x, y, Color(r / alpha, g / alpha, b / alpha, alpha / count))
	return out


func _snap_alpha(img: Image, cut: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			c.a = 1.0 if c.a >= cut else 0.0
			if c.a == 0.0:
				c = Color(0, 0, 0, 0)
			img.set_pixel(x, y, c)


func _read_palette(path: String) -> Array[Color]:
	var pal: Array[Color] = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		printerr("image_tool: cannot read palette ", path)
		return pal
	while not f.eof_reached():
		var line := f.get_line().strip_edges().trim_prefix("#")
		if line.length() == 6 and line.is_valid_hex_number():
			pal.append(Color.html(line))
	if pal.is_empty():
		printerr("image_tool: no RRGGBB lines in ", path)
	return pal


func _apply_palette(img: Image, pal: Array[Color]) -> void:
	var cache := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var key := c.to_rgba32()
			var best: Color
			if cache.has(key):
				best = cache[key]
			else:
				best = _nearest(c, pal)
				cache[key] = best
			img.set_pixel(x, y, Color(best.r, best.g, best.b, c.a))


## "Redmean" weighted RGB distance: cheap and close to perceived difference.
func _nearest(c: Color, pal: Array[Color]) -> Color:
	var best := pal[0]
	var best_d := INF
	for p in pal:
		var d := _dist(c, p)
		if d < best_d:
			best_d = d
			best = p
	return best


func _count_colours(img: Image) -> int:
	var seen := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0:
				seen[c.to_rgba32()] = true
	return seen.size()
