class_name Arch
extends RefCounted
## Traditional Chinese timber architecture, built from code.
##
## A hall is assembled the way the real ones are:
##   * a stone platform (xumizuo) with stacked mouldings, a balustrade of posts and rails, and a
##     central stair flanked by carved ramps and a pair of stone lions;
##   * a colonnade of lacquered columns on drum-shaped stone bases, each capped by a bracket set
##     (dougong: stacked blocks and crossing arms) that carries the eaves;
##   * lattice door panels (geshan) between the front columns, plastered side walls with timber
##     framing, and painted beams (blue-green caihua) under the eaves;
##   * a curved hip roof: every roof face is a grid whose height follows a concave curve (steep near
##     the ridge, flattening towards the eave), with the corners swept upward; tile ribs run down
##     the slope, a ridge with curling end ornaments (chiwen) crowns it and small guardian beasts
##     sit on the hip ridges.  Large halls get a second, lower eave.
## Styles change colours and add the building's own furniture (incense burner, herb racks and a
## cauldron, a chimney and forge).

const STYLES := {
	"hall": {"roof": "2f6a7a", "roof2": "245563", "column": "b83a2a", "wall": "efe4c8", "beam": "2a7a6a", "trim": "e8c860", "double": true},
	"alchemist": {"roof": "3a7a4a", "roof2": "2a5a38", "column": "8a3a2a", "wall": "eae0c4", "beam": "3a6a8a", "trim": "d8b850", "double": false},
	"smithy": {"roof": "5a5a64", "roof2": "44444c", "column": "6a3424", "wall": "d8ccb4", "beam": "8a4a2a", "trim": "c89840", "double": false},
}

static func _c(hex: String) -> Color:
	return Color(hex)

## Add a quad with smooth normals and the winding Godot treats as front-facing from `outside`.
static func _quad(b: MB, p: Array, nrm: Array, col: Color, outside: Vector3) -> void:
	var n0: Vector3 = ((p[1] as Vector3) - p[0]).cross((p[2] as Vector3) - p[0])
	var cols := [col, col, col, col]
	if n0.dot(outside) > 0.0:
		b.quad_n([p[0], p[3], p[2], p[1]], [nrm[0], nrm[3], nrm[2], nrm[1]], cols)
	else:
		b.quad_n(p, nrm, cols)

