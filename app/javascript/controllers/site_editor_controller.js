import { Controller } from "@hotwired/stimulus"

// So sánh 2 giá trị bất kể thứ tự key (Postgres jsonb tự sắp xếp lại key của object)
const stable = (v) => {
  if (Array.isArray(v)) return v.map(stable)
  if (v && typeof v === "object") return Object.keys(v).sort().reduce((o, k) => { o[k] = stable(v[k]); return o }, {})
  return v
}
const same = (a, b) => JSON.stringify(stable(a)) === JSON.stringify(stable(b))

// "Sửa giao diện website"
// - Khung trái: website thật (moc-fe) mở trong iframe với ?moc_edit=1
// - Cột phải: ô nhập theo trang → khu vực → ô
// Hai bên nói chuyện qua window.postMessage:
//   admin → site : values (xem trước), labels, outline (bật/tắt viền), locate (chỉ vị trí)
//   site  → admin: ready, route (đổi trang), select (click vùng chữ), select-project, missing
export default class extends Controller {
  static targets = [
    "valuesJson", "defaultsJson", "labelsJson", "pagesJson", "fieldPageJson", "projectsJson",
    "tab", "pagePanel", "field", "frame", "stage", "stageMsg", "url", "openLink",
    "status", "saveBtn", "discardBtn", "outlineToggle", "deviceBtn", "projectSelect",
    "pageTitle", "pageSubtitle", "search", "panelScroll",
    "projectCard", "projectName", "drawer", "drawerFrame", "drawerTitle", "drawerOpenTab"
  ]

  static values = {
    frontendOrigin: String,
    saveUrl: String,
    uploadUrl: String,
    initialPage: String,
    editProjectUrl: String,
    mediaProjectUrl: String
  }

  connect() {
    this.saved = this.readJson(this.valuesJsonTarget)
    this.defaults = this.readJson(this.defaultsJsonTarget)
    this.labels = this.readJson(this.labelsJsonTarget)
    this.pages = this.readJson(this.pagesJsonTarget)
    this.fieldPage = this.readJson(this.fieldPageJsonTarget)
    this.projects = this.readJson(this.projectsJsonTarget)
    this.frameReady = false

    this.fieldTargets.forEach((el) => {
      this.setFieldValue(el, this.saved[el.dataset.key])
      el.addEventListener("input", () => this.fieldChanged(el))
      el.addEventListener("change", () => this.fieldChanged(el))
    })

    this.onMessage = this.onMessage.bind(this)
    this.onKeydown = this.onKeydown.bind(this)
    this.onBeforeUnload = this.onBeforeUnload.bind(this)
    window.addEventListener("message", this.onMessage)
    window.addEventListener("keydown", this.onKeydown)
    window.addEventListener("beforeunload", this.onBeforeUnload)

    this.showPage(this.initialPageValue, { navigate: true })
    this.refreshDirtyState()
  }

  disconnect() {
    window.removeEventListener("message", this.onMessage)
    window.removeEventListener("keydown", this.onKeydown)
    window.removeEventListener("beforeunload", this.onBeforeUnload)
    clearTimeout(this.previewTimer)
    clearTimeout(this.readyTimer)
  }

  // ===================================================================
  // Trang & khung xem trước
  // ===================================================================
  selectTab(event) {
    this.closeProjectCard()
    this.showPage(event.currentTarget.dataset.pageId, { navigate: true })
  }

  showPage(pageId, { navigate = false } = {}) {
    const page = this.pages.find((p) => p.id === pageId) || this.pages[0]
    this.activePage = page.id

    this.tabTargets.forEach((t) => t.classList.toggle("is-active", t.dataset.pageId === page.id))
    this.pagePanelTargets.forEach((p) => p.classList.toggle("se-hidden", p.dataset.pageId !== page.id))
    this.pageTitleTarget.textContent = page.name
    this.pageSubtitleTarget.textContent = page.path === "/projects/:id"
      ? "Đường dẫn: /projects/<mã dự án> — chọn dự án để xem ở thanh phía trên khung xem trước"
      : `Đường dẫn trên website: ${page.path}`
    this.projectSelectTarget.classList.toggle("se-hidden", page.id !== "project")
    if (this.hasSearchTarget) { this.searchTarget.value = ""; this.filter() }

    if (navigate) this.navigateFrame(this.pathFor(page))
    // Giữ tab đang mở trên thanh địa chỉ (F5 vẫn ở đúng trang)
    if (/\/site_editor(\/[\w-]*)?$/.test(location.pathname)) {
      history.replaceState(null, "", location.pathname.replace(/\/site_editor(\/[\w-]*)?$/, `/site_editor/${page.id}`))
    }
  }

