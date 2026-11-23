import { Controller } from "@hotwired/stimulus"

// Bộ điều khiển Trực Quan Studio Admin:
// - Bản đồ Xem Trước Trực Tiếp (Live Website Preview) cập nhật tức thì khi chọn Ảnh Bìa, Ảnh Hover hoặc gõ Tên Dự Án
// - 1-Click "★ Đặt làm Ảnh Bìa" (đưa thành tấm ảnh số #1 mà không làm xáo trộn Mô tả/Video ở đầu bài)
// - 1-Click "✦ Đặt làm Ảnh Hover" (đưa thành tấm ảnh số #2 khi rê chuột)
// - 1-Click "⚡ Sắp xếp bố cục chuẩn (Mô tả → Video → Ảnh)"
// - Tự động lưu AJAX (400ms debounce)
export default class extends Controller {
  static targets = [
    "sorted",
    "sortedPool",
    "unsortedPool",
    "status",
    "sortedEmpty",
    "hiddenInput",
    "displayedTotal",
    "poolTotal"
  ]
  static values = { url: String }

  connect() {
    this.pendingSave = null
    this.dirty = false
    this.activeFilter = "ALL"
    this.initSortable()
    this.refreshUi()
    this.setStatus("saved")
  }

  disconnect() {
    if (this.sortable) this.sortable.destroy()
    clearTimeout(this.pendingSave)
  }

  initSortable() {
    if (typeof Sortable === "undefined" || !this.hasSortedTarget) return
    this.sortable = new Sortable(this.sortedTarget, {
      animation: 180,
      handle: ".drag-handle",
      ghostClass: "sortable-ghost",
      chosenClass: "sortable-chosen",
      onEnd: () => this.changed()
    })
  }

  // Cập nhật tên dự án trực tiếp trên khung "Xem trước trên Website" khi admin gõ phím
  updateNamePreview(event) {
    const val = (event.target.value || "").trim() || "Tên Dự Án Cưới"
    document.querySelectorAll("[data-preview-project-name]").forEach((el) => {
      el.textContent = val
    })
  }

  // Cuộn mượt xuống khu vực chọn ảnh và lọc riêng tab Ảnh
  scrollToPhotoPicker(event) {
    event.preventDefault()
    const filterBtn = this.element.querySelector('[data-filter-type="ProjectImage"]')
    if (filterBtn) filterBtn.click()
    const studioEl = document.getElementById("content-studio")
    if (studioEl) {
      studioEl.scrollIntoView({ behavior: "smooth", block: "start" })
    }
  }

  // Bấm nút "+ Hiển thị" trên 1 thẻ trong kho ẩn
  add(event) {
    event.preventDefault()
    const card = event.target.closest("[data-content-key]")
    if (!card) return
    this.moveCardToSorted(card, false)
    this.changed()
  }

  // 1-Click: Đặt tấm ảnh này làm ★ ẢNH BÌA CHÍNH (Ảnh #1 trên Trang Chủ & Trang Studio)
  promoteToTop(event) {
    event.preventDefault()
    const card = event.target.closest("[data-content-key]")
    if (!card) return

    let targetCard = card
    if (!this.sortedTarget.contains(card)) {
      targetCard = this.moveCardToSorted(card, true)
    }
    if (!targetCard) return

    if (targetCard.dataset.type === "ProjectImage") {
      // Đưa lên trước tấm ảnh đầu tiên hiện tại (giữ nguyên vị trí Mô tả / Video nếu đang ở đầu trang)
      const firstImg = this.sortedImageItems()[0]
      if (firstImg && firstImg !== targetCard) {
        this.sortedTarget.insertBefore(targetCard, firstImg)
      }
    } else {
      const first = this.sortedTarget.firstElementChild
      if (first && first !== targetCard) {
        this.sortedTarget.insertBefore(targetCard, first)
      }
    }

    this.changed()
    this.flashPreviewCard("cover")
  }

