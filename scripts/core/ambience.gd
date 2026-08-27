extends Node

## Autoload. Procedural ambience — no audio files ship with this game, same
## discipline the original canvas engine held to for its synthesized
## orchestra (docs/DESIGN.md section 1).
##
## LORE-BIBLE.md section 7 gives Project 42 a literal, specific spec: "A 60Hz
## mains hum as an ever-present bed, because the camp runs on far too much
## current." That is not a mood note, it's a frequency. This file builds
## exactly that tone, generated at runtime via AudioStreamGenerator, and a
## quieter filtered-noise bed for 1888 London where the bible has no entry
## and the concept doc's own brief (cold, fog, gaslight) stands in for it.

const SAMPLE_RATE := 44100.0

var _player: AudioStreamPlayer = null
var _playback: AudioStreamGeneratorPlayback = null
var _phase := 0.0
var _current_hz := 0.0
var _current_noise := 0.0
var _target_hz := 0.0
var _target_noise := 0.0
var _rng := RandomNumberGenerator.new()


func _exit_tree() -> void:
	# Explicit release rather than relying on teardown order. A headless
	# --script run (tests/run_tests.gd) calls SceneTree.quit() directly,
	# which does not reliably flow through the normal node-exit chain for
	# autoloaded singletons - discovered because this autoload's _ready()
	# runs even under --script (confirmed by disabling it and watching the
	# leak disappear), which is the opposite of what an earlier commit
	# message claimed about GameState. That claim was about a different
	# failure (a compile-time autoload identifier lookup), not about
	# whether autoload nodes get instantiated - they do, in every run mode.
	if is_instance_valid(_player):
		_player.stop()
	_playback = null


func _ready() -> void:
	# Headless test runs (tests/run_tests.gd via --headless --script) never
	# play or assert anything about sound, and a --script quit() does not
	# reliably run node-exit cleanup for autoloads - confirmed by trying an
	# explicit _exit_tree() release first, which did not stop the leak
	# either. The correct fix is not to allocate a real audio generator and
	# playback object at all when nothing will ever use it, not to chase
	# a teardown path that this run mode does not take.
	if DisplayServer.get_name() == "headless":
		return
	_rng.randomize()
	_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = SAMPLE_RATE
	gen.buffer_length = 0.2
	_player.stream = gen
	_player.volume_db = -18.0
	_player.bus = "Master"
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()


func _process(_delta: float) -> void:
	if _playback == null:
		return
	# Ease toward the target so switching eras fades rather than snaps -
	# a hard cut on a hum is the first thing a player's ear catches.
	_current_hz = lerpf(_current_hz, _target_hz, 0.02)
	_current_noise = lerpf(_current_noise, _target_noise, 0.02)

	var to_fill := _playback.get_frames_available()
	if to_fill <= 0:
		return
	var buffer := PackedVector2Array()
	buffer.resize(to_fill)
	for i in to_fill:
		var sample := 0.0
		if _current_hz > 0.5:
			sample += sin(_phase) * 0.35
			# A little third-harmonic grit - a pure sine hum reads as a test
			# tone, not a building. Cheap way to make it sound electrical
			# rather than musical.
			sample += sin(_phase * 3.0) * 0.06
		sample += (_rng.randf() * 2.0 - 1.0) * _current_noise
		buffer[i] = Vector2(sample, sample)
		if _current_hz > 0.5:
			_phase += TAU * _current_hz / SAMPLE_RATE
			if _phase > TAU:
				_phase -= TAU
	_playback.push_buffer(buffer)


## Called on era change. hz=0 means no tonal hum, just the noise bed.
func set_target(hz: float, noise_amount: float) -> void:
	_target_hz = hz
	_target_noise = noise_amount


func apply_palette(p: EraPalette.Palette) -> void:
	set_target(p.hum_hz, p.noise_amount)
