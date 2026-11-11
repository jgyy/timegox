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
	"library": {"roof": "3a4a7a", "roof2": "2a3860", "column": "7a2a2a", "wall": "efe8d4", "beam": "3a5a8a", "trim": "e0c060", "double": false},
	"house": {"roof": "5a4a3a", "roof2": "463a2e", "column": "6a4a30", "wall": "e8dcc0", "beam": "6a5a40", "trim": "b89850", "double": false},
	"inn": {"roof": "7a3a2a", "roof2": "5a2a20", "column": "8a3020", "wall": "f0e4c8", "beam": "4a6a5a", "trim": "e0b850", "double": false},
	"shrine": {"roof": "6a2a2a", "roof2": "4a1e1e", "column": "b83a2a", "wall": "f0e0c0", "beam": "2a6a5a", "trim": "f0c850", "double": true},
	# town buildings (references: Hui-style architecture of Xidi and Hongcun, white walls and black
	# tiles with stepped "horse-head" fire walls; Jiangnan water-town shop-houses; thatched farms)
	"huizhou": {"roof": "3a3c44", "roof2": "2a2c34", "column": "3a2e28", "wall": "f4f2ec", "beam": "4a4a50", "trim": "c8c0b0", "double": false, "kind": "gable", "horsehead": true},
	"farmhouse": {"roof": "b89a58", "roof2": "9a7e40", "column": "6a4a2e", "wall": "cdb48a", "beam": "6a4a30", "trim": "a88a50", "double": false, "kind": "thatch"},
	"teahouse": {"roof": "3a5a4a", "roof2": "2a4436", "column": "9a3a2a", "wall": "f0e6cc", "beam": "3a6a5a", "trim": "e0b850", "double": true, "balcony": true},
	"shop": {"roof": "6a4a3a", "roof2": "4a3428", "column": "7a3a24", "wall": "eadcc0", "beam": "5a4a3a", "trim": "d8a840", "double": false, "kind": "gable", "awning": "c8402a"},
	"dorm": {"roof": "4a4a54", "roof2": "3a3a44", "column": "7a3a2a", "wall": "ece4d0", "beam": "3a5a7a", "trim": "c8a850", "double": false, "kind": "gable"},
	"kitchen": {"roof": "5a5048", "roof2": "463e38", "column": "6a3a28", "wall": "e4d8bc", "beam": "6a5040", "trim": "c09048", "double": false, "kind": "gable", "chimney": true},
	# Part XI: the Feathered Folk's aerie tower, sky-blue tiles on white walls with a gallery
	"aerie": {"roof": "4a6aa8", "roof2": "3a5a90", "column": "e8e4d8", "wall": "f4f0e4", "beam": "4a8ab0", "trim": "f0d070", "double": true, "balcony": true, "spire": true},
	# Part XII: the fishermen's houses of Landfall and the wreck on the sea floor, blue-grey tiles over
	# whitewashed walls with coral-red columns, gabled against the sea wind
	"seahouse": {"roof": "3a5a7a", "roof2": "2a4660", "column": "c8503a", "wall": "f2f0ea", "beam": "3a6a7a", "trim": "e0d0a0", "double": false, "kind": "gable"},
	# the Lotus release (Part XV): the Founder's hermitage under the Last Cave, white plaster and pale
	# jade tiles, a round moon gate for a door, round windows, a lotus finial on the ridge and a little
	# two-storey pagoda rising out of the roof; and its bathhouse, gabled, with a raised louver along the
	# ridge to let the steam out
	"hermitage": {"roof": "6aa898", "roof2": "4a8878", "column": "f0ece4", "wall": "f6f4f0", "beam": "8ab8a8", "trim": "e8b0c0", "double": false,
		"moon_gate": true, "lotus_finial": true, "tiers": 2},
	"bathhouse": {"roof": "5a6a78", "roof2": "46545e", "column": "7a4a32", "wall": "ece4d4", "beam": "5a7a7a", "trim": "c8b890", "double": false, "kind": "gable",
		"louver": true, "moon_gate": true},
}
## Part XI: how high an upper storey's floor stands above the building's ground (the top of the ground
## floor's walls), and how deep a cellar's floor lies below it
const STOREY_Y := 2.96
const CELLAR_Y := -3.0
## the top of a ground floor's planks above the ground under the building (the platform `ph` is
## 0.3 m, the planks on it a few centimetres more): people indoors stand on this
const FLOOR_Y := 0.31

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

# ---------------------------------------------------------------- bridges and settlements
## A humped stone bridge from `a` to `e` over water: an arched deck of dressed stones, parapets
## with posts, and lotus-capped posts at the ends.  Used wherever a road crosses water.
static func bridge(b: MB, g: MB, a: Vector3, e: Vector3, width: float = 1.8) -> void:
	var d := e - a
	var ln := d.length()
	if ln < 0.5:
		return
	var dir := d / ln
	var side := Vector3(-dir.z, 0, dir.x)
	var stone := MB.tag(Color("a8a4a0"), MB.STONE)
	var stone_d := MB.tag(Color("8a8680"), MB.STONE)
	var n := maxi(6, int(ln / 0.45))
	var hump := minf(0.9, ln * 0.12)
	var prev_l := Vector3.ZERO
	var prev_r := Vector3.ZERO
	for i in n + 1:
		var t := i / float(n)
		var c := a.lerp(e, t) + Vector3(0, sin(t * PI) * hump + 0.05, 0)
		# deck stones, alternating shades
		if i < n:
			var c2 := a.lerp(e, (i + 1) / float(n)) + Vector3(0, sin((i + 1) / float(n) * PI) * hump + 0.05, 0)
			var mid := (c + c2) * 0.5
			var along_x := absf(dir.x) > absf(dir.z)
			var seg_len := (c2 - c).length() + 0.02
			var size := Vector3(seg_len, 0.22, width) if along_x else Vector3(width, 0.22, seg_len)
			b.box(mid, size, stone if i % 2 == 0 else stone_d)
		var l := c + side * width * 0.5 + Vector3(0, 0.12, 0)
		var r := c - side * width * 0.5 + Vector3(0, 0.12, 0)
		if i > 0:
			b.limb(prev_l + Vector3(0, 0.45, 0), l + Vector3(0, 0.45, 0), 0.06, 0.06, stone, 5)
			b.limb(prev_r + Vector3(0, 0.45, 0), r + Vector3(0, 0.45, 0), 0.06, 0.06, stone, 5)
		if i % 2 == 0:
			for q in [l, r]:
				b.box((q as Vector3) + Vector3(0, 0.25, 0), Vector3(0.14, 0.5, 0.14), stone)
				b.ball((q as Vector3) + Vector3(0, 0.55, 0), 0.08, stone, true)
		prev_l = l
		prev_r = r
	# the arch underneath, seen from the banks
	for s: float in [-1.0, 1.0]:
		var prev := a + side * width * 0.5 * s
		for i in range(1, 9):
			var t2 := i / 8.0
			var q2 := a.lerp(e, t2) + side * width * 0.5 * s + Vector3(0, sin(t2 * PI) * (hump - 0.25) - 0.2, 0)
			b.limb(prev, q2, 0.12, 0.12, stone_d, 5)
			prev = q2