  // 1-Click: Đặt tấm ảnh này làm ✦ ẢNH HOVER (Ảnh #2 hiện ra khi khách rê chuột)
  promoteToHover(event) {
    event.preventDefault()
    const card = event.target.closest("[data-content-key]")
    if (!card) return

    let targetCard = card
    if (!this.sortedTarget.contains(card)) {
      targetCard = this.moveCardToSorted(card, false)
    }
    if (!targetCard) return

    const images = this.sortedImageItems().filter((el) => el !== targetCard)
    if (images.length === 0) {
      // Nếu chưa có ảnh nào khác thì nó đứng đầu
      const first = this.sortedTarget.firstElementChild
      if (first) this.sortedTarget.insertBefore(targetCard, first)
    } else {
      // Chèn ngay sau tấm ảnh số #1 (Ảnh bìa)
      const coverImg = images[0]
      if (coverImg.nextSibling) {
        this.sortedTarget.insertBefore(targetCard, coverImg.nextSibling)
      } else {
        this.sortedTarget.appendChild(targetCard)
      }
    }

    this.changed()
    this.flashPreviewCard("hover")
  }

  // 1-Click: Sắp xếp bố cục chuẩn tự động (1. Mô tả Credit -> 2. Video Phim Cưới -> 3. Toàn bộ Ảnh)
  autoSortStandard(event) {
    event.preventDefault()
    // Đưa tất cả nội dung đang ẩn lên hiển thị trước
    const hiddenCards = Array.from(
      this.element.querySelectorAll("[data-unsorted-container] [data-content-key]")
    )
    hiddenCards.forEach((c) => this.moveCardToSorted(c, false))

    const allItems = this.sortedItems()
    const descriptions = allItems.filter((el) => el.dataset.type === "Description")
    const videos = allItems.filter((el) => el.dataset.type === "VideoUrl")
    const images = allItems.filter((el) => el.dataset.type === "ProjectImage")

    ;[...descriptions, ...videos, ...images].forEach((el) => {
      this.sortedTarget.appendChild(el)
    })

    this.changed()
  }

  // Bấm nút "Ẩn" trên 1 thẻ đang hiển thị
  remove(event) {
    event.preventDefault()
    const card = event.target.closest("[data-content-key]")
    if (!card) return
    this.moveCardToUnsorted(card)
    this.changed()
  }

  // Hiển thị tất cả ảnh đang nằm trong kho ẩn
  addAllImages(event) {
    event.preventDefault()
    const container = this.element.querySelector('[data-unsorted-container="ProjectImage"]')
    if (!container) return
    const cards = Array.from(container.querySelectorAll("[data-content-key]"))
    if (cards.length === 0) return
    cards.forEach((card) => this.moveCardToSorted(card, false))
    this.changed()
  }

  // Hiển thị toàn bộ nội dung (Video + Mô tả + Ảnh) đang nằm trong kho ẩn
  addAll(event) {
    event.preventDefault()
    const cards = Array.from(
      this.element.querySelectorAll("[data-unsorted-container] [data-content-key]")
    )
    if (cards.length === 0) return
    cards.forEach((card) => this.moveCardToSorted(card, false))
    this.changed()
  }

  // Ẩn toàn bộ nội dung đang hiển thị
  removeAll(event) {
    event.preventDefault()
    const items = this.sortedItems()
    if (items.length === 0) return
    if (!window.confirm(`Ẩn toàn bộ ${items.length} mục khỏi website? (Dữ liệu không bị xóa)`)) {
      return
    }
    items.forEach((card) => this.moveCardToUnsorted(card))
    this.changed()
  }

  // Lọc loại nội dung hiển thị trên bảng kéo thả (ALL | ProjectImage | VideoUrl | Description)
  filterSorted(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const filterType = btn.dataset.filterType || "ALL"
    this.activeFilter = filterType

    this.element.querySelectorAll("[data-filter-type]").forEach((el) => {
      el.classList.toggle("active", el.dataset.filterType === filterType)
    })

    this.applyFilter()
  }

  applyFilter() {
    this.sortedItems().forEach((item) => {
      const match = this.activeFilter === "ALL" || item.dataset.type === this.activeFilter
      item.classList.toggle("d-none", !match)
    })
  }