# ---------------------------------------------------------------- roofs
## Curved hip roof over a rectangle centred on `c` (eave height ye) with half extents ax (x) and
## az (z), overhang `o`, ridge height `rise` above the eave.  The ridge runs along the longer axis.
static func hip_roof(b: MB, g: MB, c: Vector3, ax: float, az: float, o: float, rise: float, st: Dictionary, beasts: bool = true) -> void:
	var swap := az > ax
	var a := maxf(ax, az) + o
	var d := minf(ax, az) + o
	var ridge_half := maxf(a - d, 0.2)
	var roof := MB.tag(_c(st.roof), MB.STONE)
	var under := MB.tag(_c(st.beam), MB.WOOD)
	var nu := 10
	var nv := 6
	# the four faces: two long trapezoids and two triangular hip ends
	for face in 4:
		var long := face < 2
		var sgn := 1.0 if face % 2 == 0 else -1.0
		var grid: Array = []
		for j in nv + 1:
			var v := j / float(nv)
			var row: Array = []
			for i in nu + 1:
				var u := i / float(nu)
				var e: Vector3
				var r: Vector3
				if long:
					e = Vector3(lerpf(-a, a, u), 0, d * sgn)
					r = Vector3(lerpf(-ridge_half, ridge_half, u), 0, 0)
				else:
					e = Vector3(a * sgn, 0, lerpf(d, -d, u) * sgn)
					r = Vector3(ridge_half * sgn, 0, 0)
				# corners sweep upward; the slope is concave (shallow at the eave, steep at the top)
				var uu := u * 2.0 - 1.0
				var lift := 0.42 * pow(absf(uu), 5.0) * (1.0 - v)
				var p := e.lerp(r, v)
				p.y = rise * pow(v, 1.7) + lift
				if swap:
					p = Vector3(p.z, p.y, p.x)
				row.append(c + p)
			grid.append(row)
		for j in nv:
			for i in nu:
				var q := [grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]]
				var nn := [] as Array
				for k in 4:
					var jj := j + (1 if k >= 2 else 0)
					var ii := i + (1 if k == 1 or k == 2 else 0)
					var pu: Vector3 = grid[jj][mini(ii + 1, nu)] - grid[jj][maxi(ii - 1, 0)]
					var pv: Vector3 = grid[mini(jj + 1, nv)][ii] - grid[maxi(jj - 1, 0)][ii]
					var nk := pu.cross(pv).normalized()
					if nk.y < 0.0:
						nk = -nk
					nn.append(nk)
				var mid: Vector3 = ((q[0] as Vector3) + q[2]) * 0.5
				var outward := (mid - c) * Vector3(1, 0, 1) + Vector3(0, 2.0, 0)
				# tile courses: alternate rows slightly darker so the roof reads as tiled
				var shade := 0.0 if j % 2 == 0 else 0.08
				_quad(b, q, nn, Color(roof.r, roof.g, roof.b, roof.a).darkened(shade), outward)
				# painted underside (seen from below the eave)
				var qd := [] as Array
				for qq in q:
					qd.append((qq as Vector3) - Vector3(0, 0.06, 0))
				_quad(b, qd, [-(nn[0] as Vector3), -(nn[1] as Vector3), -(nn[2] as Vector3), -(nn[3] as Vector3)], under, -outward)
		# tile ribs running down the slope
		var ribs := 9 if long else 4
		for k in ribs:
			var ui := int(round((k + 0.5) / ribs * nu))
			var pts: Array = []
			for j2 in nv + 1:
				pts.append((grid[j2][ui] as Vector3) + Vector3(0, 0.05, 0))
			for j3 in nv:
				b.limb(pts[j3], pts[j3 + 1], 0.045, 0.045, MB.tag(_c(st.roof2), MB.STONE), 5)
		# gilt edge along the eave
		var eave: Array = grid[0]
		for i2 in nu:
			b.limb((eave[i2] as Vector3) + Vector3(0, 0.02, 0), (eave[i2 + 1] as Vector3) + Vector3(0, 0.02, 0), 0.06, 0.06, MB.tag(_c(st.trim), MB.METAL), 5)
	# main ridge with curling chiwen at both ends
	var ra := c + (Vector3(0, rise, -ridge_half) if swap else Vector3(-ridge_half, rise, 0))
	var rb := c + (Vector3(0, rise, ridge_half) if swap else Vector3(ridge_half, rise, 0))
	b.limb(ra, rb, 0.14, 0.14, MB.tag(_c(st.roof2).darkened(0.1), MB.STONE), 8)
	for e2 in [ra, rb]:
		var out := ((e2 as Vector3) - c) * Vector3(1, 0, 1)
		out = out.normalized() if out.length() > 0.01 else Vector3.RIGHT
		var p0: Vector3 = e2
		var p1 := p0 + Vector3(0, 0.45, 0) - out * 0.05
		var p2 := p1 + Vector3(0, 0.15, 0) - out * 0.3
		b.limb(p0, p1, 0.16, 0.11, MB.tag(_c(st.trim), MB.METAL), 6)
		b.limb(p1, p2, 0.11, 0.05, MB.tag(_c(st.trim), MB.METAL), 6)
		b.ball(p2, 0.06, MB.tag(_c(st.trim), MB.METAL), true)
	# hip ridges down to the corners, with a row of little guardian beasts near the eave
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var top := c + (Vector3(0, rise, ridge_half * sx) if swap else Vector3(ridge_half * sx, rise, 0))
			var corner := c + (Vector3(d * sz, 0.42, a * sx) if swap else Vector3(a * sx, 0.42, d * sz))
			var prev := top
			for k in 5:
				var t := (k + 1) / 5.0
				var q2 := top.lerp(corner, t)
				q2.y = c.y + rise * pow(1.0 - t, 1.7) + 0.42 * pow(t, 5.0)
				b.limb(prev, q2, 0.09, 0.09, MB.tag(_c(st.roof2).darkened(0.1), MB.STONE), 6)
				if beasts and k >= 2 and k <= 3:
					b.ball(q2 + Vector3(0, 0.12, 0), 0.07, MB.tag(_c(st.trim), MB.METAL), true)
				prev = q2
			# a wind bell under each swept corner
			g.ball(corner + Vector3(0, -0.45, 0), 0.07, Color(1.0, 0.85, 0.45, 0.8), true)
			b.limb(corner, corner + Vector3(0, -0.38, 0), 0.01, 0.01, MB.tag(Color("6a5a40"), MB.METAL), 4)