  pathFor(page) {
    if (page.path !== "/projects/:id") return page.path
    const id = this.projectSelectTarget.value || this.projects[0]?.id
    return id ? `/projects/${id}` : "/studio"
  }

  changePreviewProject() {
    this.navigateFrame(this.pathFor({ path: "/projects/:id" }))
  }

  navigateFrame(path) {
    const url = `${this.frontendOriginValue}${path}${path.includes("?") ? "&" : "?"}moc_edit=1`
    this.frameReady = false
    this.frameTarget.src = url
    this.setUrl(path)
    clearTimeout(this.readyTimer)
    this.stageMsgTarget.classList.remove("is-visible")
    // Website không trả lời "ready" sau 15s → báo lỗi kết nối
    this.readyTimer = setTimeout(() => {
      if (!this.frameReady) this.stageMsgTarget.classList.add("is-visible")
    }, 15000)
  }

  setUrl(path) {
    this.urlTarget.textContent = `${this.frontendOriginValue}${path}`
    this.openLinkTarget.href = `${this.frontendOriginValue}${path}`
  }

  reloadFrame() {
    this.navigateFrame(this.currentPath || this.pathFor(this.pages.find((p) => p.id === this.activePage)))
  }

  frameLoaded() {
    // Trang tải xong nhưng không phải moc-fe (ví dụ lỗi 404 của máy chủ khác) → chờ readyTimer xử lý
  }

  setDevice(event) {
    const device = event.currentTarget.dataset.device
    this.deviceBtnTargets.forEach((b) => b.classList.toggle("is-active", b.dataset.device === device))
    this.stageTarget.classList.toggle("is-mobile", device === "mobile")
  }

  toggleOutline() {
    this.post({ type: "outline", enabled: this.outlineToggleTarget.checked })
  }

  pageIdForPath(path) {
    if (path === "/" || path === "") return "home"
    if (path.startsWith("/studio")) return "gallery"
    if (/^\/projects\/\d+/.test(path)) return "project"
    if (path.startsWith("/about")) return "about"
    if (path.startsWith("/contact")) return "contact"
    if (path.startsWith("/pricing")) return "pricing"
    return null
  }

  // ===================================================================
  // Giao tiếp với website trong iframe
  // ===================================================================
  post(message) {
    if (!this.frameReady || !this.frameTarget.contentWindow) return
    this.frameTarget.contentWindow.postMessage({ source: "moc-admin", ...message }, this.frontendOriginValue)
  }

  onMessage(event) {
    if (event.origin !== this.frontendOriginValue) return
    const data = event.data || {}
    if (data.source !== "moc-site") return

    switch (data.type) {
      case "ready":
        this.frameReady = true
        clearTimeout(this.readyTimer)
        this.stageMsgTarget.classList.remove("is-visible")
        this.post({ type: "labels", labels: this.labels })
        this.post({ type: "outline", enabled: this.outlineToggleTarget.checked })
        this.post({ type: "values", values: this.collectAll() })
        if (this.pendingLocate) { this.post({ type: "locate", key: this.pendingLocate }); this.pendingLocate = null }
        break
      case "route": {
        this.currentPath = data.path
        this.setUrl(data.path)
        const pageId = this.pageIdForPath(data.path)
        const m = data.path.match(/^\/projects\/(\d+)/)
        if (m) this.projectSelectTarget.value = m[1]
        // Người dùng bấm link trong khung xem trước → đổi cột phải theo (trừ khi đang ở tab Dùng chung)
        if (pageId && pageId !== this.activePage && this.activePage !== "global") this.showPage(pageId)
        break
      }
      case "select":
        this.focusField(data.key)
        break
      case "select-project":
        this.showProject(Number(data.id))
        break
      case "missing":
        this.flashStatus("Vùng này không hiển thị ở màn hình hiện tại (có thể chỉ hiện ở kích thước màn hình khác, hoặc sau khi khách thao tác).", "is-error")
        break
    }
  }

