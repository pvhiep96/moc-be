import { Controller } from "@hotwired/stimulus"

// Cho phép admin chọn rõ ràng 1 trong 2 cách cung cấp video dọc:
// dán link YouTube HOẶC upload file — chỉ hiện 1 ô nhập tương ứng.
// Connects to data-controller="video-vertical"
export default class extends Controller {
  static targets = ["urlSection", "fileSection", "urlRadio", "fileRadio", "urlInput", "fileInput"]

  connect() {
    // Chọn sẵn chế độ dựa trên dữ liệu hiện có: có URL → chế độ link, ngược lại → upload
    const hasUrl = this.hasUrlInputTarget && this.urlInputTarget.value.trim() !== ""
    const hasFile = this.element.dataset.videoVerticalHasFileValue === "true"

    if (hasUrl && !hasFile) {
      this.urlRadioTarget.checked = true
    } else {
      this.fileRadioTarget.checked = true
    }
    this.toggle()
  }

  toggle() {
    const useUrl = this.urlRadioTarget.checked
    this.urlSectionTarget.classList.toggle("d-none", !useUrl)
    this.fileSectionTarget.classList.toggle("d-none", useUrl)
  }
}