# ---------------------------------------------------------------- the hall
## A complete hall on rectangle `r` (world XZ) at ground height 0; `front` is +Z.
static func hall(b: MB, g: MB, r: Rect2, style: String, seed_: int) -> Array:
	var st: Dictionary = STYLES.get(style, STYLES.hall)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var cx := r.position.x + r.size.x * 0.5
	var cz := r.position.y + r.size.y * 0.5
	var hx := r.size.x * 0.5
	var hz := r.size.y * 0.5
	var stone := MB.tag(Color("b4b0b8"), MB.STONE)
	var stone_d := MB.tag(Color("8e8a94"), MB.STONE)
	var column := MB.tag(_c(st.column), MB.WOOD)
	var wall := MB.tag(_c(st.wall), MB.CLOTH)
	var beam := MB.tag(_c(st.beam), MB.WOOD)
	var trim := MB.tag(_c(st.trim), MB.METAL)
	var lights: Array = []
	# ---- platform with mouldings
	var ph := 0.62
	b.box(Vector3(cx, 0.1, cz), Vector3(r.size.x + 1.3, 0.2, r.size.y + 1.3), stone_d)
	b.box(Vector3(cx, 0.27, cz), Vector3(r.size.x + 1.0, 0.16, r.size.y + 1.0), stone)
	b.box(Vector3(cx, 0.42, cz), Vector3(r.size.x + 0.85, 0.14, r.size.y + 0.85), stone_d)
	b.box(Vector3(cx, 0.56, cz), Vector3(r.size.x + 1.05, 0.12, r.size.y + 1.05), stone)
	# balustrade along the front and sides (a gap for the stair)
	var front_z := cz + hz + 0.48
	var rail := MB.tag(Color("d8d4dc"), MB.STONE)
	var n_post := int((r.size.x + 1.0) / 0.8)
	for i in n_post + 1:
		var px := cx - (r.size.x + 1.0) * 0.5 + i * (r.size.x + 1.0) / n_post
		if absf(px - cx) < 1.2:
			continue
		b.box(Vector3(px, ph + 0.28, front_z), Vector3(0.12, 0.56, 0.12), rail)
		b.ball(Vector3(px, ph + 0.6, front_z), 0.07, rail, true)
	for s: float in [-1.0, 1.0]:
		var x0 := cx + s * 1.2
		var x1 := cx + s * (hx + 0.5)
		b.box(Vector3((x0 + x1) * 0.5, ph + 0.45, front_z), Vector3(absf(x1 - x0), 0.07, 0.07), rail)
		b.box(Vector3((x0 + x1) * 0.5, ph + 0.15, front_z), Vector3(absf(x1 - x0), 0.06, 0.06), rail)
	# central stair with carved side ramps and a pair of guardian lions
	for k in 4:
		b.box(Vector3(cx, 0.08 + k * 0.155, front_z + 1.0 - k * 0.25), Vector3(2.0, 0.155, 0.32), stone)
	for s: float in [-1.0, 1.0]:
		b.box(Vector3(cx + s * 1.12, 0.36, front_z + 0.62), Vector3(0.24, 0.72, 1.3), stone_d)
		_lion(b, Vector3(cx + s * 1.6, 0.0, front_z + 1.3), s)
	# ---- columns, bases and brackets
	var wall_h := 2.75
	var top_y := ph + wall_h
	var bay := 1.9
	var nx := maxi(2, int(round(r.size.x / bay)))
	var nz := maxi(1, int(round(r.size.y / bay)))
	var col_pts: Array = []
	for i in nx + 1:
		var px2 := cx - hx + r.size.x * i / nx
		col_pts.append(Vector3(px2, 0, cz + hz + 0.25))
		col_pts.append(Vector3(px2, 0, cz - hz - 0.05))
	for i in range(1, nz):
		var pz := cz - hz + r.size.y * i / nz
		col_pts.append(Vector3(cx - hx - 0.05, 0, pz))
		col_pts.append(Vector3(cx + hx + 0.05, 0, pz))
	for cp in col_pts:
		var p: Vector3 = cp
		b.lathe(Vector3(p.x, ph, p.z), [Vector2(0.26, 0.0), Vector2(0.28, 0.08), Vector2(0.24, 0.18), Vector2(0.18, 0.22)], stone, 10)
		b.cyl(Vector3(p.x, ph + wall_h * 0.5, p.z), 0.15, wall_h, column, Vector3.ZERO, 10)
		_dougong(b, Vector3(p.x, top_y, p.z), trim, beam, column)
	# ---- walls: lattice doors across the front, framed plaster elsewhere
	b.box(Vector3(cx, ph + wall_h * 0.5, cz - 0.05), Vector3(r.size.x - 0.1, wall_h, r.size.y - 0.3), wall)
	for i in nx:
		var x0b := cx - hx + r.size.x * i / nx
		var x1b := cx - hx + r.size.x * (i + 1) / nx
		_lattice_bay(b, g, x0b + 0.17, x1b - 0.17, ph, wall_h, cz + hz - 0.12, column, trim, i == nx / 2)
	# timber frame lines on the side and back walls
	for s: float in [-1.0, 1.0]:
		var wx := cx + s * (hx - 0.03)
		b.box(Vector3(wx, ph + wall_h * 0.55, cz - 0.05), Vector3(0.06, 0.12, r.size.y - 0.3), column)
		b.box(Vector3(wx, ph + 0.35, cz - 0.05), Vector3(0.07, 0.14, r.size.y - 0.3), column)
	# ---- painted beams under the eaves (a blue-green band with a gold edge)
	for s: float in [-1.0, 1.0]:
		b.box(Vector3(cx, top_y - 0.12, cz + s * (hz + (0.25 if s > 0 else 0.05))), Vector3(r.size.x + 0.4, 0.26, 0.18), beam)
		b.box(Vector3(cx, top_y - 0.27, cz + s * (hz + (0.33 if s > 0 else 0.13))), Vector3(r.size.x + 0.4, 0.05, 0.04), trim)
		b.box(Vector3(cx + s * (hx + 0.05), top_y - 0.12, cz), Vector3(0.18, 0.26, r.size.y + 0.4), beam)
	# ---- roofs
	var roof_y := top_y + 0.42
	if st.double:
		hip_roof(b, g, Vector3(cx, top_y + 0.3, cz), hx + 0.35, hz + 0.45, 0.9, 0.55, st, false)
		# clerestory between the eaves
		b.box(Vector3(cx, top_y + 0.85, cz), Vector3(r.size.x - 0.6, 0.9, r.size.y - 0.4), wall)
		b.box(Vector3(cx, top_y + 1.3, cz), Vector3(r.size.x - 0.4, 0.18, r.size.y - 0.2), beam)
		roof_y = top_y + 1.38
		hip_roof(b, g, Vector3(cx, roof_y, cz), hx - 0.2, hz - 0.1, 0.95, 1.9, st)
	else:
		hip_roof(b, g, Vector3(cx, roof_y, cz), hx + 0.3, hz + 0.4, 0.95, 1.65, st)
	# ---- the building's own furniture
	match style:
		"hall":
			# bronze incense burner (ding) with smoke and a name plaque over the door
			var dp := Vector3(cx + 3.6, 0, front_z + 2.2)
			b.lathe(dp, [Vector2(0.45, 0.0), Vector2(0.5, 0.15), Vector2(0.55, 0.55), Vector2(0.5, 0.75), Vector2(0.58, 0.82)], MB.tag(Color("6a5a3a"), MB.METAL), 12)
			for k in 3:
				var a := TAU * k / 3.0
				b.limb(dp + Vector3(cos(a) * 0.35, 0.1, sin(a) * 0.35), dp + Vector3(cos(a) * 0.45, -0.05, sin(a) * 0.45), 0.07, 0.06, MB.tag(Color("5a4a2a"), MB.METAL), 6)
			for s: float in [-1.0, 1.0]:
				b.torus(dp + Vector3(s * 0.55, 0.9, 0), 0.12, 0.012, MB.tag(Color("6a5a3a"), MB.METAL), Vector3(0, 0, PI * 0.5))
			for k in 3:
				g.ball(dp + Vector3(0, 0.95 + k * 0.4, 0), 0.18 + k * 0.08, Color(0.9, 0.9, 0.95, 0.12), true)
			b.box(Vector3(cx, top_y - 0.6, cz + hz + 0.32), Vector3(1.4, 0.48, 0.07), MB.tag(Color("1a2a4a"), MB.WOOD))
			b.box(Vector3(cx, top_y - 0.6, cz + hz + 0.36), Vector3(1.2, 0.34, 0.02), trim)
		"alchemist":
			# a cauldron on a brazier, herb racks drying bundles
			var kp := Vector3(cx + hx - 0.6, 0, front_z + 1.8)
			b.lathe(kp + Vector3(0, 0.25, 0), [Vector2(0.15, 0.0), Vector2(0.5, 0.15), Vector2(0.55, 0.45), Vector2(0.45, 0.62)], MB.tag(Color("3a3a40"), MB.METAL), 12)
			g.disc(kp + Vector3(0, 0.84, 0), 0.4, Color(0.4, 1.0, 0.6, 0.7), 12, Color(0.4, 1.0, 0.6, 0.2))
			g.ball(kp + Vector3(0, 0.15, 0), 0.35, Color(1.0, 0.5, 0.2, 0.5), true)
			lights.append([kp + Vector3(0, 0.9, 0), Color(0.5, 1.0, 0.6)])
			for k in 2:
				var rp := Vector3(cx - hx + 0.6 + k * 1.4, 0, front_z + 1.6)
				for s: float in [-1.0, 1.0]:
					b.cyl(rp + Vector3(s * 0.55, 0.8, 0), 0.04, 1.6, MB.tag(Color("7a5a3a"), MB.WOOD), Vector3.ZERO, 6)
				b.cyl(rp + Vector3(0, 1.5, 0), 0.03, 1.2, MB.tag(Color("7a5a3a"), MB.WOOD), Vector3(0, 0, PI * 0.5), 6)
				for h2 in 4:
					var hp := rp + Vector3(-0.4 + h2 * 0.27, 1.32, 0)
					b.cone(hp, 0.07, 0.3, MB.tag(Color("6a8a3a").lerp(Color("a8a050"), rng.randf()), MB.FOLIAGE), Vector3(PI, 0, 0), 6)
		"smithy":
			# brick chimney with forge glow, an anvil and a rack of blades
			var ch := Vector3(cx + hx - 0.7, 0, cz - hz + 0.6)
			b.box(ch + Vector3(0, top_y + 1.4, 0), Vector3(0.7, top_y * 2.0, 0.7), MB.tag(Color("8a5a4a"), MB.STONE))
			b.box(ch + Vector3(0, top_y * 2.0 + 1.45, 0), Vector3(0.85, 0.12, 0.85), MB.tag(Color("6a4a3a"), MB.STONE))
			for k in 3:
				g.ball(ch + Vector3(0.1 * k, top_y * 2.0 + 1.8 + k * 0.5, 0), 0.25 + k * 0.1, Color(0.5, 0.5, 0.55, 0.18), true)
			var av := Vector3(cx - hx + 0.9, 0, front_z + 1.6)
			b.box(av + Vector3(0, 0.3, 0), Vector3(0.35, 0.6, 0.3), MB.tag(Color("5a4a3a"), MB.WOOD))
			b.box(av + Vector3(0, 0.68, 0), Vector3(0.7, 0.16, 0.26), MB.tag(Color("4a4a54"), MB.METAL))
			b.cone(av + Vector3(0.45, 0.68, 0), 0.08, 0.3, MB.tag(Color("4a4a54"), MB.METAL), Vector3(0, 0, -PI * 0.5), 6)
			var fg := Vector3(cx, ph + 0.6, cz + hz - 0.05)
			g.box(fg, Vector3(1.0, 0.7, 0.05), Color(1.0, 0.45, 0.15, 0.8))
			lights.append([fg + Vector3(0, 0, 0.6), Color(1.0, 0.5, 0.2)])
			for k in 4:
				b.box(av + Vector3(1.2 + k * 0.2, 0.75, -0.3), Vector3(0.05, 1.3, 0.02), MB.tag(Color("c8ccd8"), MB.METAL), Vector3(0, 0, 0.15))
	# hanging lanterns at the front corners
	for s: float in [-1.0, 1.0]:
		var lp := Vector3(cx + s * (hx - 0.3), top_y - 0.75, cz + hz + 0.45)
		b.lathe(lp, [Vector2(0.06, 0.0), Vector2(0.2, 0.1), Vector2(0.22, 0.25), Vector2(0.17, 0.4), Vector2(0.06, 0.46)], MB.tag(Color("e04a3a"), MB.CLOTH), 12)
		b.ribbon([lp, lp + Vector3(0, -0.25, 0)], [0.03, 0.01], Vector3.RIGHT, MB.tag(Color("f0c850"), MB.CLOTH))
		b.limb(lp + Vector3(0, 0.46, 0), lp + Vector3(0, 0.75, 0), 0.01, 0.01, trim, 4)
		g.ball(lp + Vector3(0, 0.23, 0), 0.42, Color(1.0, 0.45, 0.2, 0.3), true)
		lights.append([lp + Vector3(0, 0.2, 0.3), Color(1.0, 0.6, 0.3)])
	return lights

