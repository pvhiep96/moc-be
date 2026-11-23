import { Controller } from "@hotwired/stimulus"

// Bật/tắt hiển thị một vùng nội dung theo checkbox (vd: bật video dọc mới hiện ô nhập).
// Connects to data-controller="reveal"
export default class extends Controller {
  static targets = ["checkbox", "content"]

  connect() {
    this.toggle()
  }

  toggle() {
    const show = this.checkboxTarget.checked
    this.contentTargets.forEach((el) => el.classList.toggle("d-none", !show))
  }
}