  // ===================================================================
  // Chọn ô nhập / dự án
  // ===================================================================
  focusField(key) {
    const el = this.fieldTargets.find((f) => f.dataset.key === key)
    if (!el) return
    this.closeProjectCard()
    if (el.dataset.page !== this.activePage) this.showPage(el.dataset.page)
    if (this.searchTarget.value) { this.searchTarget.value = ""; this.filter() }
    const details = el.closest("details")
    if (details) details.open = true
    el.scrollIntoView({ behavior: "smooth", block: "center" })
    el.classList.remove("is-focus")
    void el.offsetWidth
    el.classList.add("is-focus")
    clearTimeout(this.focusTimer)
    this.focusTimer = setTimeout(() => el.classList.remove("is-focus"), 2500)
    const input = el.querySelector("[data-role=input], [data-sub]")
    if (input) setTimeout(() => input.focus({ preventScroll: true }), 350)
  }

  showProject(id) {
    const project = this.projects.find((p) => p.id === id)
    this.currentProjectId = id
    this.projectNameTarget.textContent = project ? project.name : `Dự án #${id}`
    this.projectCardTarget.classList.remove("se-hidden")
    this.panelScrollTarget.scrollTo({ top: 0, behavior: "smooth" })
  }

  closeProjectCard() {
    this.projectCardTarget.classList.add("se-hidden")
  }

  locate(event) {
    const el = event.currentTarget.closest("[data-site-editor-target=field]")
    const key = el.dataset.key
    const fieldPageId = this.fieldPage[key]
    const currentPageId = this.pageIdForPath(this.currentPath || "")
    // Ô thuộc trang khác trang đang hiện trong khung → mở đúng trang rồi mới chỉ vị trí
    if (fieldPageId !== "global" && fieldPageId !== currentPageId) {
      this.pendingLocate = key
      this.showPage(fieldPageId, { navigate: true })
      return
    }
    this.post({ type: "locate", key })
  }

  filter() {
    const q = this.searchTarget.value.trim().toLowerCase()
    const panel = this.pagePanelTargets.find((p) => p.dataset.pageId === this.activePage)
    if (!panel) return
    panel.querySelectorAll("[data-site-editor-target=field]").forEach((f) => {
      f.classList.toggle("se-hidden", q !== "" && !f.dataset.search.includes(q))
    })
    panel.querySelectorAll("details").forEach((d) => {
      const anyVisible = d.querySelector("[data-site-editor-target=field]:not(.se-hidden)")
      d.classList.toggle("se-hidden", !anyVisible)
      if (q) d.open = true
    })
  }

  // ===================================================================
  // Đọc / ghi giá trị ô nhập
  // ===================================================================
  getFieldValue(el) {
    const type = el.dataset.type
    if (type === "list") {
      return Array.from(el.querySelectorAll("[data-role=item]")).map((item) => {
        const obj = {}
        item.querySelectorAll("[data-sub]").forEach((input) => {
          const subType = input.dataset.subType
          if (subType === "boolean") obj[input.dataset.sub] = input.checked
          else if (subType === "lines") obj[input.dataset.sub] = this.splitLines(input.value)
          else obj[input.dataset.sub] = input.value.trim()
        })
        return obj
      })
    }
    if (type === "images") {
      return Array.from(el.querySelectorAll("[data-role=gallery-item]")).map((item) => item.dataset.url)
    }
    if (type === "projects") {
      return Array.from(el.querySelectorAll("[data-role=project-item]")).map((item) => Number(item.dataset.id))
    }
    const input = el.querySelector("[data-role=input]")
    if (type === "boolean") return input.checked
    if (type === "lines") return this.splitLines(input.value)
    return input.value
  }