## Bracket set on a column top: a bearing block, crossing arms in two directions, small blocks.
static func _dougong(b: MB, top: Vector3, trim: Color, beam: Color, column: Color) -> void:
	b.box(top + Vector3(0, -0.05, 0), Vector3(0.36, 0.14, 0.36), trim)
	b.box(top + Vector3(0, 0.08, 0), Vector3(0.75, 0.11, 0.14), column)
	b.box(top + Vector3(0, 0.08, 0), Vector3(0.14, 0.11, 0.75), column)
	for s: float in [-1.0, 1.0]:
		b.box(top + Vector3(s * 0.33, 0.18, 0), Vector3(0.15, 0.09, 0.15), beam)
		b.box(top + Vector3(0, 0.18, s * 0.33), Vector3(0.15, 0.09, 0.15), beam)
	b.box(top + Vector3(0, 0.28, 0), Vector3(1.0, 0.1, 0.14), column)
	b.box(top + Vector3(0, 0.28, 0), Vector3(0.14, 0.1, 1.0), column)

## One bay of lattice doors (geshan): framed leaves with a grid in the upper part, a solid lower
## panel, warm light glowing through the paper; the middle bay gets the main door.
static func _lattice_bay(b: MB, g: MB, x0: float, x1: float, y0: float, hgt: float, z: float, frame: Color, trim: Color, main: bool) -> void:
	var leaves := 4 if (x1 - x0) > 1.2 else 2
	var lw := (x1 - x0) / leaves
	for k in leaves:
		var lx := x0 + lw * (k + 0.5)
		var top := y0 + hgt - 0.2
		b.box(Vector3(lx, y0 + hgt * 0.5, z), Vector3(lw - 0.04, hgt - 0.3, 0.06), frame)
		# lower panel
		b.box(Vector3(lx, y0 + 0.55, z + 0.035), Vector3(lw - 0.2, 0.7, 0.02), frame.darkened(0.25))
		# lattice: a grid of thin mullions over glowing paper
		var gy0 := y0 + 1.1
		var gy1 := top - 0.15
		g.box(Vector3(lx, (gy0 + gy1) * 0.5, z + 0.03), Vector3(lw - 0.22, gy1 - gy0, 0.01), Color(1.0, 0.86, 0.6, 0.55 if main else 0.4))
		for m in 4:
			var mx := lx - (lw - 0.22) * 0.5 + (lw - 0.22) * (m + 0.5) / 4.0
			b.box(Vector3(mx, (gy0 + gy1) * 0.5, z + 0.045), Vector3(0.025, gy1 - gy0, 0.025), frame)
		var rows := int((gy1 - gy0) / 0.18)
		for m in rows + 1:
			b.box(Vector3(lx, gy0 + (gy1 - gy0) * m / rows, z + 0.045), Vector3(lw - 0.22, 0.025, 0.025), frame)
		if main:
			for s: float in [-1.0, 1.0]:
				b.ball(Vector3(lx + s * lw * 0.3, y0 + 1.0, z + 0.07), 0.035, trim, true)