## A small dwelling: rammed-earth or timber walls, a gabled roof of grey tiles or thatch, a door,
## a window with a warm light, firewood stacked by the wall.  `kind`: house, stilt (marsh and
## river huts on piles), shrine (a roadside shrine with an altar), tower (a watchtower).
static func dwelling(b: MB, g: MB, kind: String, seed_: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var wall := MB.tag(Color("d8c8a8").darkened(rng.randf() * 0.12), MB.CLOTH)
	var timber := MB.tag(Color("6a4430"), MB.WOOD)
	var roof := MB.tag(Color("5a5e66") if rng.randf() < 0.6 else Color("b89a58"), MB.STONE)
	var st: Dictionary = {"roof": roof.to_html(false), "roof2": roof.darkened(0.25).to_html(false), "column": "7a3a2a", "wall": "e0d4b8", "beam": "4a6a5a", "trim": "c8a050", "double": false}
	match kind:
		"stilt":
			for cx: float in [-1.0, 1.0]:
				for cz: float in [-1.0, 1.0]:
					b.limb(Vector3(cx * 0.9, -0.6, cz * 0.75), Vector3(cx * 0.9, 1.0, cz * 0.75), 0.08, 0.07, timber, 6)
			b.box(Vector3(0, 1.0, 0), Vector3(2.3, 0.12, 1.9), timber)
			b.box(Vector3(0, 1.75, 0), Vector3(1.9, 1.4, 1.5), MB.tag(Color("9a7a50"), MB.WOOD))
			b.box(Vector3(0, 1.6, 0.76), Vector3(0.5, 1.0, 0.04), MB.tag(Color("3a2418"), MB.WOOD))
			g.box(Vector3(0.6, 1.9, 0.76), Vector3(0.36, 0.3, 0.02), Color(1.0, 0.75, 0.4, 0.7))
			_gable(b, Vector3(0, 2.45, 0), 1.25, 1.05, 0.9, MB.tag(Color("b89a58"), MB.FOLIAGE), true)
			for k in 4:
				b.box(Vector3(1.0 + k * 0.0, 0.5 - k * 0.25, 0.3), Vector3(0.4, 0.06, 0.5), timber)
		"shrine":
			b.box(Vector3(0, 0.2, 0), Vector3(1.4, 0.4, 1.2), MB.tag(Color("a8a4a0"), MB.STONE))
			for cx2: float in [-1.0, 1.0]:
				b.cyl(Vector3(cx2 * 0.5, 0.95, 0.35), 0.06, 1.1, MB.tag(Color("b83a2a"), MB.WOOD), Vector3.ZERO, 8)
			b.box(Vector3(0, 0.95, -0.2), Vector3(1.1, 1.1, 0.5), MB.tag(Color("efe4c8"), MB.CLOTH))
			b.box(Vector3(0, 0.62, 0.3), Vector3(0.6, 0.22, 0.3), MB.tag(Color("6a4430"), MB.WOOD))
			for k in 3:
				b.limb(Vector3(-0.1 + k * 0.1, 0.73, 0.3), Vector3(-0.1 + k * 0.1, 0.95, 0.3), 0.008, 0.008, MB.tag(Color("c84030"), MB.WOOD), 4)
				g.ball(Vector3(-0.1 + k * 0.1, 0.97, 0.3), 0.03, Color(1.0, 0.6, 0.3, 0.9), true)
			hip_roof(b, g, Vector3(0, 1.55, 0.05), 0.6, 0.55, 0.35, 0.55, st, false)
		"tower":
			b.box(Vector3(0, 1.0, 0), Vector3(1.6, 2.0, 1.6), MB.tag(Color("9a968e"), MB.STONE))
			b.box(Vector3(0, 2.75, 0), Vector3(1.5, 1.5, 1.5), wall)
			for cx3: float in [-1.0, 1.0]:
				for cz3: float in [-1.0, 1.0]:
					b.cyl(Vector3(cx3 * 0.72, 2.75, cz3 * 0.72), 0.07, 1.5, timber, Vector3.ZERO, 6)
			b.box(Vector3(0, 3.55, 0), Vector3(2.0, 0.1, 2.0), timber)
			g.box(Vector3(0, 2.9, 0.76), Vector3(0.5, 0.4, 0.02), Color(1.0, 0.75, 0.4, 0.7))
			hip_roof(b, g, Vector3(0, 3.65, 0), 0.85, 0.85, 0.45, 0.95, st, false)
			b.lathe(Vector3(0.7, 3.62, 0.7), [Vector2(0.05, 0.0), Vector2(0.14, -0.1), Vector2(0.14, -0.3), Vector2(0.05, -0.38)], MB.tag(Color("e04a3a"), MB.CLOTH), 8)
		_:
			# house
			b.box(Vector3(0, 0.12, 0), Vector3(2.8, 0.24, 2.2), MB.tag(Color("8e8a94"), MB.STONE))
			b.box(Vector3(0, 0.95, 0), Vector3(2.5, 1.5, 1.9), wall)
			for cx4: float in [-1.0, 1.0]:
				b.box(Vector3(cx4 * 1.22, 0.95, 0.93), Vector3(0.1, 1.5, 0.1), timber)
				b.box(Vector3(cx4 * 1.22, 0.95, -0.93), Vector3(0.1, 1.5, 0.1), timber)
			b.box(Vector3(0, 1.65, 0.96), Vector3(2.5, 0.1, 0.06), timber)
			b.box(Vector3(-0.4, 0.82, 0.96), Vector3(0.6, 1.2, 0.05), MB.tag(Color("4a2a18"), MB.WOOD))
			b.box(Vector3(0.6, 1.1, 0.96), Vector3(0.5, 0.42, 0.04), timber)
			g.box(Vector3(0.6, 1.1, 0.98), Vector3(0.42, 0.34, 0.01), Color(1.0, 0.78, 0.45, 0.65))
			_gable(b, Vector3(0, 1.7, 0), 1.65, 1.35, 1.0, roof, false)
			# a stack of firewood and a water jar
			for k in 3:
				for j in 3 - k:
					var lz := -0.6 + j * 0.15 + k * 0.07
					b.limb(Vector3(-1.75, 0.12 + k * 0.14, lz), Vector3(-1.35, 0.12 + k * 0.14, lz), 0.065, 0.065, timber, 6)
			b.lathe(Vector3(1.55, 0.0, 0.7), [Vector2(0.12, 0.0), Vector2(0.22, 0.2), Vector2(0.18, 0.4), Vector2(0.12, 0.45)], MB.tag(Color("7a4a30"), MB.STONE), 10)

## A gabled roof: two sloping planes meeting at a ridge along x, with overhanging eaves, gable
## boards and (for thatch) a thick, ragged edge.
static func _gable(b: MB, top: Vector3, hx: float, hz: float, rise: float, col: Color, thatch: bool) -> void:
	for s: float in [-1.0, 1.0]:
		var e0 := top + Vector3(-hx, 0, hz * s)
		var e1 := top + Vector3(hx, 0, hz * s)
		var r0 := top + Vector3(-hx, rise, 0)
		var r1 := top + Vector3(hx, rise, 0)
		var n := (e1 - e0).cross(r0 - e0).normalized()
		if n.y < 0:
			n = -n
		var quad := [e0, e1, r1, r0]
		Arch._quad(b, quad, [n, n, n, n], col, n)
		Arch._quad(b, [e0 - Vector3(0, 0.05, 0), e1 - Vector3(0, 0.05, 0), r1 - Vector3(0, 0.05, 0), r0 - Vector3(0, 0.05, 0)], [-n, -n, -n, -n], col.darkened(0.35), -n)
		if thatch:
			b.limb(e0 + Vector3(0, -0.05, 0), e1 + Vector3(0, -0.05, 0), 0.09, 0.09, col.darkened(0.15), 6)
		else:
			for k in int(hx * 2.0 / 0.3):
				var x := -hx + 0.15 + k * 0.3
				b.limb(top + Vector3(x, 0.04, hz * s), top + Vector3(x, rise + 0.04, 0), 0.035, 0.035, col.darkened(0.2), 4)
	b.limb(top + Vector3(-hx - 0.1, rise + 0.05, 0), top + Vector3(hx + 0.1, rise + 0.05, 0), 0.08, 0.08, col.darkened(0.3), 6)
	for sx: float in [-1.0, 1.0]:
		b.ball(top + Vector3(sx * (hx + 0.12), rise + 0.12, 0), 0.08, col.darkened(0.3), true)

## A nomad tent / steppe yurt: a felt drum with a domed roof, a coloured band and a smoke hole.
static func tent(b: MB, g: MB, seed_: int, yurt: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var felt := MB.tag(Color("e8dcc0").darkened(rng.randf() * 0.1), MB.CLOTH)
	var band := MB.tag(Color("b83a2a") if rng.randf() < 0.5 else Color("2a5a8a"), MB.CLOTH)
	if yurt:
		b.lathe(Vector3.ZERO, [Vector2(1.4, 0.0), Vector2(1.42, 0.9), Vector2(1.25, 1.2), Vector2(0.6, 1.75), Vector2(0.25, 1.9)], felt, 16)
		b.lathe(Vector3.ZERO, [Vector2(1.43, 0.55), Vector2(1.43, 0.75)], band, 16)
		b.lathe(Vector3(0, 1.88, 0), [Vector2(0.27, 0.0), Vector2(0.27, 0.12)], MB.tag(Color("6a4430"), MB.WOOD), 10)
		b.box(Vector3(0, 0.5, 1.4), Vector3(0.6, 1.0, 0.08), band)
		g.ball(Vector3(0, 2.2, 0), 0.3, Color(0.85, 0.85, 0.9, 0.2), true)
	else:
		# a long desert tent: a ridge pole and two sloping awnings of striped cloth, open at the front
		for s: float in [-1.0, 1.0]:
			b.limb(Vector3(s * 1.2, 0, 0), Vector3(s * 1.2, 1.6, 0), 0.05, 0.05, MB.tag(Color("6a4430"), MB.WOOD), 6)
		Arch._gable(b, Vector3(0, 0.3, 0), 1.3, 1.1, 1.3, felt, true)
		for k in 3:
			b.box(Vector3(-0.8 + k * 0.8, 1.0, 0.02), Vector3(0.2, 0.04, 2.0), band)
		b.box(Vector3(0, 0.03, 1.6), Vector3(1.6, 0.04, 1.0), MB.tag(Color("a83a30"), MB.CLOTH))
		b.lathe(Vector3(0.8, 0.0, 1.9), [Vector2(0.18, 0.0), Vector2(0.25, 0.25), Vector2(0.15, 0.5)], MB.tag(Color("a07040"), MB.STONE), 10)

## A ruined hall: a cracked platform, broken columns of different heights, a fallen beam, rubble
## and a corner of the old roof still standing.
static func ruin(b: MB, g: MB, seed_: int, stone_hex: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var stone := MB.tag(Color(stone_hex), MB.STONE)
	b.box(Vector3(0, 0.2, 0), Vector3(3.4, 0.4, 2.6), stone.darkened(0.15))
	for k in 6:
		var a := TAU * k / 6.0
		var p := Vector3(cos(a) * 1.3, 0.4, sin(a) * 1.0)
		var hgt := rng.randf_range(0.3, 2.6)
		b.cyl(p + Vector3(0, hgt * 0.5, 0), 0.16, hgt, stone, Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.08, 0.08)), 8)
		b.cyl(p + Vector3(0, 0.08, 0), 0.24, 0.16, stone.darkened(0.1), Vector3.ZERO, 8)
		if hgt > 2.0:
			b.box(p + Vector3(0, hgt + 0.08, 0), Vector3(0.4, 0.16, 0.4), stone.lightened(0.05))
	b.limb(Vector3(-1.4, 0.55, 0.9), Vector3(1.2, 0.5, 1.3), 0.14, 0.14, MB.tag(Color("5a4030"), MB.WOOD), 6)
	for k in 9:
		b.box(Vector3(rng.randf_range(-1.8, 1.8), 0.45, rng.randf_range(-1.4, 1.4)), Vector3(0.3, 0.2, 0.25) * rng.randf_range(0.6, 1.4), stone.darkened(rng.randf() * 0.2), Vector3(rng.randf(), rng.randf() * TAU, rng.randf()))
	var st: Dictionary = {"roof": "4a5a5a", "roof2": "3a4848", "column": "7a3a2a", "wall": "e0d4b8", "beam": "3a5a50", "trim": "a89060", "double": false}
	hip_roof(b, g, Vector3(-0.9, 2.6, -0.6), 0.6, 0.5, 0.35, 0.5, st, false)

# ---------------------------------------------------------------- settlement meshes (cached)
## building kinds that appear at the edges of each region's wilds
const SETTLE := {
	"bamboo": ["house", "shrine", "pavilion"], "marsh": ["stilt", "stilt", "shrine"], "frost": ["tower"], "thunder": ["tower", "ruin"],
	"dunes": ["tent", "tent", "ruin"], "aurora": ["yurt", "yurt", "tower"], "maple": ["shrine", "house", "house"],
	"karst": ["stilt", "house", "shrine"], "lilies": ["shrine", "ruin", "pavilion"], "grave": ["ruin", "shrine"], "garden": ["pavilion", "house", "shrine"],
	"cloudsea": ["shrine", "tower", "pavilion"], "court": ["ruin", "pavilion"], "celestial": ["pavilion"], "time": ["ruin"], "abyss": ["ruin"], "volcano": ["ruin", "tower"],
	"forge": ["tower", "ruin"], "mirror": ["shrine", "stilt"], "palace": ["tower", "ruin"],
	"village": ["house", "house", "shrine"], "tea": ["pavilion", "house"], "silk": ["house", "shrine"], "loom": ["pavilion", "ruin"],
	"starferry": ["stilt", "house", "shrine"], "magpie": ["tower", "pavilion"], "starpalace": ["pavilion", "pavilion", "ruin"], "jasper": ["pavilion", "shrine"],
	"yanggu": ["house", "house", "tower"], "millet": ["house", "ruin", "shrine"], "fusang": ["shrine", "stilt", "pavilion"], "guanghan": ["pavilion", "pavilion", "ruin"],
	"longmen": ["stilt", "house", "shrine"], "drowned": ["stilt", "stilt", "ruin"], "tushan": ["house", "tower", "ruin"], "buzhou": ["ruin", "tower"],
	"juntian": ["tower", "pavilion", "shrine"], "changhe": ["pavilion", "pavilion", "shrine"], "ninesprings": ["stilt", "house", "ruin"], "youdu": ["ruin", "shrine", "tower"],
	"penglai": ["stilt", "house", "pavilion"], "fangzhang": ["pavilion", "shrine", "house"], "yingzhou": ["shrine", "ruin"], "guixu": ["ruin", "ruin"],
}
static var _mesh_cache := {}

static func settlement_mesh(kind: String, variant: int, theme_name: String) -> ArrayMesh:
	var key := "%s#%d#%s" % [kind, variant, theme_name]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var b := MB.new()
	var g := MB.new()
	var seed_ := hash(key)
	match kind:
		"tent":
			tent(b, g, seed_, false)
		"yurt":
			tent(b, g, seed_, true)
		"pavilion":
			var pav := {"court": ["2a8a6a", "2a6a5a"], "celestial": ["e8c860", "c83a2a"], "garden": ["c86a8a", "8a3a2a"], "lilies": ["5a3a3a", "8a2a20"]}
			var pc: Array = pav.get(theme_name, ["2f6a7a", "b83a2a"])
			pavilion(b, g, pc[0], pc[1], 1.1)
		"ruin":
			var th := Look.theme(theme_name)
			ruin(b, g, seed_, Color(th.wall).lerp(Color("a8a4a0"), 0.6).to_html(false))
		_:
			dwelling(b, g, kind, seed_)
	var m := b.build(MB.mat_scenery())
	g.add_to(m, MB.mat_glow())
	_mesh_cache[key] = m
	return m


# ---------------------------------------------------------------- enterable buildings
## A building the hero can walk into.  `r` is the whole footprint in world XZ including its ring
## of wall tiles; the walls stand on the middle of that ring, so the inner tiles are the floor.
## The body (platform, floor, walls with a door gap, furniture, lanterns) goes into `b`/`g`; the
## roof goes into `roof`/`roof_g` so the world can lift it away while the hero is inside.
## `props` are [kind, tile centre]; returns lights [[pos, colour], ...].
## Part XI: a building with an upper storey (`up` given) gets a second floor of planks on top of the
## ground floor's walls (open at the stairs, `hole`), walls with windows, its own furniture
## (`upper_props`) in `up`/`up_g` (so the world can lift the storey away while the hero is on the
## ground floor), and its roof a storey higher.
static func house(b: MB, g: MB, roof: MB, roof_g: MB, r: Rect2, door: Vector3, style: String, props: Array, seed_: int, up: MB = null, up_g: MB = null, upper_props: Array = [], hole: Vector3 = Vector3(-9999, 0, -9999)) -> Array:
	var st: Dictionary = STYLES.get(style, STYLES.house)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var T := Terrain3D.T
	var lights: Array = []
	var cx := r.get_center().x
	var cz := r.get_center().y
	var x0 := r.position.x + T * 0.5
	var x1 := r.end.x - T * 0.5
	var z0 := r.position.y + T * 0.5
	var z1 := r.end.y - T * 0.5
	var stone := MB.tag(Color("a8a4ac"), MB.STONE)
	var stone_d := MB.tag(Color("848088"), MB.STONE)
	var column := MB.tag(_c(st.column), MB.WOOD)
	var wall := MB.tag(_c(st.wall), MB.CLOTH)
	var beam := MB.tag(_c(st.beam), MB.WOOD)
	var trim := MB.tag(_c(st.trim), MB.METAL)
	var plank := MB.tag(Color("9a6a42"), MB.WOOD)
	var plank_d := MB.tag(Color("7a5034"), MB.WOOD)
	var ph := 0.3
	var wall_h := 2.6
	var th := 0.32
	# platform and plank floor (planks run along the long side)
	b.box(Vector3(cx, ph * 0.5 - 0.15, cz), Vector3(r.size.x + 0.4, ph + 0.3, r.size.y + 0.4), stone_d)
	b.box(Vector3(cx, ph - 0.02, cz), Vector3(x1 - x0, 0.06, z1 - z0), plank)
	var along_x := r.size.x >= r.size.y
	var n_pl := int((z1 - z0) / 0.5) if along_x else int((x1 - x0) / 0.5)
	for i in n_pl:
		if along_x:
			b.box(Vector3(cx, ph + 0.012, z0 + (i + 0.5) * (z1 - z0) / n_pl), Vector3(x1 - x0, 0.01, 0.03), plank_d)
		else:
			b.box(Vector3(x0 + (i + 0.5) * (x1 - x0) / n_pl, ph + 0.012, cz), Vector3(0.03, 0.01, z1 - z0), plank_d)
	# a rug down the middle from the door
	var rug := MB.tag(Color("9a2a2a") if style in ["hall", "shrine", "inn"] else Color("4a5a7a"), MB.CLOTH)
	b.box(Vector3((door.x + cx) * 0.5, ph + 0.02, (door.z + cz) * 0.5), Vector3(maxf(absf(door.x - cx), 1.2) if absf(door.x - cx) > 0.5 else 1.2, 0.01, maxf(absf(door.z - cz), 1.2) if absf(door.z - cz) > 0.5 else 1.2), rug)
	# walls: four runs on the centre line of the wall ring, one with a doorway
	var sides := [[Vector3(x0, 0, z0), Vector3(x1, 0, z0)], [Vector3(x0, 0, z1), Vector3(x1, 0, z1)], [Vector3(x0, 0, z0), Vector3(x0, 0, z1)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1)]]
	for sd in sides:
		var a: Vector3 = sd[0]
		var e: Vector3 = sd[1]
		var horiz := absf(a.z - e.z) < 0.01
		var on_door := (horiz and absf(door.z - a.z) < T * 0.6) or (not horiz and absf(door.x - a.x) < T * 0.6)
		var cuts: Array = []
		if on_door:
			var dc := door.x if horiz else door.z
			cuts = [[minf(a.x, e.x) if horiz else minf(a.z, e.z), dc - 0.85], [dc + 0.85, maxf(a.x, e.x) if horiz else maxf(a.z, e.z)]]
		else:
			cuts = [[minf(a.x, e.x) if horiz else minf(a.z, e.z), maxf(a.x, e.x) if horiz else maxf(a.z, e.z)]]
		for c in cuts:
			var lo: float = c[0] - th * 0.5
			var hi: float = c[1] + th * 0.5
			var mid := (lo + hi) * 0.5
			var ln := hi - lo
			var pc := Vector3(mid, 0, a.z) if horiz else Vector3(a.x, 0, mid)
			var sz := Vector3(ln, wall_h, th) if horiz else Vector3(th, wall_h, ln)
			b.box(pc + Vector3(0, ph + wall_h * 0.5, 0), sz, wall)
			# stone plinth and a timber rail at waist and eave height
			b.box(pc + Vector3(0, ph + 0.22, 0), sz * Vector3(1, 0, 1) + Vector3(0.06 if not horiz else 0.0, 0.44, 0.06 if horiz else 0.0), stone)
			b.box(pc + Vector3(0, ph + 1.05, 0), sz * Vector3(1, 0, 1) + Vector3(0.05 if not horiz else 0.0, 0.08, 0.05 if horiz else 0.0), column)
			b.box(pc + Vector3(0, ph + wall_h - 0.1, 0), sz * Vector3(1, 0, 1) + Vector3(0.08 if not horiz else 0.0, 0.2, 0.08 if horiz else 0.0), beam)
			# lattice windows on longer stretches, glowing faintly from inside
			var nwin := int(ln / 2.6)
			for k in nwin:
				var wpos := lo + (k + 0.5) * ln / nwin
				var wc := Vector3(wpos, ph + 1.75, a.z) if horiz else Vector3(a.x, ph + 1.75, wpos)
				var wsz := Vector3(0.9, 0.7, th + 0.04) if horiz else Vector3(th + 0.04, 0.7, 0.9)
				b.box(wc, wsz + Vector3(0.1 if horiz else 0.0, 0.1, 0.0 if horiz else 0.1), column)
				g.box(wc, wsz * Vector3(0.85 if horiz else 1.02, 0.8, 1.02 if horiz else 0.85), Color(1.0, 0.85, 0.55, 0.35))
				for q in 3:
					var off := (q - 1) * 0.25
					b.box(wc + (Vector3(off, 0, 0) if horiz else Vector3(0, 0, off)), Vector3(0.04 if horiz else th + 0.06, 0.7, th + 0.06 if horiz else 0.04), column)
		# columns at the ends of each run
		for pnt in [a, e]:
			b.cyl(pnt + Vector3(0, ph + wall_h * 0.5, 0), 0.2, wall_h + 0.1, column, Vector3.ZERO, 10)
		if on_door:
			# door frame, lintel with a name board, and two leaves swung open into the room
			var dc2 := door.x if horiz else door.z
			var inward := (1.0 if cz > a.z else -1.0) if horiz else (1.0 if cx > a.x else -1.0)
			for s2: float in [-1.0, 1.0]:
				var post := Vector3(dc2 + s2 * 0.85, 0, a.z) if horiz else Vector3(a.x, 0, dc2 + s2 * 0.85)
				b.cyl(post + Vector3(0, ph + wall_h * 0.5, 0), 0.14, wall_h, column, Vector3.ZERO, 8)
				var leaf_c := post + (Vector3(-s2 * 0.08, 0, inward * 0.42) if horiz else Vector3(inward * 0.42, 0, -s2 * 0.08))
				b.box(leaf_c + Vector3(0, ph + 1.05, 0), Vector3(0.06, 2.0, 0.8) if horiz else Vector3(0.8, 2.0, 0.06), MB.tag(Color("a8342a"), MB.WOOD))
				for q2 in 3:
					b.ball(leaf_c + Vector3(0, ph + 0.6 + q2 * 0.45, 0) + (Vector3(0.04, 0, 0) if horiz else Vector3(0, 0, 0.04)), 0.035, trim, true)
			var lint := Vector3(dc2, ph + wall_h - 0.35, a.z) if horiz else Vector3(a.x, ph + wall_h - 0.35, dc2)
			b.box(lint, Vector3(1.9, 0.22, th + 0.1) if horiz else Vector3(th + 0.1, 0.22, 1.9), beam)
			var plaque := lint + Vector3(0, 0.0, -inward * (th * 0.5 + 0.06)) if horiz else lint + Vector3(-inward * (th * 0.5 + 0.06), 0, 0)
			b.box(plaque + Vector3(0, 0.45, 0), Vector3(1.1, 0.4, 0.05) if horiz else Vector3(0.05, 0.4, 1.1), MB.tag(Color("1a2a4a"), MB.WOOD))
			b.box(plaque + Vector3(0, 0.45, 0), Vector3(0.9, 0.26, 0.07) if horiz else Vector3(0.07, 0.26, 0.9), trim)
			# a threshold step and a pair of lanterns outside
			var outside := Vector3(0, 0, -inward) if horiz else Vector3(-inward, 0, 0)
			b.box(Vector3(door.x, ph * 0.4, door.z) + outside * 1.1, Vector3(1.8, ph * 0.8, 0.6) if horiz else Vector3(0.6, ph * 0.8, 1.8), stone)
			for s3: float in [-1.0, 1.0]:
				var lp := Vector3(door.x, ph + 2.1, door.z) + outside * 0.45 + (Vector3(s3 * 1.15, 0, 0) if horiz else Vector3(0, 0, s3 * 1.15))
				_lantern(b, g, lp, trim)
				lights.append([lp + outside * 0.4, Color(1.0, 0.6, 0.3)])
	# ceiling beams and hanging lanterns inside (seen once the roof lifts away)
	var top := ph + wall_h
	var nbeam := maxi(1, int((x1 - x0) / 2.4))
	for i in nbeam:
		var bx := x0 + (i + 0.5) * (x1 - x0) / nbeam
		b.box(Vector3(bx, top - 0.05, cz), Vector3(0.2, 0.22, z1 - z0), beam)
	var nl := maxi(1, int((x1 - x0) / 4.5))
	for i in nl:
		var lpos := Vector3(x0 + (i + 0.5) * (x1 - x0) / nl, top - 0.75, cz)
		b.limb(lpos + Vector3(0, 0.45, 0), lpos + Vector3(0, 0.7, 0), 0.012, 0.012, trim, 4)
		_lantern(b, g, lpos, trim)
		lights.append([lpos, Color(1.0, 0.72, 0.45)])
	if st.get("moon_gate", false):
		_moon_gate(b, g, door, Rect2(x0, z0, x1 - x0, z1 - z0), ph, wall_h, th, st)
	# furniture
	for pr in props:
		_furnish(b, g, str(pr[0]), pr[1] + Vector3(0, ph, 0), Rect2(x0, z0, x1 - x0, z1 - z0), st, rng, lights)
	# ---- an upper storey (Part XI)
	if up != null:
		var floor_y := top
		var wall2 := 2.4
		# planks tile by tile, leaving the stairwell open
		for zi in int(round((z1 - z0) / T)) + 1:
			for xi in int(round((x1 - x0) / T)) + 1:
				var cx2 := x0 + xi * T
				var cz2 := z0 + zi * T
				if cx2 > x1 + 0.01 or cz2 > z1 + 0.01:
					continue
				var px0 := maxf(cx2 - T * 0.5, x0)
				var px1 := minf(cx2 + T * 0.5, x1)
				var pz0 := maxf(cz2 - T * 0.5, z0)
				var pz1 := minf(cz2 + T * 0.5, z1)
				if absf(cx2 - hole.x) < T * 0.4 and absf(cz2 - hole.z) < T * 0.4:
					continue
				up.box(Vector3((px0 + px1) * 0.5, floor_y + 0.03, (pz0 + pz1) * 0.5), Vector3(px1 - px0, 0.08, pz1 - pz0), plank)
				# the seams between boards every half metre along the long side, as on the ground floor
				for k6 in 4:
					if along_x:
						up.box(Vector3((px0 + px1) * 0.5, floor_y + 0.075, pz0 + (k6 + 0.5) * (pz1 - pz0) / 4.0), Vector3(px1 - px0, 0.01, 0.03), plank_d)
					else:
						up.box(Vector3(px0 + (k6 + 0.5) * (px1 - px0) / 4.0, floor_y + 0.075, (pz0 + pz1) * 0.5), Vector3(0.03, 0.01, pz1 - pz0), plank_d)
		for sd2 in sides:
			var a2: Vector3 = sd2[0]
			var e2: Vector3 = sd2[1]
			var horiz2 := absf(a2.z - e2.z) < 0.01
			var lo2: float = (minf(a2.x, e2.x) if horiz2 else minf(a2.z, e2.z)) - th * 0.5
			var hi2: float = (maxf(a2.x, e2.x) if horiz2 else maxf(a2.z, e2.z)) + th * 0.5
			var mid2 := (lo2 + hi2) * 0.5
			var ln2 := hi2 - lo2
			var pc2 := Vector3(mid2, 0, a2.z) if horiz2 else Vector3(a2.x, 0, mid2)
			var sz2 := Vector3(ln2, wall2, th) if horiz2 else Vector3(th, wall2, ln2)
			up.box(pc2 + Vector3(0, floor_y + wall2 * 0.5, 0), sz2, wall)
			up.box(pc2 + Vector3(0, floor_y + 0.05, 0), sz2 * Vector3(1, 0, 1) + Vector3(0.06 if not horiz2 else 0.0, 0.14, 0.06 if horiz2 else 0.0), beam)
			up.box(pc2 + Vector3(0, floor_y + wall2 - 0.1, 0), sz2 * Vector3(1, 0, 1) + Vector3(0.08 if not horiz2 else 0.0, 0.2, 0.08 if horiz2 else 0.0), beam)
			var nwin2 := int(ln2 / 2.2)
			for k5 in nwin2:
				var wp2 := lo2 + (k5 + 0.5) * ln2 / nwin2
				var wc2 := Vector3(wp2, floor_y + 1.35, a2.z) if horiz2 else Vector3(a2.x, floor_y + 1.35, wp2)
				var ws2 := Vector3(0.8, 0.8, th + 0.04) if horiz2 else Vector3(th + 0.04, 0.8, 0.8)
				up.box(wc2, ws2 + Vector3(0.1 if horiz2 else 0.0, 0.1, 0.0 if horiz2 else 0.1), column)
				up_g.box(wc2, ws2 * Vector3(0.85 if horiz2 else 1.02, 0.8, 1.02 if horiz2 else 0.85), Color(1.0, 0.85, 0.55, 0.35))
			for pnt2 in [a2, e2]:
				up.cyl(pnt2 + Vector3(0, floor_y + wall2 * 0.5, 0), 0.2, wall2 + 0.1, column, Vector3.ZERO, 10)
		var lup := Vector3(cx, floor_y + wall2 - 0.7, cz)
		_lantern(up, up_g, lup, trim)
		lights.append([lup, Color(1.0, 0.72, 0.45)])
		for pr3 in upper_props:
			_furnish(up, up_g, str(pr3[0]), pr3[1] + Vector3(0, floor_y + 0.07, 0), Rect2(x0, z0, x1 - x0, z1 - z0), st, rng, lights)
		top = floor_y + wall2
	# ---- the roof: eave beams, bracket sets at the corners and a curved hip roof
	var ry := top + 0.25
	for s4: float in [-1.0, 1.0]:
		roof.box(Vector3(cx, top + 0.08, cz + s4 * (z1 - z0) * 0.5), Vector3(x1 - x0 + 0.6, 0.3, 0.24), beam)
		roof.box(Vector3(cx + s4 * (x1 - x0) * 0.5, top + 0.08, cz), Vector3(0.24, 0.3, z1 - z0 + 0.6), beam)
		roof.box(Vector3(cx, top - 0.1, cz + s4 * ((z1 - z0) * 0.5 + 0.13)), Vector3(x1 - x0 + 0.6, 0.05, 0.04), trim)
	for c2 in [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x0, 0, z1), Vector3(x1, 0, z1)]:
		_dougong(roof, (c2 as Vector3) + Vector3(0, top + 0.2, 0), trim, beam, column)
	var hx := (x1 - x0) * 0.5
	var hz := (z1 - z0) * 0.5
	var kind: String = st.get("kind", "hip")
	if kind == "gable" or kind == "thatch":
		# a gabled roof with its ridge along the long side
		var along := hx >= hz
		var rise := 1.3 + minf(hx, hz) * 0.22
		var rc := MB.tag(_c(st.roof), MB.WOOD if kind == "thatch" else MB.STONE)
		var tmp := MB.new()
		_gable(tmp, Vector3.ZERO, (hx if along else hz) + 0.5, (hz if along else hx) + 0.55, rise, rc, kind == "thatch")
		var xf := Transform3D(Basis.IDENTITY if along else Basis(Vector3.UP, PI * 0.5), Vector3(cx, ry, cz))
		roof.merge(tmp, xf)
		# gable ends filled with wall
		for s5: float in [-1.0, 1.0]:
			var gt := MB.new()
			for k in 6:
				var f := (k + 0.5) / 6.0
				var wv := (hz if along else hx) * (1.0 - f)
				gt.box(Vector3(0, rise * f * 0.98 - rise / 12.0, 0), Vector3(0.24, rise / 6.0 + 0.02, wv * 2.0), wall)
			roof.merge(gt, Transform3D(Basis.IDENTITY if along else Basis(Vector3.UP, PI * 0.5), Vector3(cx, ry, cz) + (Vector3(s5 * hx, 0, 0) if along else Vector3(0, 0, s5 * hz))))
		if st.get("horsehead", false):
			# stepped fire walls rising above the roof at both gable ends, capped with tiles and
			# ending in upturned "horse heads"
			var cap := MB.tag(_c(st.roof2), MB.STONE)
			for s6: float in [-1.0, 1.0]:
				var hw := MB.new()
				var half := (hz if along else hx) + 0.55
				for tier in 3:
					var w2 := half * (1.0 - tier / 3.0)
					var y_top := rise * (0.45 + 0.32 * tier) + 0.55
					for sd: float in [-1.0, 1.0]:
						var z_in := w2 - half / 3.0
						var mid := sd * (z_in + w2) * 0.5
						var len_ := w2 - z_in
						hw.box(Vector3(0, y_top * 0.5, mid), Vector3(0.36, y_top, len_ + 0.02), wall)
						hw.box(Vector3(0, y_top + 0.06, mid), Vector3(0.5, 0.12, len_ + 0.18), cap)
						hw.box(Vector3(0, y_top + 0.16, sd * (w2 + 0.04)), Vector3(0.42, 0.14, 0.2), cap)
				roof.merge(hw, Transform3D(Basis.IDENTITY if along else Basis(Vector3.UP, PI * 0.5), Vector3(cx, ry - 0.1, cz) + (Vector3(s6 * (hx + 0.32), 0, 0) if along else Vector3(0, 0, s6 * (hz + 0.32)))))
		if st.get("chimney", false):
			var chp := Vector3(cx + (hx * 0.55 if along else 0.0), ry, cz + (0.0 if along else hz * 0.55))
			roof.box(chp + Vector3(0, rise * 0.6, 0), Vector3(0.6, rise * 1.2 + 0.6, 0.6), MB.tag(Color("8a7a6a"), MB.STONE))
			roof_g.ball(chp + Vector3(0, rise * 1.25 + 0.4, 0), 0.3, Color(0.85, 0.85, 0.9, 0.18), true)
	elif st.double:
		hip_roof(roof, roof_g, Vector3(cx, ry + 0.2, cz), hx + 0.45, hz + 0.5, 0.9, 0.55, st, false)
		roof.box(Vector3(cx, ry + 0.75, cz), Vector3(x1 - x0 - 0.8, 0.9, z1 - z0 - 0.6), wall)
		hip_roof(roof, roof_g, Vector3(cx, ry + 1.25, cz), hx - 0.2, hz - 0.1, 0.95, 1.8, st)
		if st.get("balcony", false):
			# a gallery round the upper storey: a rail on posts just inside the lower eave
			for s7: float in [-1.0, 1.0]:
				roof.box(Vector3(cx, ry + 0.95, cz + s7 * (hz - 0.05)), Vector3(x1 - x0 - 0.5, 0.06, 0.06), column)
				roof.box(Vector3(cx + s7 * (hx - 0.05), ry + 0.95, cz), Vector3(0.06, 0.06, z1 - z0 - 0.5), column)
				for k2 in int((x1 - x0) / 0.6):
					roof.box(Vector3(x0 + 0.3 + k2 * 0.6, ry + 0.75, cz + s7 * (hz - 0.05)), Vector3(0.04, 0.4, 0.04), column)
	else:
		hip_roof(roof, roof_g, Vector3(cx, ry + 0.1, cz), hx + 0.4, hz + 0.45, 0.95, 1.6 + minf(hx, hz) * 0.15, st)
	if st.get("spire", false):
		# the Feathered Folk's tower (Part XI): a lantern turret rising out of the roof, with its own
		# little roof, a golden finial, and nests on the ridge where the eldest roost
		var tb := Vector3(cx, ry + 2.5, cz)
		roof.box(tb + Vector3(0, 1.3, 0), Vector3(3.2, 2.6, 3.2), wall)
		for s8: float in [-1.0, 1.0]:
			roof_g.box(tb + Vector3(s8 * 1.62, 1.5, 0), Vector3(0.05, 0.8, 1.2), Color(1.0, 0.85, 0.55, 0.45))
			roof_g.box(tb + Vector3(0, 1.5, s8 * 1.62), Vector3(1.2, 0.8, 0.05), Color(1.0, 0.85, 0.55, 0.45))
			roof.box(tb + Vector3(s8 * 1.62, 1.3, 0), Vector3(0.08, 2.6, 0.22), column)
		hip_roof(roof, roof_g, tb + Vector3(0, 2.7, 0), 1.7, 1.7, 0.7, 1.5, st)
		roof.cyl(tb + Vector3(0, 4.9, 0), 0.08, 1.4, trim, Vector3.ZERO, 8)
		roof.ball(tb + Vector3(0, 5.7, 0), 0.22, trim, true)
		for s9: float in [-1.0, 1.0]:
			var np := Vector3(cx, ry + 2.9, cz) + (Vector3(s9 * (hx - 1.0), 0, 0) if hx >= hz else Vector3(0, 0, s9 * (hz - 1.0)))
			roof.torus(np, 0.45, 0.16, MB.tag(Color("8a6a3a"), MB.WOOD))
	if st.get("louver", false) and (kind == "gable" or kind == "thatch"):
		# a raised louver along the ridge: a little roof on posts over a gap, and the steam coming out
		var alongl := hx >= hz
		var risel := 1.3 + minf(hx, hz) * 0.22
		var lv := MB.new()
		var ll := (hx if alongl else hz) * 0.55
		for k5 in 4:
			var xk := -ll + k5 * ll * 2.0 / 3.0
			for s10: float in [-1.0, 1.0]:
				lv.box(Vector3(xk, 0.25, s10 * 0.45), Vector3(0.1, 0.5, 0.1), column)
		_gable(lv, Vector3(0, 0.5, 0), ll + 0.2, 0.75, 0.45, MB.tag(_c(st.roof2), MB.STONE), false)
		roof.merge(lv, Transform3D(Basis.IDENTITY if alongl else Basis(Vector3.UP, PI * 0.5), Vector3(cx, ry + risel, cz)))
		for k6 in 3:
			roof_g.ball(Vector3(cx, ry + risel + 1.3 + k6 * 0.45, cz) + (Vector3((k6 - 1) * ll * 0.6, 0, 0) if alongl else Vector3(0, 0, (k6 - 1) * ll * 0.6)), 0.35 + k6 * 0.12, Color(0.92, 0.92, 0.95, 0.16), true)
	if st.get("lotus_finial", false):
		# a bronze lotus bud on the ridge, its petals opening, on a little drum
		var fy := ry + 1.6 + minf(hx, hz) * 0.15 + 0.05
		var fc := Vector3(cx, fy, cz) + (Vector3(hx * 0.45, 0, 0) if hx >= hz else Vector3(0, 0, hz * 0.45))
		roof.cyl(fc + Vector3(0, 0.15, 0), 0.16, 0.3, trim, Vector3.ZERO, 10)
		for k7 in 8:
			var a7 := TAU * k7 / 8.0
			roof.leaf(fc + Vector3(0, 0.3, 0), fc + Vector3(cos(a7) * 0.32, 0.62, sin(a7) * 0.32), 0.16, MB.tag(_c(st.trim), MB.METAL), Vector3(-sin(a7), 0, cos(a7)))
		roof.lathe(fc + Vector3(0, 0.3, 0), [Vector2(0.12, 0.0), Vector2(0.16, 0.2), Vector2(0.08, 0.42), Vector2(0.01, 0.5)], MB.tag(Color("f0c8d0"), MB.METAL), 10)
	if int(st.get("tiers", 0)) > 0:
		# a small pagoda of `tiers` storeys rising out of the middle of the roof (a drum tower, a
		# reading room for the stars)
		var tb2 := Vector3(cx, ry + 1.15, cz) - (Vector3(hx * 0.3, 0, 0) if hx >= hz else Vector3(0, 0, hz * 0.3))
		var py := 0.0
		for tier in int(st.tiers):
			var w2 := 2.2 - tier * 0.5
			var hh := 1.2 - tier * 0.1
			roof.box(tb2 + Vector3(0, py + hh * 0.5, 0), Vector3(w2, hh, w2), wall)
			for s11: float in [-1.0, 1.0]:
				roof_g.box(tb2 + Vector3(0, py + hh * 0.55, s11 * (w2 * 0.5 + 0.01)), Vector3(w2 * 0.45, hh * 0.45, 0.02), Color(1.0, 0.85, 0.6, 0.45))
				roof_g.box(tb2 + Vector3(s11 * (w2 * 0.5 + 0.01), py + hh * 0.55, 0), Vector3(0.02, hh * 0.45, w2 * 0.45), Color(1.0, 0.85, 0.6, 0.45))
				# round windows on the tower too
				roof.torus(tb2 + Vector3(0, py + hh * 0.55, s11 * (w2 * 0.5 + 0.03)), w2 * 0.22, 0.04, column, Vector3(PI * 0.5, 0, 0))
			for cx2: float in [-1.0, 1.0]:
				for cz2: float in [-1.0, 1.0]:
					roof.cyl(tb2 + Vector3(cx2 * w2 * 0.5, py + hh * 0.5, cz2 * w2 * 0.5), 0.07, hh, column, Vector3.ZERO, 8)
			hip_roof(roof, roof_g, tb2 + Vector3(0, py + hh + 0.05, 0), w2 * 0.5, w2 * 0.5, 0.45, 0.5, st, false)
			py += hh + 0.5
		roof.cyl(tb2 + Vector3(0, py + 0.35, 0), 0.04, 0.7, trim, Vector3.ZERO, 6)
		roof.ball(tb2 + Vector3(0, py + 0.75, 0), 0.1, trim, true)
	if st.has("awning"):
		# a cloth awning over the shop front and a tall signboard by the door
		var horiz2 := absf(door.z - z0) < T * 0.6 or absf(door.z - z1) < T * 0.6
		var out_v := (Vector3(0, 0, -1) if absf(door.z - z0) < T * 0.6 else Vector3(0, 0, 1)) if horiz2 else (Vector3(-1, 0, 0) if absf(door.x - x0) < T * 0.6 else Vector3(1, 0, 0))
		var aw := MB.tag(_c(st.awning), MB.CLOTH)
		var ac := Vector3(door.x, ph + 2.25, door.z) + out_v * 0.75
		b.box(ac, Vector3(3.2, 0.06, 1.4) if horiz2 else Vector3(1.4, 0.06, 3.2), aw)
		for k3 in 5:
			var off2 := (k3 - 2) * 0.7
			b.box(ac + out_v * 0.72 + (Vector3(off2, -0.12, 0) if horiz2 else Vector3(0, -0.12, off2)), Vector3(0.62, 0.22, 0.04) if horiz2 else Vector3(0.04, 0.22, 0.62), MB.tag(_c(st.awning).lightened(0.25 if k3 % 2 else 0.0), MB.CLOTH))
		var sp := Vector3(door.x, 0, door.z) + out_v * 1.45 + (Vector3(1.9, 0, 0) if horiz2 else Vector3(0, 0, 1.9))
		b.cyl(sp + Vector3(0, 1.7, 0), 0.06, 3.4, column, Vector3.ZERO, 8)
		b.box(sp + Vector3(0, 2.3, 0) + (Vector3(0.0, 0, 0)), Vector3(0.5, 1.6, 0.06) if horiz2 else Vector3(0.06, 1.6, 0.5), MB.tag(Color("f0e2c0"), MB.CLOTH))
		for k4 in 4:
			b.box(sp + Vector3(0, 2.85 - k4 * 0.36, 0) + out_v * 0.04, Vector3(0.26, 0.2, 0.05) if horiz2 else Vector3(0.05, 0.2, 0.26), MB.tag(Color("2a1a1a"), MB.CLOTH))
	return lights

