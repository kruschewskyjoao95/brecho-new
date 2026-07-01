import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "drawer", "backdrop" ]

  connect() {
    // Controller conectado
  }

  open(event) {
    if (event && event.currentTarget.tagName === "A") event.preventDefault()
    this.drawerTarget.classList.add("open")
    this.backdropTarget.style.display = "block"
    this.drawerTarget.focus() // Foca no drawer
    document.body.style.overflow = "hidden" // Impede scroll do body
  }

  close(event) {
    if (event) event.preventDefault()
    this.drawerTarget.classList.remove("open")
    this.backdropTarget.style.display = "none"
    document.body.style.overflow = "" // Restaura scroll do body
  }
}