## A stone guardian lion on a plinth, facing out from the stair.
static func _lion(b: MB, p: Vector3, side: float) -> void:
	var s := MB.tag(Color("c0bcc4"), MB.STONE)
	b.box(p + Vector3(0, 0.25, 0), Vector3(0.6, 0.5, 0.7), MB.tag(Color("9a96a0"), MB.STONE))
	b.sph(p + Vector3(0, 0.75, -0.05), Vector3(0.22, 0.28, 0.28), s)
	b.sph(p + Vector3(0, 1.08, 0.08), Vector3(0.2, 0.19, 0.19), s)
	b.sph(p + Vector3(0, 1.0, 0.2), Vector3(0.1, 0.08, 0.1), s)
	for k in 6:
		var a := k * 1.05
		b.ball(p + Vector3(cos(a) * 0.17, 1.1 + sin(a) * 0.14, 0.02), 0.07, s.darkened(0.08), true)
	b.limb(p + Vector3(0.1, 0.55, 0.15), p + Vector3(0.12, 0.5, 0.3), 0.06, 0.05, s, 6)
	b.limb(p + Vector3(-0.1, 0.55, 0.15), p + Vector3(-0.12, 0.5, 0.3), 0.06, 0.05, s, 6)
	b.ball(p + Vector3(side * 0.16, 0.62, 0.32), 0.09, s.darkened(0.15), true)