## A moon gate (the Lotus release): a round stone frame about the doorway in the wall the door is in,
## with a carved band over it, and round lattice windows in the other walls in place of square ones'
## frames (a lantern glow behind each).
static func _moon_gate(b: MB, g: MB, door: Vector3, inner: Rect2, ph: float, wall_h: float, th: float, st: Dictionary) -> void:
	var T := Terrain3D.T
	var frame := MB.tag(Color("e8e4dc"), MB.STONE)
	var horiz := absf(door.z - inner.position.y) < T * 0.6 or absf(door.z - inner.end.y) < T * 0.6
	var rot := Vector3(PI * 0.5, 0, 0) if horiz else Vector3(0, 0, PI * 0.5)
	var dc := Vector3(door.x, ph + 1.05, door.z)
	# the ring stands proud of the wall on both faces
	for s: float in [-1.0, 1.0]:
		var face := (Vector3(0, 0, s * (th * 0.5 + 0.04)) if horiz else Vector3(s * (th * 0.5 + 0.04), 0, 0))
		b.torus(dc + face, 1.12, 0.1, frame, rot, true)
		b.torus(dc + face * 1.3, 1.2, 0.04, MB.tag(_c(st.trim), MB.METAL), rot)
	# a carved name band over the gate
	var band := dc + Vector3(0, 1.32, 0)
	b.box(band, Vector3(1.4, 0.3, th + 0.12) if horiz else Vector3(th + 0.12, 0.3, 1.4), MB.tag(_c(st.beam), MB.WOOD))
	for k in 3:
		var off := (k - 1) * 0.36
		b.box(band + (Vector3(off, 0, 0) if horiz else Vector3(0, 0, off)), Vector3(0.18, 0.18, th + 0.16) if horiz else Vector3(th + 0.16, 0.18, 0.18), MB.tag(Color("2a2a30"), MB.CLOTH))
	# round windows: a ring and a lattice disc in the middle of each other wall
	var cxm := inner.get_center().x
	var czm := inner.get_center().y
	var walls := [[Vector3(cxm, 0, inner.position.y), true], [Vector3(cxm, 0, inner.end.y), true], [Vector3(inner.position.x, 0, czm), false], [Vector3(inner.end.x, 0, czm), false]]
	for wv in walls:
		var wp: Vector3 = wv[0]
		var wh: bool = wv[1]
		if (wh and horiz and absf(wp.z - door.z) < T * 0.6) or (not wh and not horiz and absf(wp.x - door.x) < T * 0.6):
			continue
		var wc := wp + Vector3(0, ph + 1.75, 0)
		var wr := Vector3(PI * 0.5, 0, 0) if wh else Vector3(0, 0, PI * 0.5)
		for s2: float in [-1.0, 1.0]:
			var f2 := Vector3(0, 0, s2 * (th * 0.5 + 0.03)) if wh else Vector3(s2 * (th * 0.5 + 0.03), 0, 0)
			b.torus(wc + f2, 0.48, 0.06, frame, wr)
			b.box(wc + f2, Vector3(0.9, 0.04, 0.04) if wh else Vector3(0.04, 0.04, 0.9), MB.tag(_c(st.column).darkened(0.4), MB.WOOD))
			b.box(wc + f2, Vector3(0.04, 0.9, 0.04), MB.tag(_c(st.column).darkened(0.4), MB.WOOD))
		g.disc(wc, 0.44, Color(1.0, 0.82, 0.55, 0.35), 16, Color(1.0, 0.82, 0.55, 0.2), wr)

