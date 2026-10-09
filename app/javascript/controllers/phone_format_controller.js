import { Controller } from "@hotwired/stimulus"

// Formats a US number as it's typed or autofilled: 5551234567 → (555) 123-4567,
// 15551234567 → +1 (555) 123-4567. Other international numbers (a "+" not
// followed by 1) and anything longer than a US number are left as typed.
export default class extends Controller {
  format() {
    const input = this.element
    const formatted = formatPhone(input.value)
    if (formatted === input.value) return

    // Keep the caret after the same digit it was after before reformatting.
    const digitsBeforeCaret = input.value.slice(0, input.selectionStart).replace(/\D/g, "").length
    input.value = formatted
    if (document.activeElement !== input) return
    let caret = 0
    for (let seen = 0; caret < formatted.length && seen < digitsBeforeCaret; caret++) {
      if (/\d/.test(formatted[caret])) seen++
    }
    input.setSelectionRange(caret, caret)
  }
}

export function formatPhone(value) {
  if (/^\s*\+(?!\s*1)/.test(value)) return value

  const digits = value.replace(/\D/g, "")
  const country = digits.startsWith("1")
  const national = country ? digits.slice(1) : digits
  if (national.length > 10) return value

  let out = national
  if (national.length > 6) out = `(${national.slice(0, 3)}) ${national.slice(3, 6)}-${national.slice(6)}`
  else if (national.length > 3) out = `(${national.slice(0, 3)}) ${national.slice(3)}`
  else if (national.length > 0) out = `(${national}`

  if (!country) return out
  return out ? `+1 ${out}` : "+1"
}
