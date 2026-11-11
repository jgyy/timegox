extends RefCounted
class_name Gpu
## Which graphics card the game runs on. On a laptop with a discrete NVIDIA card next to the integrated
## one, the desktop's default is the integrated card; the renderer (OpenGL, Compatibility) takes its card
## from the environment when the process starts, so the game starts itself once more with NVIDIA's
## render offload set. Off again with --igpu, and never in the editor, headless, or the tools (bot,
## tour, bench, census, gallery), where the card does not matter.

const MARK := "TIMEGOX_DISCRETE_GPU"
const NV_DRIVER := "/proc/driver/nvidia/version"
const OFFLOAD := ["__NV_PRIME_RENDER_OFFLOAD=1", "__GLX_VENDOR_LIBRARY_NAME=nvidia"]
const TOOLS := ["bot", "tour", "bench", "census", "gallery"]


## True when the game has started itself again on the discrete card and this process must end.
static func prefer_discrete(args: Dictionary) -> bool:
	# the editor's own build reports the "editor" feature even for a game it runs, so the run is told apart
	# by the editor's debugger instead
	if OS.get_name() != "Linux" or DisplayServer.get_name() == "headless" or EngineDebugger.is_active():
		return false
	if OS.get_cmdline_args().has("--remote-debug"):
		return false
	if args.has("igpu") or TOOLS.any(func(t): return args.has(t)):
		return false
	var relaunched := OS.get_environment(MARK) != ""
	if relaunched:
		print("[gpu] running on ", RenderingServer.get_video_adapter_name())
		return false
	if not FileAccess.file_exists(NV_DRIVER):
		return false
	if RenderingServer.get_video_adapter_name().contains("NVIDIA"):
		return false
	var argv := PackedStringArray(OFFLOAD)
	argv.append(MARK + "=1")
	argv.append(OS.get_executable_path())
	argv.append_array(OS.get_cmdline_args())
	if OS.create_process("/usr/bin/env", argv) < 0:
		return false
	print("[gpu] started again on the NVIDIA card")
	return true