  setFieldValue(el, value) {
    const type = el.dataset.type
    if (type === "list") {
      const container = el.querySelector("[data-role=items]")
      container.innerHTML = ""
      ;(Array.isArray(value) ? value : []).forEach((item) => this.appendItem(el, item))
      this.renumber(el)
      return
    }
    if (type === "images") {
      el.querySelector("[data-role=gallery]").innerHTML = ""
      ;(Array.isArray(value) ? value : []).forEach((url) => this.appendImage(el, url))
      this.renumberGallery(el)
      return
    }
    if (type === "projects") {
      el.querySelector("[data-role=project-list]").innerHTML = ""
      ;(Array.isArray(value) ? value : []).forEach((id) => this.appendProject(el, id))
      this.renumberProjects(el)
      return
    }
    const input = el.querySelector("[data-role=input]")
    if (type === "boolean") { input.checked = Boolean(value); return }
    input.value = type === "lines" ? (Array.isArray(value) ? value.join("\n") : "") : (value ?? "")
    if (type === "lines") input.rows = Math.max(3, input.value.split("\n").length + 1)
    if (type === "image") this.updateThumb(el)
    if (type === "video") this.updateVideoPreview(el)
  }

  appendItem(el, item = {}) {
    const template = el.querySelector("template[data-role=item-template]")
    const node = template.content.firstElementChild.cloneNode(true)
    node.querySelectorAll("[data-sub]").forEach((input) => {
      const v = item[input.dataset.sub]
      if (input.dataset.subType === "boolean") input.checked = Boolean(v)
      else if (input.dataset.subType === "lines") input.value = Array.isArray(v) ? v.join("\n") : (v || "")
      else input.value = v ?? ""
    })
    el.querySelector("[data-role=items]").appendChild(node)
    return node
  }

  addItem(event) {
    const el = event.currentTarget.closest("[data-site-editor-target=field]")
    const node = this.appendItem(el)
    this.renumber(el)
    this.fieldChanged(el)
    node.querySelector("[data-sub]")?.focus()
  }

  removeItem(event) {
    const item = event.currentTarget.closest("[data-role=item]")
    const el = item.closest("[data-site-editor-target=field]")
    item.remove()
    this.renumber(el)
    this.fieldChanged(el)
  }

  moveItemUp(event) { this.moveItem(event, -1) }
  moveItemDown(event) { this.moveItem(event, 1) }

  moveItem(event, dir) {
    const item = event.currentTarget.closest("[data-role=item]")
    const el = item.closest("[data-site-editor-target=field]")
    const sibling = dir < 0 ? item.previousElementSibling : item.nextElementSibling
    if (!sibling) return
    if (dir < 0) sibling.before(item)
    else sibling.after(item)
    this.renumber(el)
    this.fieldChanged(el)
  }

  renumber(el) {
    el.querySelectorAll("[data-role=item]").forEach((item, idx) => {
      const span = item.querySelector("[data-role=item-index]")
      if (span) span.textContent = `#${idx + 1}`
    })
  }

  updateThumb(el) {
    const thumb = el.querySelector("[data-role=thumb]")
    let src = el.querySelector("[data-role=input]").value.trim() || this.defaults[el.dataset.key] || ""
    src = this.normalizeImage(src)
    // Ảnh mặc định nằm trong thư mục public của website
    if (src.startsWith("/")) src = `${this.frontendOriginValue}${src}`
    thumb.src = src
  }

  normalizeImage(url) {
    const m = url.match(/drive\.google\.com\/file\/d\/([\w-]+)/) || url.match(/drive\.google\.com\/(?:open|uc)\?(?:.*&)?id=([\w-]+)/)
    return m ? `https://lh3.googleusercontent.com/d/${m[1]}` : url
  }

  splitLines(text) {
    return text.split(/\r?\n/).map((l) => l.trim()).filter(Boolean)
  }

  collectAll() {
    const values = {}
    this.fieldTargets.forEach((el) => {
      let v = this.getFieldValue(el)
      if (el.dataset.type === "image") v = this.normalizeImage(v.trim())
      if (el.dataset.type === "video") v = v.trim()
      // Ô để trống → website dùng nội dung mặc định
      const empty = v === "" || (Array.isArray(v) && v.length === 0)
      values[el.dataset.key] = empty ? this.defaults[el.dataset.key] : v
    })
    return values
  }

  resetField(event) {
    const el = event.currentTarget.closest("[data-site-editor-target=field]")
    this.setFieldValue(el, this.defaults[el.dataset.key])
    this.fieldChanged(el)
  }