## Five-storey pagoda: each storey a smaller balconied box under its own curved roof.
static func pagoda(b: MB, g: MB, base: Vector3, storeys: int = 5) -> void:
	var st: Dictionary = {"roof": "2a4a6a", "roof2": "1e3a56", "column": "b83a2a", "wall": "efe4c8", "beam": "2a7a6a", "trim": "e8c860", "double": false}
	b.box(base + Vector3(0, 0.3, 0), Vector3(3.6, 0.6, 3.6), MB.tag(Color("a8a4b0"), MB.STONE))
	var y := 0.6
	for k in storeys:
		var w := 2.6 - k * 0.36
		var hgt := 1.15 - k * 0.06
		b.box(base + Vector3(0, y + hgt * 0.5, 0), Vector3(w, hgt, w), MB.tag(Color(st.wall), MB.CLOTH))
		for cx: float in [-1.0, 1.0]:
			for cz: float in [-1.0, 1.0]:
				b.cyl(base + Vector3(cx * w * 0.5, y + hgt * 0.5, cz * w * 0.5), 0.09, hgt, MB.tag(Color(st.column), MB.WOOD), Vector3.ZERO, 8)
		for s: float in [-1.0, 1.0]:
			g.box(base + Vector3(0, y + hgt * 0.5, s * (w * 0.5 + 0.01)), Vector3(w * 0.35, hgt * 0.5, 0.02), Color(1.0, 0.85, 0.5, 0.6))
		hip_roof(b, g, base + Vector3(0, y + hgt + 0.05, 0), w * 0.5, w * 0.5, 0.55 + 0.05 * (storeys - k), 0.55, st, false)
		y += hgt + 0.55
	b.cyl(base + Vector3(0, y + 0.7, 0), 0.05, 1.4, MB.tag(Color(st.trim), MB.METAL), Vector3.ZERO, 6)
	for k in 5:
		b.torus(base + Vector3(0, y + 0.3 + k * 0.22, 0), 0.17 - k * 0.025, 0.012, MB.tag(Color(st.trim), MB.METAL))
	b.ball(base + Vector3(0, y + 1.45, 0), 0.12, MB.tag(Color(st.trim), MB.METAL), true)

