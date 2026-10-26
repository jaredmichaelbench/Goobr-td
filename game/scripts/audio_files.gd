class_name AudioFiles
extends RefCounted
## Songs and sound packs are WAVs dropped into audio/ by hand (never in git). In the
## editor they are plain files; in an exported build they may be plain files (the
## builds made for Demo 1 pack them as-is) or imported resources. These two helpers
## work in both, so the same code finds the music on Jared's Mac and in a build.


## The .wav file names in a folder, sorted.
static func list_wavs(dir: String) -> Array:
	var names := {}
	if not DirAccess.dir_exists_absolute(dir):
		return []
	for f in DirAccess.get_files_at(dir):
		var lower := f.to_lower()
		if lower.ends_with(".wav"):
			names[f] = true
		elif lower.ends_with(".wav.import") or lower.ends_with(".wav.remap"):
			names[f.get_basename()] = true
	var out := names.keys()
	out.sort()
	return out


static func exists(path: String) -> bool:
	return FileAccess.file_exists(path) or ResourceLoader.exists(path)


## A WAV as a stream we can change (loop points), or null.
static func load_wav(path: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV = null
	if FileAccess.file_exists(path):
		var real := ProjectSettings.globalize_path(path) if OS.has_feature("editor") else path
		stream = AudioStreamWAV.load_from_file(real)
	if stream == null and ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStreamWAV:
			stream = res.duplicate()
	return stream
