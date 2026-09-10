import { Controller } from "@hotwired/stimulus"

// Submits the RSVP form as JSON and swaps in a thank-you state.
export default class extends Controller {
  static targets = ["form", "guests", "error", "submit", "success", "successTitle", "successMessage"]
  static values = { url: String }

  connect() { this.toggleGuests() }

  toggleGuests() {
    const attending = this.formTarget.querySelector('input[name="rsvp[attending]"]:checked')?.value === "true"
    this.guestsTarget.hidden = !attending
  }

  async submit(event) {
    event.preventDefault()
    this.errorTarget.hidden = true
    this.submitTarget.disabled = true
    this.submitTarget.textContent = "Sending…"

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: { "Accept": "application/json", "X-CSRF-Token": this.csrfToken },
        body: new FormData(this.formTarget)
      })
      const data = await response.json()
      if (!response.ok || !data.ok) throw new Error((data.errors || ["Something went wrong. Please try again."]).join(". "))

      this.successTitleTarget.textContent = data.attending ? `See you there, ${data.name}!` : `We'll miss you, ${data.name}.`
      this.successMessageTarget.textContent = data.message
      this.formTarget.hidden = true
      this.successTarget.hidden = false
      this.successTarget.scrollIntoView({ behavior: "smooth", block: "center" })
    } catch (err) {
      this.errorTarget.textContent = err.message
      this.errorTarget.hidden = false
    } finally {
      this.submitTarget.disabled = false
      this.submitTarget.textContent = "Send RSVP"
    }
  }

  reset() {
    this.successTarget.hidden = true
    this.formTarget.hidden = false
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