## A courtyard wall from `a` to `e` (ground points): rendered plaster on a stone footing, a timber
## band, and a coping of grey tiles with a rounded ridge.  Small lattice windows every few metres.
static func wall_run(b: MB, g: MB, a: Vector3, e: Vector3, hgt: float = 2.2) -> void:
	var d := e - a
	var ln := d.length()
	if ln < 0.2:
		return
	var dir := d / ln
	var mid := (a + e) * 0.5
	# walls run along the map edges (axis-aligned); MB boxes are sized in world axes
	var along_x := absf(dir.x) > absf(dir.z)
	var sz := func(across: float, up: float, along: float) -> Vector3:
		return Vector3(along, up, across) if along_x else Vector3(across, up, along)
	var side := Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
	b.box(mid + Vector3(0, 0.25, 0), sz.call(0.62, 0.5, ln), MB.tag(Color("8e8a94"), MB.STONE))
	b.box(mid + Vector3(0, 0.5 + (hgt - 0.5) * 0.5, 0), sz.call(0.45, hgt - 0.5, ln), MB.tag(Color("f0e8d8"), MB.CLOTH))
	b.box(mid + Vector3(0, hgt - 0.12, 0), sz.call(0.5, 0.12, ln), MB.tag(Color("8a3424"), MB.WOOD))
	# coping: stepped grey tile courses overhanging both faces, a round ridge, and tile ends
	b.box(mid + Vector3(0, hgt + 0.03, 0), sz.call(0.8, 0.07, ln + 0.1), MB.tag(Color("4a5058"), MB.STONE))
	b.box(mid + Vector3(0, hgt + 0.12, 0), sz.call(0.55, 0.08, ln + 0.1), MB.tag(Color("424850"), MB.STONE))
	b.limb(a + Vector3(0, hgt + 0.2, 0) - dir * 0.05, e + Vector3(0, hgt + 0.2, 0) + dir * 0.05, 0.07, 0.07, MB.tag(Color("3a4048"), MB.STONE), 6)
	var n_tiles := int(ln / 0.32)
	for k in n_tiles:
		var p := a + dir * (k + 0.5) * ln / n_tiles + Vector3(0, hgt + 0.02, 0)
		for s: float in [-1.0, 1.0]:
			b.ball(p + side * s * 0.4, 0.05, MB.tag(Color("3a4048"), MB.STONE), true)
	# round lattice windows on both faces
	var n_win := int(ln / 4.5)
	for k in n_win:
		var wp := a + dir * (k + 0.5) * ln / maxi(n_win, 1) + Vector3(0, hgt * 0.6, 0)
		for s: float in [-1.0, 1.0]:
			var face := wp + side * s * 0.235
			b.torus(face, 0.32, 0.02, MB.tag(Color("6a3a2a"), MB.WOOD), Vector3(PI * 0.5, 0.0 if along_x else PI * 0.5, 0))
			b.box(face, Vector3(0.03, 0.56, 0.03), MB.tag(Color("6a3a2a"), MB.WOOD))
			b.box(face, sz.call(0.03, 0.03, 0.56), MB.tag(Color("6a3a2a"), MB.WOOD))

## A memorial archway (pailou) standing over a road: four lacquered posts on stone drums, three
## stepped roofs on bracket sets, a gilded name board, and lanterns on the side posts.
static func pailou(b: MB, g: MB, p: Vector3, yaw: float, span: float = 3.2) -> void:
	var bs := Basis(Vector3.UP, yaw)
	var red := MB.tag(Color("b83a2a"), MB.WOOD)
	var stone := MB.tag(Color("b0acb8"), MB.STONE)
	var gold := MB.tag(Color("e8c860"), MB.METAL)
	var st: Dictionary = {"roof": "2f6a7a", "roof2": "245563", "column": "b83a2a", "wall": "efe4c8", "beam": "2a7a6a", "trim": "e8c860", "double": false}
	var posts := [-span * 0.5, span * 0.5, -span * 0.5 - 1.3, span * 0.5 + 1.3]
	# MB boxes are sized in world axes: swap extents when the arch spans along z
	var swap0 := absf(sin(yaw)) > 0.7
	var sz := func(along: float, up: float, across: float) -> Vector3:
		return Vector3(across, up, along) if swap0 else Vector3(along, up, across)
	for i in posts.size():
		var x: float = posts[i]
		var tall := 4.2 if i < 2 else 3.0
		var q := p + bs * Vector3(x, 0, 0)
		b.lathe(q, [Vector2(0.3, 0.0), Vector2(0.3, 0.35), Vector2(0.22, 0.5)], stone, 10)
		b.cyl(q + Vector3(0, tall * 0.5, 0), 0.14, tall, red, Vector3.ZERO, 10)
		# stone buttress blocks either side of each post
		for s: float in [-1.0, 1.0]:
			b.box(q + bs * Vector3(0, 0.35, s * 0.3), sz.call(0.2, 0.7, 0.36), stone)
	# beams and the name board
	b.box(p + Vector3(0, 3.6, 0), sz.call(span + 0.4, 0.26, 0.22), red)
	b.box(p + Vector3(0, 3.05, 0), sz.call(span + 0.3, 0.18, 0.2), MB.tag(Color("2a7a6a"), MB.WOOD))
	b.box(p + Vector3(0, 3.33, 0), sz.call(1.5, 0.4, 0.08), MB.tag(Color("1a2a4a"), MB.WOOD))
	b.box(p + bs * Vector3(0, 3.33, 0.05), sz.call(1.3, 0.28, 0.02), gold)
	for s: float in [-1.0, 1.0]:
		b.box(p + bs * Vector3(s * (span * 0.5 + 0.65), 2.55, 0), sz.call(1.3, 0.2, 0.2), red)
	# roofs: a tall centre roof and two lower side roofs
	var swap := absf(sin(yaw)) > 0.7
	var ax := (span + 0.6) * 0.5
	var az := 0.35
	hip_roof(b, g, p + Vector3(0, 3.78, 0), az if swap else ax, ax if swap else az, 0.45, 0.6, st, false)
	for s: float in [-1.0, 1.0]:
		var sp := p + bs * Vector3(s * (span * 0.5 + 0.65), 2.7, 0)
		hip_roof(b, g, sp, az if swap else 0.6, 0.6 if swap else az, 0.35, 0.45, st, false)
		var lp := p + bs * Vector3(s * (span * 0.5), 2.3, 0.25)
		b.lathe(lp, [Vector2(0.06, 0.0), Vector2(0.16, 0.08), Vector2(0.17, 0.2), Vector2(0.13, 0.32), Vector2(0.05, 0.36)], MB.tag(Color("e04a3a"), MB.CLOTH), 10)
		g.ball(lp + Vector3(0, 0.18, 0), 0.35, Color(1.0, 0.45, 0.2, 0.3), true)

