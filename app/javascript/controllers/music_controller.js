import { Controller } from "@hotwired/stimulus"

// Background music with a small floating play/pause + volume widget.
// Starts quietly; if the browser blocks autoplay, playback begins on the first tap/keypress.
export default class extends Controller {
  static targets = ["audio", "toggle", "volume"]
  static values = { volume: { type: Number, default: 0.2 }, storageKey: { type: String, default: "bg-music" } }

  connect() {
    this.audio = this.audioTarget
    this.audio.loop = true
    this.audio.volume = this.savedVolume ?? this.volumeValue
    this.volumeTarget.value = Math.round(this.audio.volume * 100)

    this.onFirstGesture = () => { this.play(); this.removeGestureListeners() }
    this.audio.addEventListener("play", this.render)
    this.audio.addEventListener("pause", this.render)
    this.render()

    if (this.wasPaused) return
    this.play().catch(() => this.addGestureListeners())
  }

  disconnect() {
    this.removeGestureListeners()
    this.audio.pause()
  }

  toggle() {
    if (this.audio.paused) {
      this.play(); this.remember("paused", "0")
    } else {
      this.audio.pause(); this.remember("paused", "1"); this.removeGestureListeners()
    }
  }

  changeVolume() {
    this.audio.volume = this.volumeTarget.value / 100
    this.audio.muted = false
    this.remember("volume", this.audio.volume)
    if (this.audio.paused && !this.wasPaused) this.play()
  }

  play() {
    return this.audio.play()
  }

  render = () => {
    const playing = !this.audio.paused
    this.toggleTarget.textContent = playing ? "⏸" : "▶"
    this.toggleTarget.setAttribute("aria-label", playing ? "Pause music" : "Play music")
    this.element.classList.toggle("is-playing", playing)
  }

  addGestureListeners() {
    if (this.listening) return
    this.listening = true
    for (const ev of this.gestureEvents) document.addEventListener(ev, this.onFirstGesture, { once: true, passive: true })
  }

  removeGestureListeners() {
    this.listening = false
    for (const ev of this.gestureEvents) document.removeEventListener(ev, this.onFirstGesture)
  }

  get gestureEvents() { return ["pointerdown", "touchstart", "keydown"] }

  get savedVolume() {
    const v = parseFloat(this.read("volume"))
    return Number.isFinite(v) ? Math.min(1, Math.max(0, v)) : null
  }

  get wasPaused() { return this.read("paused") === "1" }

  read(key) {
    try { return localStorage.getItem(`${this.storageKeyValue}:${key}`) } catch { return null }
  }

  remember(key, value) {
    try { localStorage.setItem(`${this.storageKeyValue}:${key}`, String(value)) } catch {}
  }
}
