import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "amount", "period", "subtext", "toggle", "savings" ]
  static values = { interval: { type: String, default: "month" } }

  connect() {
    this.updateDisplay()
  }

  setInterval(event) {
    this.intervalValue = event.params.interval
  }

  intervalValueChanged() {
    this.updateDisplay()
  }

  updateDisplay() {
    const interval = this.intervalValue

    this.toggleTargets.forEach((button) => {
      const active = button.dataset.interval === interval
      button.setAttribute("aria-pressed", active ? "true" : "false")
      button.classList.toggle("bg-white", active)
      button.classList.toggle("text-zinc-900", active)
      button.classList.toggle("shadow-sm", active)
      button.classList.toggle("text-zinc-500", !active)
    })

    this.amountTargets.forEach((el) => {
      el.textContent = el.dataset[`${interval}Amount`]
    })

    this.periodTargets.forEach((el) => {
      const period = el.dataset[`${interval}Period`]
      el.textContent = period || ""
      el.classList.toggle("hidden", !period)
    })

    if (this.hasSubtextTarget) {
      this.subtextTargets.forEach((el) => {
        const subtext = el.dataset[`${interval}Subtext`]
        el.textContent = subtext || ""
        el.classList.toggle("hidden", !subtext)
      })
    }

    this.savingsTargets.forEach((el) => {
      const show = interval === "year" && el.dataset.yearSavings
      el.classList.toggle("hidden", !show)
      if (show) el.textContent = `Save ${el.dataset.yearSavings}% vs monthly`
    })
  }
}