  moveCardToSorted(poolCard, toStart = false) {
    const key = poolCard.dataset.contentKey
    const sortedCard = this.sortedPoolTarget.querySelector(
      `[data-content-key="${CSS.escape(key)}"]`
    )
    if (sortedCard) {
      if (toStart && this.sortedTarget.firstElementChild) {
        this.sortedTarget.insertBefore(sortedCard, this.sortedTarget.firstElementChild)
      } else {
        this.sortedTarget.appendChild(sortedCard)
      }
    }
    this.unsortedPoolTarget.appendChild(poolCard)
    return sortedCard
  }

  moveCardToUnsorted(sortedCard) {
    const key = sortedCard.dataset.contentKey
    const type = sortedCard.dataset.type

    this.sortedPoolTarget.appendChild(sortedCard)

    const unsortedCard = this.unsortedPoolTarget.querySelector(
      `[data-content-key="${CSS.escape(key)}"]`
    )
    const container = this.element.querySelector(`[data-unsorted-container="${type}"]`)
    if (unsortedCard && container) container.appendChild(unsortedCard)
  }

  changed() {
    this.dirty = true
    this.refreshUi()
    this.setStatus("saving")
    clearTimeout(this.pendingSave)
    this.pendingSave = setTimeout(() => this.save(), 350)
  }

  retry() {
    this.setStatus("saving")
    this.save()
  }

  currentPositions() {
    return this.sortedItems().map((item, index) => ({
      id: item.dataset.id,
      type: item.dataset.type,
      position: index + 1
    }))
  }