static func _lantern(b: MB, g: MB, lp: Vector3, trim: Color) -> void:
	b.lathe(lp, [Vector2(0.06, 0.0), Vector2(0.2, 0.1), Vector2(0.22, 0.25), Vector2(0.17, 0.4), Vector2(0.06, 0.46)], MB.tag(Color("e04a3a"), MB.CLOTH), 10)
	b.ribbon([lp, lp + Vector3(0, -0.25, 0)], [0.03, 0.01], Vector3.RIGHT, MB.tag(Color("f0c850"), MB.CLOTH))
	g.ball(lp + Vector3(0, 0.23, 0), 0.36, Color(1.0, 0.5, 0.25, 0.3), true)

## Furniture: `p` is a floor tile centre; wall pieces back onto the nearest wall of `inner`.
static func _furnish(b: MB, g: MB, kind: String, p: Vector3, inner: Rect2, st: Dictionary, rng: RandomNumberGenerator, lights: Array) -> void:
	var wood := MB.tag(Color("7a4a2e"), MB.WOOD)
	var wood_l := MB.tag(Color("a87a4a"), MB.WOOD)
	var lacquer := MB.tag(Color("8a2a22"), MB.WOOD)
	var bronze := MB.tag(Color("7a6a3a"), MB.METAL)
	var iron := MB.tag(Color("44444c"), MB.METAL)
	var paper := MB.tag(Color("efe6d0"), MB.CLOTH)
	var trim := MB.tag(_c(st.trim), MB.METAL)
	# direction to the nearest wall, and the yaw that turns a piece to face away from it
	var dl := p.x - inner.position.x
	var dr := inner.end.x - p.x
	var du := p.z - inner.position.y
	var dd := inner.end.y - p.z
	var m := minf(minf(dl, dr), minf(du, dd))
	var back := Vector3(-1, 0, 0) if m == dl else (Vector3(1, 0, 0) if m == dr else (Vector3(0, 0, -1) if m == du else Vector3(0, 0, 1)))
	var side := Vector3(back.z, 0, -back.x)
	var wallp := p + back * (m - 0.25)
	var ax := absf(back.x) > 0.5
	match kind:
		"altar":
			b.box(p + Vector3(0, 0.45, 0), Vector3(1.9, 0.08, 0.9), lacquer)
			for s: float in [-1.0, 1.0]:
				for s2: float in [-1.0, 1.0]:
					b.box(p + Vector3(s * 0.85, 0.22, s2 * 0.38), Vector3(0.1, 0.44, 0.1), lacquer)
			b.box(p + Vector3(0, 0.5, 0), Vector3(1.95, 0.04, 0.95), MB.tag(Color("e8c860"), MB.CLOTH))
			b.lathe(p + Vector3(0, 0.52, 0), [Vector2(0.18, 0.0), Vector2(0.22, 0.1), Vector2(0.2, 0.22), Vector2(0.24, 0.26)], bronze, 10)
			for k in 3:
				b.limb(p + Vector3(-0.05 + k * 0.05, 0.75, 0), p + Vector3(-0.05 + k * 0.05, 1.05, 0), 0.008, 0.008, MB.tag(Color("c84a2a"), MB.WOOD), 3)
				g.ball(p + Vector3(-0.05 + k * 0.05, 1.07, 0), 0.03, Color(1.0, 0.5, 0.2, 0.9), true)
			for s3: float in [-1.0, 1.0]:
				b.lathe(p + Vector3(s3 * 0.7, 0.52, 0), [Vector2(0.06, 0.0), Vector2(0.05, 0.25), Vector2(0.09, 0.3)], bronze, 8)
				g.ball(p + Vector3(s3 * 0.7, 0.86, 0), 0.06, Color(1.0, 0.8, 0.4, 0.9), true)
			lights.append([p + Vector3(0, 1.4, 0), Color(1.0, 0.75, 0.45)])
		"statue":
			# the sect founder, seated in meditation on a lotus pedestal against the back wall
			var sp := wallp + Vector3(0, 0, 0)
			b.lathe(sp, [Vector2(0.75, 0.0), Vector2(0.7, 0.35), Vector2(0.55, 0.45), Vector2(0.8, 0.6)], MB.tag(Color("c8b070"), MB.METAL), 14)
			b.sph(sp + Vector3(0, 1.0, 0), Vector3(0.55, 0.5, 0.42), MB.tag(Color("d8b860"), MB.METAL))
			b.sph(sp + Vector3(0, 1.55, 0), Vector3(0.3, 0.45, 0.25), MB.tag(Color("d8b860"), MB.METAL))
			b.ball(sp + Vector3(0, 2.15, 0), 0.22, MB.tag(Color("e0c070"), MB.METAL))
			g.disc(sp + Vector3(0, 2.2, 0) + back * 0.25, 0.55, Color(1.0, 0.85, 0.4, 0.35), 20, Color(1.0, 0.85, 0.4, 0.0), Vector3(PI * 0.5, 0, 0) if not ax else Vector3(0, 0, PI * 0.5))
		"cushion":
			b.sph(p + Vector3(0, 0.08, 0), Vector3(0.35, 0.08, 0.35), MB.tag(Color("c8a040"), MB.CLOTH))
		"scroll":
			# a hanging calligraphy scroll on the wall
			var sc := wallp + Vector3(0, 1.6, 0) - back * 0.05
			b.box(sc, Vector3(0.04, 1.3, 0.55) if ax else Vector3(0.55, 1.3, 0.04), paper)
			for k2 in 4:
				b.box(sc + Vector3(0, 0.35 - k2 * 0.22, 0) - back * 0.02, Vector3(0.02, 0.1, 0.12) if ax else Vector3(0.12, 0.1, 0.02), MB.tag(Color("1a1a1a"), MB.CLOTH))
			b.cyl(sc + Vector3(0, -0.7, 0), 0.04, 0.7, wood, Vector3(PI * 0.5, 0, 0) if ax else Vector3(0, 0, PI * 0.5), 6)
		"shelf", "bookshelf":
			var shp := wallp - back * 0.1
			var w2 := Vector3(0.4, 0, 1.7) if ax else Vector3(1.7, 0, 0.4)
			for lv in 5:
				b.box(shp + Vector3(0, 0.05 + lv * 0.48, 0), w2 + Vector3(0, 0.05, 0), wood)
			for s4: float in [-1.0, 1.0]:
				b.box(shp + side * s4 * 0.85 + Vector3(0, 1.0, 0), Vector3(0.06 if not ax else 0.4, 2.0, 0.4 if not ax else 0.06), wood)
			for lv2 in 4:
				var n := 6 + rng.randi() % 4
				for k3 in n:
					var o := -0.75 + (k3 + 0.5) * 1.5 / n
					var it := shp + side * o + Vector3(0, 0.1 + lv2 * 0.48, 0)
					if kind == "bookshelf":
						var bc: Color = [Color("6a2a2a"), Color("2a4a6a"), Color("e8dcc0"), Color("4a5a2a")][rng.randi() % 4]
						b.box(it + Vector3(0, 0.17, 0), Vector3(0.28, 0.34, 0.12) if ax else Vector3(0.12, 0.34, 0.28), MB.tag(bc, MB.CLOTH))
					else:
						var jc: Color = [Color("6a8a5a"), Color("c8b8a0"), Color("4a6a8a"), Color("a86a3a")][rng.randi() % 4]
						b.lathe(it, [Vector2(0.06, 0.0), Vector2(0.09, 0.08), Vector2(0.08, 0.2), Vector2(0.04, 0.24), Vector2(0.05, 0.28)], MB.tag(jc, MB.STONE), 8)
		"counter", "desk", "table":
			var tw := 1.6 if kind != "table" else 1.2
			b.box(p + Vector3(0, 0.78 if kind == "counter" else 0.62, 0), Vector3(tw, 0.08, 0.7), wood_l)
			if kind == "counter":
				b.box(p + Vector3(0, 0.38, 0), Vector3(tw - 0.1, 0.76, 0.6), wood)
				b.box(p + Vector3(0.4, 0.86, 0), Vector3(0.3, 0.08, 0.2), MB.tag(Color("3a3a3a"), MB.WOOD))  # abacus
				for k4 in 5:
					b.ball(p + Vector3(0.3 + k4 * 0.05, 0.92, 0), 0.025, MB.tag(Color("c84a2a"), MB.WOOD), true)
			else:
				for s5: float in [-1.0, 1.0]:
					for s6: float in [-1.0, 1.0]:
						b.box(p + Vector3(s5 * (tw * 0.5 - 0.08), 0.3, s6 * 0.27), Vector3(0.07, 0.6, 0.07), wood)
				if kind == "desk":
					b.box(p + Vector3(-0.3, 0.68, 0), Vector3(0.5, 0.02, 0.35), paper)
					b.cyl(p + Vector3(0.3, 0.72, 0.1), 0.05, 0.1, MB.tag(Color("2a2a2a"), MB.STONE))
					b.limb(p + Vector3(0.1, 0.67, -0.1), p + Vector3(0.35, 0.67, -0.12), 0.01, 0.006, wood, 4)
				else:
					b.lathe(p + Vector3(0, 0.66, 0), [Vector2(0.08, 0.0), Vector2(0.11, 0.08), Vector2(0.06, 0.16), Vector2(0.03, 0.2)], MB.tag(Color("e8e8f0"), MB.STONE), 10)
					for s7: float in [-1.0, 1.0]:
						b.cyl(p + Vector3(s7 * 0.35, 0.68, 0.12), 0.05, 0.06, MB.tag(Color("e8e8f0"), MB.STONE))
		"stool":
			b.cyl(p + Vector3(0, 0.25, 0), 0.22, 0.5, wood_l, Vector3.ZERO, 10)
		"cauldron":
			b.lathe(p + Vector3(0, 0.15, 0), [Vector2(0.2, 0.0), Vector2(0.6, 0.15), Vector2(0.65, 0.5), Vector2(0.55, 0.7), Vector2(0.62, 0.74)], iron, 14)
			for k5 in 3:
				var a := TAU * k5 / 3.0
				b.limb(p + Vector3(cos(a) * 0.4, 0.2, sin(a) * 0.4), p + Vector3(cos(a) * 0.55, 0.0, sin(a) * 0.55), 0.06, 0.05, iron, 6)
			g.disc(p + Vector3(0, 0.84, 0), 0.5, Color(0.4, 1.0, 0.6, 0.7), 14, Color(0.4, 1.0, 0.6, 0.2))
			g.ball(p + Vector3(0, 0.1, 0), 0.35, Color(1.0, 0.5, 0.2, 0.55), true)
			for k6 in 3:
				g.ball(p + Vector3(0, 1.1 + k6 * 0.35, 0), 0.15 + k6 * 0.06, Color(0.6, 1.0, 0.7, 0.12), true)
			lights.append([p + Vector3(0, 1.0, 0), Color(0.5, 1.0, 0.6)])
		"herbs":
			var hp := wallp - back * 0.15
			for s8: float in [-1.0, 1.0]:
				b.cyl(hp + side * s8 * 0.6 + Vector3(0, 0.9, 0), 0.04, 1.8, wood, Vector3.ZERO, 6)
			b.limb(hp - side * 0.6 + Vector3(0, 1.7, 0), hp + side * 0.6 + Vector3(0, 1.7, 0), 0.03, 0.03, wood, 6)
			for k7 in 5:
				var bp := hp + side * (-0.45 + k7 * 0.22) + Vector3(0, 1.5, 0)
				b.cone(bp, 0.08, 0.36, MB.tag(Color("6a8a3a").lerp(Color("a8a050"), rng.randf()), MB.FOLIAGE), Vector3(PI, 0, 0), 6)
		"hearth":
			var fp := wallp - back * 0.2
			b.box(fp + Vector3(0, 0.55, 0), Vector3(1.3, 1.1, 1.0) if not ax else Vector3(1.0, 1.1, 1.3), MB.tag(Color("8a5a4a"), MB.STONE))
			b.box(fp + Vector3(0, 2.0, 0) + back * 0.15, Vector3(0.7, 1.9, 0.7), MB.tag(Color("7a4a3a"), MB.STONE))
			g.box(fp + Vector3(0, 0.75, 0) - back * 0.5, Vector3(0.8, 0.4, 0.05) if not ax else Vector3(0.05, 0.4, 0.8), Color(1.0, 0.45, 0.15, 0.9))
			g.ball(fp + Vector3(0, 1.0, 0), 0.5, Color(1.0, 0.4, 0.1, 0.35), true)
			lights.append([fp + Vector3(0, 1.0, 0) - back * 0.8, Color(1.0, 0.5, 0.2)])
		"anvil":
			b.box(p + Vector3(0, 0.3, 0), Vector3(0.35, 0.6, 0.3), wood)
			b.box(p + Vector3(0, 0.68, 0), Vector3(0.75, 0.16, 0.28), iron)
			b.cone(p + Vector3(0.48, 0.68, 0), 0.08, 0.3, iron, Vector3(0, 0, -PI * 0.5), 6)
			b.limb(p + Vector3(-0.1, 0.78, 0.05), p + Vector3(0.2, 0.8, 0.25), 0.02, 0.02, wood, 4)
			b.box(p + Vector3(0.22, 0.82, 0.27), Vector3(0.14, 0.08, 0.08), iron)
		"rack":
			var rp := wallp - back * 0.1
			b.box(rp + Vector3(0, 0.9, 0), Vector3(0.12, 0.1, 1.6) if ax else Vector3(1.6, 0.1, 0.12), wood)
			b.box(rp + Vector3(0, 0.15, 0), Vector3(0.3, 0.1, 1.6) if ax else Vector3(1.6, 0.1, 0.3), wood)
			for k8 in 5:
				var bl := rp + side * (-0.6 + k8 * 0.3)
				b.box(bl + Vector3(0, 0.75, 0), Vector3(0.03, 1.3, 0.06) if not ax else Vector3(0.06, 1.3, 0.03), MB.tag(Color("c8ccd8"), MB.METAL))
				b.box(bl + Vector3(0, 0.12, 0), Vector3(0.12, 0.05, 0.05), trim)
		"tub":
			# a cedar bath (the Lotus release): staves, iron hoops, a step, and hot water to the brim
			b.lathe(p, [Vector2(0.62, 0.0), Vector2(0.66, 0.35), Vector2(0.68, 0.62), Vector2(0.62, 0.64)], MB.tag(Color("b88a5a"), MB.WOOD), 16)
			for k8 in 2:
				b.torus(p + Vector3(0, 0.15 + k8 * 0.38, 0), 0.67, 0.025, iron)
			g.disc(p + Vector3(0, 0.56, 0), 0.6, Color(0.5, 0.8, 0.78, 0.7), 16)
			b.box(p - back * 0.0 + side * 0.0 + (-back) * 0.78 + Vector3(0, 0.12, 0), Vector3(0.5, 0.24, 0.3) if ax else Vector3(0.3, 0.24, 0.5), wood_l)
			g.ball(p + Vector3(0, 1.0, 0), 0.4, Color(0.95, 0.95, 1.0, 0.12), true)
		"barrel":
			b.lathe(p, [Vector2(0.3, 0.0), Vector2(0.36, 0.35), Vector2(0.3, 0.7)], wood, 12)
			b.torus(p + Vector3(0, 0.15, 0), 0.33, 0.02, iron)
			b.torus(p + Vector3(0, 0.55, 0), 0.33, 0.02, iron)
			b.disc(p + Vector3(0, 0.71, 0), 0.28, MB.tag(Color("3a5a7a"), MB.STONE), 12)
		"bed":
			var bp2 := wallp - back * 0.5
			b.box(bp2 + Vector3(0, 0.3, 0), Vector3(1.0, 0.25, 1.9) if not ax else Vector3(1.9, 0.25, 1.0), wood)
			b.box(bp2 + Vector3(0, 0.48, 0), Vector3(0.9, 0.12, 1.8) if not ax else Vector3(1.8, 0.12, 0.9), MB.tag(Color("c86a5a"), MB.CLOTH))
			b.box(bp2 + Vector3(0, 0.55, 0) + (Vector3(0, 0, -0.7) if not ax else Vector3(-0.7, 0, 0)), Vector3(0.6, 0.1, 0.3) if not ax else Vector3(0.3, 0.1, 0.6), paper)
		"stove":
			var sv := wallp - back * 0.2
			b.box(sv + Vector3(0, 0.4, 0), Vector3(1.2, 0.8, 0.8) if not ax else Vector3(0.8, 0.8, 1.2), MB.tag(Color("b8a890"), MB.STONE))
			b.lathe(sv + Vector3(0, 0.8, 0), [Vector2(0.3, 0.0), Vector2(0.35, 0.15), Vector2(0.2, 0.25)], iron, 12)
			g.box(sv + Vector3(0, 0.25, 0) - back * 0.41, Vector3(0.4, 0.25, 0.04) if not ax else Vector3(0.04, 0.25, 0.4), Color(1.0, 0.45, 0.15, 0.8))
			lights.append([sv + Vector3(0, 0.6, 0) - back * 0.8, Color(1.0, 0.55, 0.25)])
		"cabinet":
			var cb := wallp - back * 0.15
			b.box(cb + Vector3(0, 0.75, 0), Vector3(0.45, 1.5, 1.1) if ax else Vector3(1.1, 1.5, 0.45), lacquer)
			b.box(cb + Vector3(0, 0.75, 0) - back * 0.23, Vector3(0.02, 1.3, 0.02) if ax else Vector3(0.02, 1.3, 0.02), trim)
		"loom":
			var lm := p
			for s9: float in [-1.0, 1.0]:
				b.box(lm + side * s9 * 0.7 + Vector3(0, 0.8, 0), Vector3(0.1, 1.6, 0.1), wood)
			b.limb(lm - side * 0.7 + Vector3(0, 1.5, 0), lm + side * 0.7 + Vector3(0, 1.5, 0), 0.05, 0.05, wood, 6)
			b.limb(lm - side * 0.7 + Vector3(0, 0.5, 0), lm + side * 0.7 + Vector3(0, 0.5, 0), 0.05, 0.05, wood, 6)
			b.box(lm + Vector3(0, 1.0, 0), (Vector3(0.02, 0.95, 1.3) if ax else Vector3(1.3, 0.95, 0.02)), MB.tag(Color("d0a0c8"), MB.CLOTH))
		"lantern":
			_lantern(b, g, p + Vector3(0, 1.4, 0), trim)
			lights.append([p + Vector3(0, 1.6, 0), Color(1.0, 0.65, 0.35)])
		# ---- Part XI: stairs between storeys, and the Feathered Folk's nests
		"stairs_up":
			# a steep flight of steps up the tile towards the nearest wall, rising one storey (2.6 m)
			var fwd2 := back
			var start := p - fwd2 * 0.85
			for k9 in 8:
				var sp2 := start + fwd2 * (k9 * 0.24) + Vector3(0, 0.16 + k9 * 0.33, 0)
				b.box(sp2, Vector3(1.4, 0.1, 0.34) if absf(fwd2.z) > 0.5 else Vector3(0.34, 0.1, 1.4), wood_l)
			for s10: float in [-1.0, 1.0]:
				var rail_a := start + side * (s10 * 0.75) + Vector3(0, 0.6, 0)
				var rail_b := start + fwd2 * 1.75 + side * (s10 * 0.75) + Vector3(0, 3.1, 0)
				b.limb(rail_a, rail_b, 0.05, 0.05, lacquer, 6)
				b.limb(start + side * (s10 * 0.75), rail_a, 0.04, 0.04, lacquer, 5)
			g.box(p + Vector3(0, 0.04, 0) - fwd2 * 0.9, Vector3(0.9, 0.02, 0.18) if absf(fwd2.z) > 0.5 else Vector3(0.18, 0.02, 0.9), Color(1.0, 0.85, 0.4, 0.5))
		"stairs_down":
			# a hatch in the floor with stone steps going down into the dark, and a rail round it
			b.box(p + Vector3(0, 0.0, 0), Vector3(1.6, 0.06, 1.6), MB.tag(Color("141012"), MB.STONE))
			for k10 in 4:
				b.box(p + back * (0.5 - k10 * 0.3) + Vector3(0, -0.15 - k10 * 0.32, 0), Vector3(1.3, 0.1, 0.32) if absf(back.z) > 0.5 else Vector3(0.32, 0.1, 1.3), MB.tag(Color("6a6670"), MB.STONE))
			for s11: float in [-1.0, 1.0]:
				_railing(b, p + side * (s11 * 0.85) - back * 0.8, p + side * (s11 * 0.85) + back * 0.8, 0.9, lacquer)
			_railing(b, p - back * 0.85 - side * 0.85, p - back * 0.85 + side * 0.85, 0.9, lacquer)
			g.box(p + Vector3(0, 0.05, 0), Vector3(1.2, 0.02, 1.2), Color(1.0, 0.6, 0.3, 0.18))
		"stairs_hole":
			# the top of the stairwell on an upper floor: a dark shaft with the top of the flight in it,
			# stepping down from the wall side, and an open railing round the other three sides
			var shaft := MB.tag(Color("1a1416"), MB.WOOD)
			b.box(p + Vector3(0, -2.5, 0), Vector3(1.9, 0.1, 1.9), shaft)
			for q12: Vector3 in [side, -side, back, -back]:
				b.box(p + q12 * 0.93 + Vector3(0, -1.25, 0), Vector3(0.06, 2.45, 1.9) if absf(q12.x) > 0.5 else Vector3(1.9, 2.45, 0.06), shaft)
			for k12 in 4:
				b.box(p + back * (0.62 - k12 * 0.3) + Vector3(0, -0.2 - k12 * 0.33, 0), Vector3(1.4, 0.1, 0.32) if absf(back.z) > 0.5 else Vector3(0.32, 0.1, 1.4), wood_l)
			for s12: float in [-1.0, 1.0]:
				_railing(b, p + side * (s12 * 0.95) - back * 0.95, p + side * (s12 * 0.95) + back * 0.95, 1.0, lacquer)
			_railing(b, p - back * 0.95 - side * 0.95, p - back * 0.95 + side * 0.95, 1.0, lacquer)
		"nest":
			# a round nest of woven twigs with three eggs, for the Feathered Folk's chicks
			b.torus(p + Vector3(0, 0.22, 0), 0.5, 0.18, MB.tag(Color("8a6a3a"), MB.WOOD))
			b.disc(p + Vector3(0, 0.12, 0), 0.5, MB.tag(Color("6a4a2a"), MB.WOOD), 12)
			for k11 in 3:
				var a11 := TAU * k11 / 3.0 + rng.randf() * 0.4
				b.sph(p + Vector3(cos(a11) * 0.2, 0.3, sin(a11) * 0.2), Vector3(0.12, 0.16, 0.12), MB.tag(Color("f4f0e4").darkened(rng.randf() * 0.1), MB.STONE))
			g.ball(p + Vector3(0, 0.35, 0), 0.6, Color(1.0, 0.85, 0.6, 0.12), true)
		_:
			# the Hollow Hills release: the twelve new pieces (rooms.gd)
			if not Rooms.furnish(b, g, kind, p, wallp, back, side, rng, lights):
				b.box(p + Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 0.6), wood)


