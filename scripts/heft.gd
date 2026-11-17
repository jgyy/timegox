class_name Heft
extends RefCounted
## The Five Hands release: what hangs, swings and turns does so because it has weight.
##
## Until this release everything a hand held was rigid with the hand (a lantern on its stick stood out
## sideways when the arm was raised, the baskets of a shoulder pole were welded to it), and what was
## used moved by a sine with an envelope (the swing, the bell).  Here are the three small pieces of
## mechanics that replace those, each a pure function of a state and a step of time, so that the tests
## can measure them (a pendulum's period is 2 pi sqrt(L / g), or it is not a pendulum):
##
## - `hang`: a weight on a cord whose other end is carried about (a lantern, a basket, a float on a
##   line): a point moved by its own velocity and by gravity, then put back on the cord.  The hand that
##   carries it drives it: start walking and it lags, stop and it swings on.
## - `pendulum`: an angle about a fixed axle (the bell on its beam, the swing on its ropes), pushed by a
##   torque: theta'' = -(g / L) sin theta - c theta' + push.
## - `bob`: something floating (a fisherman's float): a spring to the water's face, damped, and a tug.
##
## Nothing here is game state: all of it is drawn only, and with no window none of it runs.

const G := 9.8
## no step of the integration is longer than this (a frame of a slow machine is cut into several)
const STEP := 1.0 / 240.0

## The small-swing period of a weight on a cord of length `len` (seconds).
static func period(len: float) -> float:
	return TAU * sqrt(maxf(0.01, len) / G)

## A weight on a cord `len` long whose top is at `pivot` (world) now.  `s` is its state ({"p": where the
## weight is, "v": its velocity}; empty the first time: it starts hanging straight down, at rest).
## `drag` is the part of its speed the air takes in a second.  `floor_y`: it does not go below this (a
## float does not sink; a basket does not go through the ground).  Returns where the weight is.
static func hang(s: Dictionary, pivot: Vector3, dt: float, len: float, drag: float = 0.9, floor_y: float = -INF) -> Vector3:
	if not s.has("p") or dt <= 0.0 or dt > 0.5 or (s.p as Vector3).distance_to(pivot) > len * 4.0 + 1.0:
		# the first time, after a long pause, or when its bearer has been moved somewhere else: at rest
		s.p = pivot + Vector3(0, -len, 0)
		s.v = Vector3.ZERO
		if dt <= 0.0 or dt > 0.5:
			return s.p
	var n := maxi(1, int(ceil(dt / STEP)))
	var h := dt / float(n)
	var p: Vector3 = s.p
	var v: Vector3 = s.v
	for _i in n:
		v += Vector3(0, -G, 0) * h
		v *= maxf(0.0, 1.0 - drag * h)
		var q := p + v * h
		# back onto the cord (it is a cord, not a rod: it cannot push, but nothing here ever goes slack
		# for longer than a frame, and a rod reads better than a weight flying up past the hand)
		var off := q - pivot
		var ln := off.length()
		if ln > 1e-5:
			q = pivot + off / ln * len
		if q.y < floor_y:
			q.y = floor_y
		v = (q - p) / h
		p = q
	s.p = p
	s.v = v
	return p

## An angle about a fixed axle, for a weight `len` from it.  `s` is {"th", "om"}; `push` is an angular
## acceleration applied this step (a rider pumping, a hand on the rope); `damp` is the part of the
## angular speed lost in a second.  Returns the angle.
static func pendulum(s: Dictionary, dt: float, len: float, damp: float = 0.4, push: float = 0.0) -> float:
	if not s.has("th"):
		s.th = 0.0
		s.om = 0.0
	if dt <= 0.0 or dt > 0.5:
		return float(s.th)
	var n := maxi(1, int(ceil(dt / STEP)))
	var h := dt / float(n)
	var th: float = s.th
	var om: float = s.om
	var k := G / maxf(0.05, len)
	for _i in n:
		om += (-k * sin(th) - damp * om + push) * h
		th += om * h
	s.th = th
	s.om = om
	return th

## A blow on something that hangs: it is given angular speed at once (the striker's speed over the
## length of what it struck).
static func kick(s: Dictionary, speed: float) -> void:
	if not s.has("th"):
		s.th = 0.0
		s.om = 0.0
	s.om = float(s.om) + speed

## The energy of a pendulum for a unit of mass (kinetic and of height), to see that it only ever falls
## when nothing pushes.
static func energy(s: Dictionary, len: float) -> float:
	var om := float(s.get("om", 0.0))
	return 0.5 * len * len * om * om + G * len * (1.0 - cos(float(s.get("th", 0.0))))