  // ===================================================================
  // Thay đổi, xem trước, lưu
  // ===================================================================
  fieldChanged(el) {
    if (el.dataset.type === "image") this.updateThumb(el)
    if (el.dataset.type === "video") this.updateVideoPreview(el)
    el.classList.remove("is-error")
    const err = el.querySelector("[data-role=error]")
    if (err) err.textContent = ""
    this.refreshDirtyState()
    clearTimeout(this.previewTimer)
    this.previewTimer = setTimeout(() => this.post({ type: "values", values: this.collectAll() }), 120)
  }

  isDirty(el) {
    const current = this.collectAll()[el.dataset.key]
    return same(current, this.saved[el.dataset.key]) === false
  }

  refreshDirtyState() {
    const current = this.collectAll()
    const dirtyPages = new Set()
    let count = 0
    this.fieldTargets.forEach((el) => {
      const dirty = !same(current[el.dataset.key], this.saved[el.dataset.key])
      el.classList.toggle("is-dirty", dirty)
      if (dirty) { count++; dirtyPages.add(el.dataset.page) }
    })
    this.dirtyCount = count
    this.tabTargets.forEach((t) => t.classList.toggle("has-changes", dirtyPages.has(t.dataset.pageId)))
    this.saveBtnTarget.disabled = count === 0
    this.discardBtnTarget.disabled = count === 0
    if (!this.saving) {
      this.setStatus(count === 0 ? (this.lastSavedAt ? `Đã lưu lúc ${this.lastSavedAt}` : "Chưa có thay đổi") : `${count} ô chưa lưu`, count === 0 ? (this.lastSavedAt ? "is-ok" : "") : "is-dirty")
    }
  }

  discard() {
    if (!confirm(`Bỏ ${this.dirtyCount} thay đổi chưa lưu?`)) return
    this.fieldTargets.forEach((el) => this.setFieldValue(el, this.saved[el.dataset.key]))
    this.refreshDirtyState()
    this.post({ type: "values", values: this.collectAll() })
  }