## An open railing along the floor from `a` to `e`: a post at each end, a top rail, a middle rail and
## balusters between them (Part XI: round stairwells).
static func _railing(b: MB, a: Vector3, e: Vector3, h: float, mat: Color) -> void:
	for q: Vector3 in [a, e]:
		b.box(q + Vector3(0, h * 0.5, 0), Vector3(0.09, h, 0.09), mat)
	b.limb(a + Vector3(0, h, 0), e + Vector3(0, h, 0), 0.045, 0.045, mat, 6)
	b.limb(a + Vector3(0, h * 0.45, 0), e + Vector3(0, h * 0.45, 0), 0.03, 0.03, mat, 5)
	var n := maxi(2, int(a.distance_to(e) / 0.3))
	for i in range(1, n):
		var q2 := a.lerp(e, float(i) / n)
		b.box(q2 + Vector3(0, h * 0.5, 0), Vector3(0.035, h, 0.035), mat)

## A cellar (Part XI): a stone room the size of the building's rectangle `r` (its own XZ, from the
## corner), floor at y 0, thick walls of dressed stone up to just under the ground, timber posts,
## lanterns on the walls, its furniture (`props`: [kind, tile centre]) and the stairs up (`stairs`).
## No ceiling: the camera looks down into it.  Returns lights [[pos, colour], ...].
static func cellar(b: MB, g: MB, r: Rect2, props: Array, stairs: Vector3, seed_: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var T := Terrain3D.T
	var st: Dictionary = STYLES.house
	var lights: Array = []
	var x0 := r.position.x + T * 0.5
	var x1 := r.end.x - T * 0.5
	var z0 := r.position.y + T * 0.5
	var z1 := r.end.y - T * 0.5
	var flag := MB.tag(Color("6a6460"), MB.STONE)
	var flag_d := MB.tag(Color("54504c"), MB.STONE)
	var wall := MB.tag(Color("7a746c"), MB.STONE)
	var wall_d := MB.tag(Color("5e5852"), MB.STONE)
	var post := MB.tag(Color("5a3a24"), MB.WOOD)
	var hgt := 2.6
	# flagstones, a slightly different stone every other one
	var nx := int(round((x1 - x0) / T)) + 1
	var nz := int(round((z1 - z0) / T)) + 1
	for zi in nz:
		for xi in nx:
			b.box(Vector3(x0 + xi * T, -0.05, z0 + zi * T), Vector3(T - 0.06, 0.1, T - 0.06), flag if (xi + zi + rng.randi() % 2) % 2 == 0 else flag_d)
	# walls on the ring of wall tiles, with courses of darker stone
	var runs := [[Vector3(x0, 0, z0), Vector3(x1, 0, z0)], [Vector3(x0, 0, z1), Vector3(x1, 0, z1)], [Vector3(x0, 0, z0), Vector3(x0, 0, z1)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1)]]
	for rn in runs:
		var a: Vector3 = rn[0]
		var e: Vector3 = rn[1]
		var horiz := absf(a.z - e.z) < 0.01
		var ln := (absf(e.x - a.x) if horiz else absf(e.z - a.z)) + 0.9
		var c := (a + e) * 0.5
		var sz := Vector3(ln, hgt, 0.9) if horiz else Vector3(0.9, hgt, ln)
		b.box(c + Vector3(0, hgt * 0.5, 0), sz, wall)
		for k in 3:
			b.box(c + Vector3(0, 0.5 + k * 0.8, 0), sz * Vector3(1, 0, 1) + Vector3(0.04 if not horiz else 0.0, 0.12, 0.04 if horiz else 0.0), wall_d)
		var np := maxi(1, int(ln / 3.0))
		for k2 in np + 1:
			var f := float(k2) / float(np)
			var pp := a.lerp(e, f)
			b.box(pp + Vector3(0, hgt * 0.5, 0), Vector3(0.28, hgt + 0.1, 0.28), post)
	# lanterns on the walls
	var lc := Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
	for lp in [Vector3(x0 + 0.5, 1.9, lc.z), Vector3(x1 - 0.5, 1.9, lc.z)]:
		_lantern(b, g, lp, MB.tag(Color("c8a040"), MB.METAL))
		lights.append([lp + Vector3(0, -0.2, 0), Color(1.0, 0.6, 0.3)])
	var inner := Rect2(x0, z0, x1 - x0, z1 - z0)
	for pr in props:
		_furnish(b, g, str(pr[0]), pr[1], inner, st, rng, lights)
	_furnish(b, g, "stairs_up", stairs, inner, st, rng, lights)
	return lights
