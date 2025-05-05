import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="video-file"
export default class extends Controller {
  static targets = ["input", "preview"]

  connect() {
    if (this.hasInputTarget && this.hasPreviewTarget) {
      this.inputTarget.addEventListener("change", this.previewVideo.bind(this))
    }
  }

  disconnect() {
    if (this.hasInputTarget) {
      this.inputTarget.removeEventListener("change", this.previewVideo.bind(this))
    }
  }

  previewVideo(event) {
    const file = event.target.files[0]
    if (!file) {
      this.clearPreview()
      return
    }

    // Check if file is a video
    if (!file.type.match('video.*')) {
      this.showError("Selected file is not a video")
      return
    }

    // Check file size (max 500MB)
    if (file.size > 500 * 1024 * 1024) {
      this.showError("Video file is too large (maximum is 500MB)")
      return
    }

    const reader = new FileReader()
    reader.onload = (e) => {
      this.showPreview(e.target.result, file.type)
    }
    reader.readAsDataURL(file)
  }

  showPreview(src, type) {
    this.previewTarget.innerHTML = `
      <div class="mt-3">
        <p class="mb-2">Preview:</p>
        <div class="ratio ratio-9x16">
          <video controls class="w-100">
            <source src="${src}" type="${type}">
            Your browser does not support the video tag.
          </video>
        </div>
      </div>
    `
  }

  clearPreview() {
    this.previewTarget.innerHTML = ""
  }

  showError(message) {
    this.previewTarget.innerHTML = `
      <div class="alert alert-danger mt-2">
        <i class="fas fa-exclamation-circle me-1"></i> ${message}
      </div>
    `
  }
}
