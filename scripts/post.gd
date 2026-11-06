class_name PostFX
extends CanvasLayer
## Screen-space finishing pass over the 3D view.  It sits on canvas layer -1, so it reads the
## rendered 3D frame and is drawn *below* the HUD, dialogue and menus (they stay crisp).
##
## Steps, all in one canvas shader: an unsharp mask that crisps the toon edges, a soft bloom built
## from the screen texture's mip chain, split toning (cool shadows / warm highlights taken from the
## region's sky and sun), a gentle saturation lift, vignette, film grain and chromatic aberration at
## the frame edges.  On top of that: a full-screen flash for big hits and tribulation lightning,
## a "qi pulse" ripple for breakthroughs and a cinematic letterbox while dialogue is open.
## Disabled in headless runs and with --no-post.

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform float vignette = 0.18;
uniform vec3 shadow_tint : source_color = vec3(0.92, 0.96, 1.08);
uniform vec3 high_tint : source_color = vec3(1.05, 1.0, 0.94);
uniform float saturation = 1.06;
uniform float grain = 0.0;
uniform float bloom = 0.1;
uniform float bloom_threshold = 0.9;
uniform float aberration = 0.0;
uniform float sharpen = 0.22;
uniform float flash = 0.0;
uniform vec3 flash_col : source_color = vec3(1.0);
uniform float letterbox = 0.0;
uniform float pulse = 0.0;
uniform vec2 pulse_center = vec2(0.5, 0.55);

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	// qi pulse: an expanding ring that bends the image as it passes
	if (pulse > 0.0) {
		vec2 pd = uv - pulse_center;
		float dist = length(pd * vec2(1.0, 0.56));
		float ring = 1.0 - pulse;
		float w = smoothstep(0.08, 0.0, abs(dist - ring * 0.9));
		uv -= normalize(pd + 1e-5) * w * 0.02 * pulse;
	}
	vec2 dc = uv - 0.5;
	// chromatic aberration growing towards the frame edges
	float ca = aberration * dot(dc, dc) * 4.0;
	vec3 c;
	c.r = texture(screen_tex, uv + dc * ca).r;
	c.g = texture(screen_tex, uv).g;
	c.b = texture(screen_tex, uv - dc * ca).b;
	// unsharp mask: crisper ink lines and texture detail
	vec3 nb = texture(screen_tex, uv + vec2(px.x, 0.0)).rgb + texture(screen_tex, uv - vec2(px.x, 0.0)).rgb
		+ texture(screen_tex, uv + vec2(0.0, px.y)).rgb + texture(screen_tex, uv - vec2(0.0, px.y)).rgb;
	c += (c - nb * 0.25) * sharpen;
	// soft bloom from blurred mip levels (only what is brighter than the threshold)
	vec3 b1 = textureLod(screen_tex, uv, 1.5).rgb;
	vec3 b2 = textureLod(screen_tex, uv, 3.0).rgb;
	vec3 bsrc = b1 * 0.7 + b2 * 0.3;
	c += max(bsrc - bloom_threshold, vec3(0.0)) * bloom * 1.6;
	// saturation and split toning
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	c *= mix(shadow_tint, high_tint, smoothstep(0.15, 0.85, l));
	// vignette
	float v = smoothstep(0.9, 0.3, length(dc * vec2(1.0, 0.75)));
	c *= mix(1.0 - vignette, 1.0, v);
	// film grain (animated)
	float n = fract(sin(dot(floor(uv / px) + fract(TIME) * 91.7, vec2(12.9898, 78.233))) * 43758.5453);
	c += (n - 0.5) * grain;
	// flash and letterbox
	c = mix(c, flash_col, clamp(flash, 0.0, 1.0));
	float lb = step(0.5 - letterbox, abs(SCREEN_UV.y - 0.5));
	c = mix(c, vec3(0.0), lb);
	COLOR = vec4(c, 1.0);
}
"""

var rect: ColorRect
var mat: ShaderMaterial
var flash := 0.0
var flash_col := Color.WHITE
var pulse := 0.0
var letterbox := 0.0
var letterbox_target := 0.0
var enabled := true

func _ready() -> void:
	layer = -1
	rect = ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.size = Vector2(1280, 720)
	mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	mat.shader = sh
	rect.material = mat
	add_child(rect)
	set_theme("sect")

## Grade the frame for a region: shadows lean towards its sky, highlights towards its sun.
func set_theme(name: String) -> void:
	if mat == null:
		return
	var th := Look.theme(name)
	var sky: Color = th.sky_top
	var sun: Color = th.sun
	var st := Color(0.92, 0.95, 1.06).lerp(Color(sky.r * 0.5 + 0.55, sky.g * 0.5 + 0.55, sky.b * 0.5 + 0.6), 0.45)
	var ht := Color(1.04, 1.0, 0.95).lerp(Color(sun.r * 0.2 + 0.85, sun.g * 0.2 + 0.83, sun.b * 0.2 + 0.8), 0.5)
	mat.set_shader_parameter("shadow_tint", st)
	mat.set_shader_parameter("high_tint", ht)
	var dark: bool = Color(th.sky_top).v < 0.35
	mat.set_shader_parameter("bloom", 0.16 if dark else 0.08)
	mat.set_shader_parameter("bloom_threshold", 0.8 if dark else 0.92)
	mat.set_shader_parameter("vignette", 0.24 if dark else 0.16)

func do_flash(col: Color = Color.WHITE, strength: float = 0.6) -> void:
	flash = maxf(flash, strength)
	flash_col = col

func do_pulse() -> void:
	pulse = 1.0

func _process(d: float) -> void:
	if mat == null:
		return
	flash = maxf(0.0, flash - d * 2.5)
	pulse = maxf(0.0, pulse - d * 0.8)
	letterbox = move_toward(letterbox, letterbox_target, d * 0.35)
	mat.set_shader_parameter("flash", flash)
	mat.set_shader_parameter("flash_col", flash_col)
	mat.set_shader_parameter("pulse", pulse)
	mat.set_shader_parameter("letterbox", letterbox)
	visible = enabled