  save() {
    if (!this.urlValue) return
    const positions = this.currentPositions()
    const csrfMeta = document.querySelector('meta[name="csrf-token"]')
    const csrfToken = csrfMeta ? csrfMeta.getAttribute("content") : ""

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({ positions })
    })
      .then((response) => {
        if (!response.ok) return response.json().then((data) => Promise.reject(data))
        return response.json()
      })
      .then(() => {
        this.dirty = false
        this.setStatus("saved")
      })
      .catch((error) => {
        console.error("Lỗi khi lưu thứ tự nội dung:", error)
        this.setStatus("error", error && error.error)
      })
  }

  sortedItems() {
    if (!this.hasSortedTarget) return []
    return Array.from(this.sortedTarget.querySelectorAll("[data-content-key]"))
  }

  sortedImageItems() {
    return this.sortedItems().filter((item) => item.dataset.type === "ProjectImage")
  }

  flashPreviewCard(which) {
    const selector = which === "cover" ? "[data-preview-box='cover']" : "[data-preview-box='hover']"
    const box = document.querySelector(selector)
    if (!box) return
    box.classList.add("preview-flash-highlight")
    setTimeout(() => box.classList.remove("preview-flash-highlight"), 900)
  }

  // Cập nhật số thứ tự, nhãn Ảnh Bìa / Ảnh Hover, khung Live Preview trên cùng, bộ đếm và hidden input
  refreshUi() {
    const items = this.sortedItems()
    let imageRank = 0
    let coverUrl = null
    let hoverUrl = null

    items.forEach((item, index) => {
      const badge = item.querySelector("[data-position-badge]")
      if (badge) badge.textContent = `#${index + 1}`

      const innerCard = item.querySelector(".studio-order-card")
      const roleBadge = item.querySelector("[data-role-badge]")
      const btnCover = item.querySelector("[data-btn-cover]")
      const btnHover = item.querySelector("[data-btn-hover]")

      if (innerCard) {
        innerCard.classList.remove("border-warning", "border-info", "border-2")
      }

      if (item.dataset.type === "ProjectImage") {
        imageRank += 1
        const imgEl = item.querySelector("img")
        const imgSrc = imgEl ? imgEl.getAttribute("src") : null

        if (imageRank === 1) {
          coverUrl = imgSrc
          if (innerCard) innerCard.classList.add("border-warning", "border-2")
          if (roleBadge) {
            roleBadge.textContent = "★ ẢNH BÌA (Trang Chủ & Studio)"
            roleBadge.className = "badge bg-warning text-dark"
          }
          if (btnCover) {
            btnCover.className = "btn btn-sm btn-warning text-dark fw-semibold flex-grow-1 py-1"
            btnCover.innerHTML = '<i class="fas fa-star me-1"></i>Đang là Ảnh Bìa'
          }
          if (btnHover) {
            btnHover.className = "btn btn-sm btn-outline-info text-dark py-1"
            btnHover.innerHTML = "✦ Đặt Hover"
          }
        } else if (imageRank === 2) {
          hoverUrl = imgSrc
          if (innerCard) innerCard.classList.add("border-info", "border-2")
          if (roleBadge) {
            roleBadge.textContent = "✦ ẢNH HOVER (Khi rê chuột)"
            roleBadge.className = "badge bg-info text-dark"
          }
          if (btnCover) {
            btnCover.className = "btn btn-sm btn-outline-warning text-dark py-1"
            btnCover.innerHTML = '<i class="fas fa-star me-1"></i>Đặt Bìa'
          }
          if (btnHover) {
            btnHover.className = "btn btn-sm btn-info text-dark fw-semibold flex-grow-1 py-1"
            btnHover.innerHTML = "✦ Đang là Hover"
          }
        } else {
          if (roleBadge) {
            roleBadge.textContent = ""
            roleBadge.className = "d-none"
          }
          if (btnCover) {
            btnCover.className = "btn btn-sm btn-outline-warning text-dark flex-grow-1 py-1"
            btnCover.innerHTML = '<i class="fas fa-star me-1"></i>Đặt Bìa'
          }
          if (btnHover) {
            btnHover.className = "btn btn-sm btn-outline-info text-dark flex-grow-1 py-1"
            btnHover.innerHTML = "✦ Đặt Hover"
          }
        }
      } else if (roleBadge) {
        roleBadge.textContent = ""
        roleBadge.className = "d-none"
      }
    })

    // Cập nhật trực tiếp ảnh trên Khung Xem Trước Website ở đầu trang
    document.querySelectorAll("[data-preview-cover-img]").forEach((img) => {
      if (coverUrl) {
        img.src = coverUrl
        img.classList.remove("d-none")
      }
    })
    document.querySelectorAll("[data-preview-hover-img]").forEach((img) => {
      if (hoverUrl || coverUrl) {
        img.src = hoverUrl || coverUrl
        img.classList.remove("d-none")
      }
    })

    if (this.hasSortedEmptyTarget) {
      this.sortedEmptyTarget.classList.toggle("d-none", items.length > 0)
    }

    if (this.hasDisplayedTotalTarget) {
      this.displayedTotalTarget.textContent = items.length
    }

    if (this.hasHiddenInputTarget) {
      this.hiddenInputTarget.value = JSON.stringify(this.currentPositions())
    }

    let poolSum = 0
    this.element.querySelectorAll("[data-unsorted-container]").forEach((container) => {
      const type = container.dataset.unsortedContainer
      const count = container.querySelectorAll("[data-content-key]").length
      poolSum += count
      const tabCount = this.element.querySelector(`[data-tab-count="${type}"]`)
      if (tabCount) tabCount.textContent = count
      const empty = this.element.querySelector(`[data-unsorted-empty="${type}"]`)
      if (empty) empty.classList.toggle("d-none", count > 0)
    })

    if (this.hasPoolTotalTarget) {
      this.poolTotalTarget.textContent = poolSum
    }

    this.applyFilter()
  }

  setStatus(state, message = null) {
    if (!this.hasStatusTarget) return
    const templates = {
      saving: `<span class="badge rounded-pill bg-warning text-dark px-3 py-2"><i class="fas fa-circle-notch fa-spin me-1"></i>Đang tự động lưu…</span>`,
      saved: `<span class="badge rounded-pill bg-success-subtle text-success border border-success-subtle px-3 py-2"><i class="fas fa-check-circle me-1"></i>Đã lưu tự động lên Website</span>`,
      error: `<span class="badge rounded-pill bg-danger px-3 py-2"><i class="fas fa-exclamation-triangle me-1"></i>${message || "Lưu thất bại"}</span>
              <button type="button" class="btn btn-sm btn-outline-danger ms-2" data-action="content-order#retry">
                <i class="fas fa-redo me-1"></i>Thử lại
              </button>`
    }
    this.statusTarget.innerHTML = templates[state]
  }
}