  async save() {
    if (this.saving || this.dirtyCount === 0) return
    this.saving = true
    this.saveBtnTarget.disabled = true
    this.setStatus("Đang lưu…", "")
    const token = document.querySelector("meta[name=csrf-token]")?.content
    try {
      const response = await fetch(this.saveUrlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": token },
        body: JSON.stringify({ values: this.collectAll() })
      })
      const data = await response.json().catch(() => ({}))
      if (!response.ok || !data.ok) {
        this.showErrors(data.errors || [{ message: `Lỗi máy chủ (${response.status})` }])
        return
      }
      this.saved = data.values
      this.lastSavedAt = data.saved_at
      // Đồng bộ ô nhập với giá trị đã chuẩn hoá phía máy chủ (vd: link Drive → link ảnh)
      this.fieldTargets.forEach((el) => {
        if (!same(this.getFieldValue(el), this.saved[el.dataset.key])) {
          this.setFieldValue(el, this.saved[el.dataset.key])
        }
      })
      this.saving = false
      this.refreshDirtyState()
      this.flashStatus(`✓ Đã lưu lúc ${data.saved_at} — website đã cập nhật`, "is-ok")
    } catch (e) {
      this.showErrors([{ message: "Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại." }])
    } finally {
      this.saving = false
      this.saveBtnTarget.disabled = this.dirtyCount === 0
    }
  }

  showErrors(errors) {
    errors.forEach((err) => {
      const el = err.key && this.fieldTargets.find((f) => f.dataset.key === err.key)
      if (!el) return
      el.classList.add("is-error")
      el.querySelector("[data-role=error]").textContent = err.message
    })
    this.saving = false
    this.setStatus(`Lưu thất bại: ${errors.map((e) => e.message).join("; ")}`, "is-error")
    const first = errors.find((e) => e.key)
    if (first) this.focusField(first.key)
  }

  setStatus(text, cls) {
    this.statusTarget.textContent = text
    this.statusTarget.title = text
    this.statusTarget.className = `se-status ${cls || ""}`
  }

  flashStatus(text, cls) {
    this.setStatus(text, cls)
    clearTimeout(this.statusTimer)
    this.statusTimer = setTimeout(() => this.refreshDirtyState(), 5000)
  }

  onKeydown(event) {
    if (event.key === "Escape" && !this.drawerTarget.classList.contains("se-hidden")) {
      this.closeDrawer()
      return
    }
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "s") {
      event.preventDefault()
      this.save()
    }
  }

  onBeforeUnload(event) {
    if (this.dirtyCount > 0) {
      event.preventDefault()
      event.returnValue = ""
    }
  }

  // ===================================================================
  // Ảnh / video: xem trước, tải file lên
  // ===================================================================
  absoluteMedia(src) {
    // Ảnh/video mặc định nằm trong thư mục public của website
    return src && src.startsWith("/") ? `${this.frontendOriginValue}${src}` : src
  }

  updateVideoPreview(el) {
    const video = el.querySelector("[data-role=video-preview]")
    const src = el.querySelector("[data-role=input]").value.trim()
    video.classList.toggle("se-hidden", !src)
    if (src && video.getAttribute("src") !== this.absoluteMedia(src)) video.src = this.absoluteMedia(src)
    if (!src) video.removeAttribute("src")
  }

  async uploadFiles(event) {
    const input = event.currentTarget
    const el = input.closest("[data-site-editor-target=field]")
    const files = Array.from(input.files || [])
    input.value = ""
    if (files.length === 0) return
    const upload = input.closest(".se-upload")
    const progress = upload.querySelector("[data-role=progress]")

    if (el.dataset.type === "images") {
      const max = Number(el.dataset.max || 0)
      const room = max ? max - this.getFieldValue(el).length : files.length
      if (room <= 0) { this.showUploadState(progress, `Đã đủ ${max} ảnh — bỏ bớt ảnh cũ trước.`, true); return }
      files.splice(room)
    }

    for (let i = 0; i < files.length; i++) {
      const label = files.length > 1 ? `(${i + 1}/${files.length}) ` : ""
      try {
        const result = await this.sendFile(files[i], input.dataset.kind, (pct) => {
          this.showUploadState(progress, `${label}Đang tải ${files[i].name}… ${pct}%`, false, pct)
        })
        if (el.dataset.type === "images") {
          this.appendImage(el, result.url)
          this.renumberGallery(el)
        } else {
          el.querySelector("[data-role=input]").value = result.url
        }
        this.fieldChanged(el)
        this.showUploadState(progress, `✓ Đã tải lên ${result.filename} — nhớ bấm Lưu thay đổi`, false, 100)
      } catch (message) {
        this.showUploadState(progress, `${files[i].name}: ${message}`, true)
        return
      }
    }
  }

  sendFile(file, kind, onProgress) {
    return new Promise((resolve, reject) => {
      const form = new FormData()
      form.append("file", file)
      form.append("kind", kind)
      const xhr = new XMLHttpRequest()
      xhr.open("POST", this.uploadUrlValue)
      xhr.setRequestHeader("X-CSRF-Token", document.querySelector("meta[name=csrf-token]")?.content || "")
      xhr.setRequestHeader("Accept", "application/json")
      xhr.upload.onprogress = (e) => { if (e.lengthComputable) onProgress(Math.round((e.loaded / e.total) * 100)) }
      xhr.onload = () => {
        let data = {}
        try { data = JSON.parse(xhr.responseText) } catch { /* không phải JSON */ }
        if (xhr.status === 413) return reject("File quá lớn so với giới hạn của máy chủ.")
        if (xhr.status >= 200 && xhr.status < 300 && data.ok) resolve(data)
        else reject(data.error || `Tải lên thất bại (mã lỗi ${xhr.status}).`)
      }
      xhr.onerror = () => reject("Mất kết nối khi tải lên.")
      onProgress(0)
      xhr.send(form)
    })
  }

  showUploadState(progress, text, isError, pct) {
    progress.classList.remove("se-hidden")
    progress.classList.toggle("is-error", Boolean(isError))
    progress.querySelector("[data-role=progress-text]").textContent = text
    progress.querySelector("[data-role=progress-bar]").style.width = `${isError ? 0 : (pct ?? 0)}%`
    progress.querySelector(".se-progress-track").classList.toggle("se-hidden", Boolean(isError) || pct === 100)
  }

  // --- Nhiều ảnh ---
  appendImage(el, url) {
    const node = el.querySelector("template[data-role=gallery-template]").content.firstElementChild.cloneNode(true)
    node.dataset.url = url
    node.querySelector("img").src = this.absoluteMedia(this.normalizeImage(url))
    el.querySelector("[data-role=gallery]").appendChild(node)
  }

  renumberGallery(el) {
    const items = el.querySelectorAll("[data-role=gallery-item]")
    items.forEach((item, idx) => { item.querySelector("[data-role=gallery-index]").textContent = idx + 1 })
    el.querySelector("[data-role=gallery-empty]").classList.toggle("se-hidden", items.length > 0)
  }

  addImageLink(event) {
    const el = event.currentTarget.closest("[data-site-editor-target=field]")
    const input = el.querySelector("[data-role=gallery-link]")
    const url = this.normalizeImage(input.value.trim())
    if (!url) return
    const max = Number(el.dataset.max || 0)
    if (max && this.getFieldValue(el).length >= max) { alert(`Tối đa ${max} ảnh.`); return }
    this.appendImage(el, url)
    input.value = ""
    this.renumberGallery(el)
    this.fieldChanged(el)
  }

  removeImage(event) { this.changeGallery(event, (item) => item.remove()) }
  moveImageLeft(event) { this.changeGallery(event, (item) => item.previousElementSibling?.before(item)) }
  moveImageRight(event) { this.changeGallery(event, (item) => item.nextElementSibling?.after(item)) }

  changeGallery(event, fn) {
    const item = event.currentTarget.closest("[data-role=gallery-item]")
    const el = item.closest("[data-site-editor-target=field]")
    fn(item)
    this.renumberGallery(el)
    this.fieldChanged(el)
  }

  // --- Chọn dự án ---
  appendProject(el, id) {
    const project = this.projects.find((p) => p.id === Number(id))
    if (!project) return
    const node = el.querySelector("template[data-role=project-template]").content.firstElementChild.cloneNode(true)
    node.dataset.id = project.id
    node.querySelector("[data-role=project-name]").textContent = project.name
    el.querySelector("[data-role=project-list]").appendChild(node)
  }

  renumberProjects(el) {
    const chosen = this.getFieldValue(el)
    el.querySelectorAll("[data-role=project-item]").forEach((item, idx) => {
      item.querySelector("[data-role=project-index]").textContent = idx + 1
    })
    const select = el.querySelector("[data-role=project-add]")
    Array.from(select.options).forEach((opt) => { if (opt.value) opt.disabled = chosen.includes(Number(opt.value)) })
    const max = Number(el.dataset.max || 0)
    select.disabled = Boolean(max) && chosen.length >= max
  }

  addProject(event) {
    const select = event.currentTarget
    const el = select.closest("[data-site-editor-target=field]")
    if (select.value) this.appendProject(el, select.value)
    select.value = ""
    this.renumberProjects(el)
    this.fieldChanged(el)
  }

  removeProject(event) { this.changeProjects(event, (item) => item.remove()) }
  moveProjectUp(event) { this.changeProjects(event, (item) => item.previousElementSibling?.before(item)) }
  moveProjectDown(event) { this.changeProjects(event, (item) => item.nextElementSibling?.after(item)) }

  changeProjects(event, fn) {
    const item = event.currentTarget.closest("[data-role=project-item]")
    const el = item.closest("[data-site-editor-target=field]")
    fn(item)
    this.renumberProjects(el)
    this.fieldChanged(el)
  }

  // ===================================================================
  // Ngăn trượt: sửa ảnh / video / mô tả của một dự án
  // ===================================================================
  openProjectEditor(event) {
    const id = this.currentProjectId
    if (!id) return
    const mode = event.currentTarget.dataset.mode
    const template = mode === "media" ? this.mediaProjectUrlValue : this.editProjectUrlValue
    const url = template.replace("__ID__", id) + (mode === "media" ? "" : "#content-studio")
    const project = this.projects.find((p) => p.id === id)
    this.drawerTitleTarget.textContent = `${mode === "media" ? "Ảnh bìa / hover" : "Sửa dự án"}: ${project ? project.name : "#" + id}`
    this.drawerOpenTabTarget.href = url
    this.drawerFrameTarget.src = url
    this.drawerTarget.classList.remove("se-hidden")
  }

  closeDrawer() {
    this.drawerTarget.classList.add("se-hidden")
    this.drawerFrameTarget.src = "about:blank"
    // Ảnh/video của dự án có thể vừa đổi → tải lại trang xem trước
    this.reloadFrame()
  }

  readJson(el) {
    try { return JSON.parse(el.textContent) } catch { return {} }
  }
}
