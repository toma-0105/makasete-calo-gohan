import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  showLoading() {
    this.overlayTarget.classList.remove("hidden")
  }
}
