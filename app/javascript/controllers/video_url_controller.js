import { Controller } from "@hotwired/stimulus"

// Validate URL YouTube hoặc Livid ngay khi nhập, tự động tách src nếu dán thẻ <iframe>,
// và hiển thị ảnh thumbnail / khung xem trước.
export default class extends Controller {
  static targets = ["input", "preview", "feedback"]

  connect() {
    if (this.hasInputTarget && this.inputTarget.value.trim() !== "") {
      this.validateUrl()
    }
  }

  validateUrl() {
    let url = this.inputTarget.value.trim()

    if (url === "") {
      this.clearFeedback()
      return
    }

    // Nếu người dùng dán nguyên mã nhúng <iframe src="..."> thì tự động trích xuất URL
    const iframeMatch = url.match(/src=["']([^"']+)["']/i)
    if (iframeMatch && iframeMatch[1]) {
      url = iframeMatch[1].trim()
      this.inputTarget.value = url
    }

    const videoId = this.extractVideoId(url)
    const lividUrl = this.extractLividUrl(url)
    const gdriveId = this.extractGdriveId(url)

    if (videoId) {
      this.inputTarget.classList.remove("is-invalid")
      this.inputTarget.classList.add("is-valid")
      this.feedbackTarget.innerHTML = ""
      this.previewTarget.innerHTML = `
        <div class="d-flex align-items-center gap-3 mt-2 p-2 bg-light rounded border">
          <img src="https://img.youtube.com/vi/${videoId}/mqdefault.jpg"
               alt="Xem trước video" style="width: 112px; height: 63px; object-fit: cover; border-radius: 6px;">
          <div class="small text-success fw-medium">
            <i class="fab fa-youtube me-1 text-danger"></i>Link YouTube hợp lệ (ID: <code>${videoId}</code>)
          </div>
        </div>
      `
    } else if (lividUrl) {
      this.inputTarget.value = lividUrl
      this.inputTarget.classList.remove("is-invalid")
      this.inputTarget.classList.add("is-valid")
      this.feedbackTarget.innerHTML = ""
      this.previewTarget.innerHTML = `
        <div class="d-flex align-items-center gap-2 mt-2 p-2 bg-light rounded border small text-success fw-medium">
          <i class="fas fa-check-circle"></i>Link Livid hợp lệ (<code>${lividUrl}</code>)
        </div>
      `
    } else if (gdriveId) {
      this.inputTarget.classList.remove("is-invalid")
      this.inputTarget.classList.add("is-valid")
      this.feedbackTarget.innerHTML = ""
      this.previewTarget.innerHTML = `
        <div class="d-flex align-items-center gap-2 mt-2 p-2 bg-light rounded border small text-success fw-medium">
          <i class="fab fa-google-drive me-1"></i>Link Google Drive Video hợp lệ (ID: <code>${gdriveId}</code>)
        </div>
      `
    } else {
      this.inputTarget.classList.remove("is-valid")
      this.inputTarget.classList.add("is-invalid")
      this.previewTarget.innerHTML = ""
      this.feedbackTarget.innerHTML = `
        <div class="small text-danger mt-1">
          <i class="fas fa-exclamation-circle me-1"></i>
          Vui lòng dán link YouTube, Livid (https://livid.com/...) hoặc Google Drive Video.
        </div>
      `
    }
  }

  clearFeedback() {
    this.inputTarget.classList.remove("is-valid", "is-invalid")
    this.previewTarget.innerHTML = ""
    this.feedbackTarget.innerHTML = ""
  }

  extractVideoId(url) {
    const match = url.match(
      /(?:youtube\.com\/(?:[^/]+\/.+\/|(?:v|e(?:mbed)?)\/|shorts\/|.*[?&]v=)|youtu\.be\/)([^"&?/\s]{11})/
    )
    return match ? match[1] : null
  }

  extractLividUrl(url) {
    try {
      const parsed = new URL(url)
      if (!/^(www\.)?livid\.com$/i.test(parsed.hostname)) return null
      parsed.protocol = "https:"
      if (parsed.pathname.startsWith("/embed/")) return parsed.toString()
      const cleaned = parsed.pathname.replace(/^\/+|\/+$/g, "")
      if (!cleaned) return null
      const parts = cleaned.split("/")
      const slug =
        parts.length >= 2 && ["v", "watch", "video", "videos", "e"].includes(parts[0].toLowerCase())
          ? parts.slice(1).join("/")
          : cleaned
      parsed.pathname = `/embed/${slug}`
      return parsed.toString()
    } catch {
      return null
    }
  }

  extractGdriveId(url) {
    const match = url.match(/drive\.google\.com\/file\/d\/([a-zA-Z0-9_-]+)/)
    return match ? match[1] : null
  }
}