## An open pavilion (ting): four or six columns on a raised round terrace, benches between the
## columns, a curved roof with a gilded finial.  Used as a landmark in built regions.
static func pavilion(b: MB, g: MB, roof_hex: String, column_hex: String, size: float = 1.0) -> void:
	var st: Dictionary = {"roof": roof_hex, "roof2": Color(roof_hex).darkened(0.25).to_html(false), "column": column_hex, "wall": "efe4c8", "beam": "2a7a6a", "trim": "e8c860", "double": false}
	var r := 1.05 * size
	b.lathe(Vector3.ZERO, [Vector2(r + 0.35, -0.05), Vector2(r + 0.35, 0.18), Vector2(r + 0.2, 0.28), Vector2(r + 0.2, 0.34)], MB.tag(Color("b4b0b8"), MB.STONE), 16)
	var hgt := 2.0 * size
	for k in 4:
		var a := TAU * k / 4.0 + PI / 4.0
		var cp := Vector3(cos(a) * r, 0.34, sin(a) * r)
		b.cyl(cp + Vector3(0, hgt * 0.5, 0), 0.09 * size, hgt, MB.tag(Color(column_hex), MB.WOOD), Vector3.ZERO, 8)
		b.lathe(cp, [Vector2(0.15 * size, 0.0), Vector2(0.15 * size, 0.08), Vector2(0.1 * size, 0.12)], MB.tag(Color("a8a4b0"), MB.STONE), 8)
		# a low railing bench between this column and the next
		var a2 := TAU * (k + 1) / 4.0 + PI / 4.0
		var cp2 := Vector3(cos(a2) * r, 0.34, sin(a2) * r)
		if k != 1:
			b.limb(cp + Vector3(0, 0.45, 0), cp2 + Vector3(0, 0.45, 0), 0.05, 0.05, MB.tag(Color(column_hex).darkened(0.2), MB.WOOD), 5)
			b.limb(cp + Vector3(0, 0.2, 0), cp2 + Vector3(0, 0.2, 0), 0.03, 0.03, MB.tag(Color(column_hex).darkened(0.2), MB.WOOD), 5)
		_dougong(b, cp + Vector3(0, hgt, 0), MB.tag(Color("e8c860"), MB.METAL), MB.tag(Color("2a7a6a"), MB.WOOD), MB.tag(Color(column_hex), MB.WOOD))
	b.box(Vector3(0, 0.34 + hgt - 0.08, 0), Vector3(r * 1.5, 0.16, r * 1.5), MB.tag(Color("2a7a6a"), MB.WOOD))
	hip_roof(b, g, Vector3(0, 0.34 + hgt + 0.3, 0), r * 0.75, r * 0.72, 0.65 * size, 1.25 * size, st, false)
	var top := Vector3(0, 0.34 + hgt + 0.3 + 1.25 * size, 0)
	b.lathe(top, [Vector2(0.16, 0.0), Vector2(0.08, 0.15), Vector2(0.12, 0.3), Vector2(0.01, 0.55)], MB.tag(Color("e8c860"), MB.METAL), 10)
	g.ball(Vector3(0, 0.34 + hgt - 0.35, 0), 0.25, Color(1.0, 0.7, 0.35, 0.5), true)
