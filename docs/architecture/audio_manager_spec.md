# System Design Specification: AudioManager

## 1. System Overview
* **Module Name:** `AudioManager`
* **Type:** `Autoload` (Singleton)
* **Responsibility:** manages global audio playback. Handles music crossfading, SFX pooling (polyphony control), and bus volume management.
* **Dependencies:** `CoreEventBus` (Listens for `sfx_play_requested` and `music_play_requested`).

## 2. Bus Architecture (Godot AudioServer)
The manager assumes (and should enforce/verify) this bus layout:
* **Master**
    * **Music** (Background tracks)
    * **SFX** (Gameplay sounds)
    * **UI** (Interface beeps - distinct from SFX so they can be mixed separately)

## 3. Logic Flow Specification

### A. Initialization (`_ready`)
1.  **Signal Connection:** Connect to `CoreEventBus` signals:
    * `music_play_requested` -> `play_music`
    * `music_stop_requested` -> `stop_music`
    * `sfx_play_requested` -> `play_sfx`
2.  **Pool Generation:** Create a pool of `AudioStreamPlayer` (2D and 3D) nodes to prevent runtime instantiation lag.
    * *Strategy:* Create `N` players at startup. When a sound is requested, find the first `!playing` player.

### B. Music System (The DJ)
* **Architecture:** Uses two `AudioStreamPlayer` nodes (`_music_player_1`, `_music_player_2`) to achieve crossfading.
* **Logic:**
    * Identify which player is currently active.
    * Load new stream into the *inactive* player.
    * Tween volume of *active* down to -80dB.
    * Tween volume of *inactive* up to 0dB.
    * Swap active reference.

### C. SFX System (The Pool)
* **Input:** `sound_id` (String path or Resource), `position` (Vector3).
* **Logic:**
    * If `position == AUDIO_3D_NULL`: Use a **Non-Positional (UI)** player pool.
    * If `position != AUDIO_3D_NULL`: Use a **3D Positional** player pool.
    * **Concurrency Limit:** If all pool players are busy, either:
        * A) Drop the sound (Optimization).
        * B) Steal the oldest sound (Priority).
        * *For MVP:* Dropping is safer and cheaper.

### D. Volume Control
* `set_bus_volume(bus_name: String, linear_value: float)`:
    * Converts linear (0.0 - 1.0) to Decibels (`linear_to_db`).
    * clamps to safe ranges.

## 4. API Surface (Public Methods)
* `play_music(stream_path: String, fade_time: float = 1.0)`
* `stop_music(fade_time: float = 1.0)`
* `play_sfx(stream_path: String, ...)` (Usually called via Signal, but public entry point exists).

## 5. Technical Constraints
* **Resource Loading:** For MVP, `stream_path` can be a string. Use `load(path)` on the fly. (In production, we might preload, but `load()` is fast enough for small assets).
* **Tweening:** Use `create_tween()` for all volume fades.