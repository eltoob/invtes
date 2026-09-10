import { Controller } from "@hotwired/stimulus"

// Background music with a small floating play/pause + volume widget.
//
// Autoplay strategy (browsers only block *audible* autoplay without a gesture):
//   1. Try to play with sound straight away (works when the site already has
//      media-engagement credit or the visit came from a user click).
//   2. If that is blocked, start playing muted immediately (always allowed) so
//      the track is already running, then unmute on the first tap/click/keypress,
//      or whenever the tab regains focus and the browser now permits sound.
// A pause via the widget is remembered for the current tab session only, so a
// fresh visit to the invitation always starts the music again.
export default class extends Controller {
  static targets = ["audio", "toggle", "volume"]
  static values = { volume: { type: Number, default: 0.2 }, storageKey: { type: String, default: "bg-music" } }

  connect() {
    this.audio = this.audioTarget
    this.audio.loop = true
    this.audio.volume = this.savedVolume ?? this.volumeValue
    this.volumeTarget.value = Math.round(this.audio.volume * 100)

    this.onFirstGesture = () => this.unlock()
    this.onResume = () => { if (!document.hidden && !this.userPaused) this.unlock() }

    this.audio.addEventListener("play", this.render)
    this.audio.addEventListener("pause", this.render)
    this.audio.addEventListener("volumechange", this.render)
    document.addEventListener("visibilitychange", this.onResume)
    window.addEventListener("pageshow", this.onResume)
    window.addEventListener("focus", this.onResume)
    this.render()

    if (this.userPaused) return
    this.autoplay()
  }

  disconnect() {
    this.removeGestureListeners()
    document.removeEventListener("visibilitychange", this.onResume)
    window.removeEventListener("pageshow", this.onResume)
    window.removeEventListener("focus", this.onResume)
    this.audio.pause()
  }

  // Try audible playback; fall back to muted playback + unmute on first gesture.
  autoplay() {
    this.audio.muted = false
    this.audio.play().catch(() => {
      this.audio.muted = true
      this.audio.play().catch(() => {})
      this.addGestureListeners()
    })
  }

  // Called from a user gesture or when the tab regains focus: make it audible.
  unlock() {
    if (this.userPaused) return
    this.audio.muted = false
    this.audio.play()
      .then(() => this.removeGestureListeners())
      .catch(() => { this.audio.muted = true; this.audio.play().catch(() => {}); this.addGestureListeners() })
  }

  toggle() {
    if (this.audio.paused || this.audio.muted) {
      this.remember("paused", "0")
      this.unlock()
    } else {
      this.audio.pause()
      this.remember("paused", "1")
      this.removeGestureListeners()
    }
  }

  changeVolume() {
    this.audio.volume = this.volumeTarget.value / 100
    this.rememberVolume(this.audio.volume)
    this.remember("paused", "0")
    this.unlock()
  }

  render = () => {
    const playing = !this.audio.paused && !this.audio.muted
    this.toggleTarget.textContent = playing ? "⏸" : "▶"
    this.toggleTarget.setAttribute("aria-label", playing ? "Pause music" : "Play music")
    this.element.classList.toggle("is-playing", playing)
  }

  addGestureListeners() {
    if (this.listening) return
    this.listening = true
    for (const ev of this.gestureEvents) document.addEventListener(ev, this.onFirstGesture, { passive: true })
  }

  removeGestureListeners() {
    this.listening = false
    for (const ev of this.gestureEvents) document.removeEventListener(ev, this.onFirstGesture)
  }

  get gestureEvents() { return ["pointerdown", "touchend", "click", "keydown"] }

  get savedVolume() {
    let raw = null
    try { raw = localStorage.getItem(`${this.storageKeyValue}:volume`) } catch {}
    const v = parseFloat(raw)
    return Number.isFinite(v) ? Math.min(1, Math.max(0, v)) : null
  }

  get userPaused() { return this.read("paused") === "1" }

  read(key) {
    try { return sessionStorage.getItem(`${this.storageKeyValue}:${key}`) } catch { return null }
  }

  remember(key, value) {
    try { sessionStorage.setItem(`${this.storageKeyValue}:${key}`, String(value)) } catch {}
  }

  rememberVolume(value) {
    try { localStorage.setItem(`${this.storageKeyValue}:volume`, String(value)) } catch {}
  }
}