## How a rider pumps a swing: with the way it is going while it is lower than `top`, and not at all
## once it is as high as wanted (so it settles about that height and dies away when he stops).
static func pump(s: Dictionary, len: float, top: float, strength: float = 1.6) -> float:
	var om := float(s.get("om", 0.0))
	var th := float(s.get("th", 0.0))
	# the height it will reach on this swing, as an angle
	var e := energy(s, len)
	var reach := acos(clampf(1.0 - e / (G * len), -1.0, 1.0))
	if reach >= top:
		return 0.0
	if absf(om) < 0.05 and absf(th) < 0.02:
		return strength
	return strength * signf(om)

## Something floating: its height `y` drawn to the water's face, damped, with a `tug` (an
## acceleration: a fish on the line pulls it under).  `s` is {"y", "v"}.
static func bob(s: Dictionary, dt: float, water: float, tug: float = 0.0, spring: float = 60.0, damp: float = 5.0) -> float:
	if not s.has("y"):
		s.y = water
		s.v = 0.0
	if dt <= 0.0 or dt > 0.5:
		return float(s.y)
	var n := maxi(1, int(ceil(dt / STEP)))
	var h := dt / float(n)
	var y: float = s.y
	var v: float = s.v
	for _i in n:
		v += (-spring * (y - water) - damp * v + tug) * h
		y += v * h
	s.y = y
	s.v = v
	return y

## The basis that hangs something drawn hanging down its own -Y so that it hangs along `down` instead
## (a unit vector), turning it as little as possible from `keep` (so that a lantern does not spin on
## its cord as the hand turns).
static func hung(down: Vector3, keep: Basis) -> Basis:
	var y := -down.normalized()
	var z := keep.z - y * keep.z.dot(y)
	if z.length() < 1e-3:
		z = keep.x.cross(y)
	z = z.normalized()
	var x := y.cross(z).normalized()
	return Basis(x, y, z)

# ---------------------------------------------------------------- what flies off a blow
## Chips off whatever a tool has just bitten (`at`, world): `n` small bodies with real weight, thrown
## back towards whoever struck (`dir` is the way the blow went), that fall, bounce on the ground as it
## really lies there (`ground`: a Callable giving its height) and lie a few seconds.
static func chips(parent: Node3D, at: Vector3, dir: Vector3, ground, col: Color, n: int = 5, size: float = 0.05) -> Node3D:
	var root := Node3D.new()
	root.name = "debris"
	parent.add_child(root)
	if ground is Callable and (ground as Callable).is_valid():
		root.add_child(Havoc.ground_patch(at, ground, 4))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(at.snapped(Vector3.ONE * 0.05)))
	var pm := PhysicsMaterial.new()
	pm.friction = 0.9
	pm.bounce = 0.22
	var d := Vector3(dir.x, 0.0, dir.z)
	d = d.normalized() if d.length() > 0.01 else Vector3(0, 0, 1)
	var mat := MB.mat_plain()
	var bodies: Array = []
	for i in n:
		var sz := Vector3(size * rng.randf_range(0.8, 2.2), size * rng.randf_range(0.25, 0.5), size * rng.randf_range(0.6, 1.2))
		var b := MB.new()
		b.box(Vector3.ZERO, sz, MB.tag(col.darkened(rng.randf_range(0.0, 0.2)), MB.WOOD))
		var rb := RigidBody3D.new()
		rb.mass = 0.05
		rb.physics_material_override = pm
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = sz
		cs.shape = bx
		rb.add_child(cs)
		MB.mesh_node(rb, b.build(mat), Vector3.ZERO)
		root.add_child(rb)
		rb.position = at + Vector3(rng.randf_range(-0.04, 0.04), rng.randf_range(0.0, 0.06), rng.randf_range(-0.04, 0.04))
		rb.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		# (back off the face of what was struck, and up, and a little to either side)
		rb.linear_velocity = -d.rotated(Vector3.UP, rng.randf_range(-0.9, 0.9)) * rng.randf_range(0.8, 2.4) + Vector3(0, rng.randf_range(1.2, 3.0), 0)
		rb.angular_velocity = Vector3(rng.randf_range(-14, 14), rng.randf_range(-14, 14), rng.randf_range(-14, 14))
		bodies.append(rb)
	var tw := root.create_tween()
	tw.tween_interval(5.0)
	for rb2 in bodies:
		tw.parallel().tween_property(rb2, "scale", Vector3.ONE * 0.01, 0.8)
	tw.tween_callback(root.queue_free)
	return root
