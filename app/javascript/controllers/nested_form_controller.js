import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nested-form"
export default class extends Controller {
  static targets = ["template", "container"]
  
  connect() {
    console.log("Nested form controller connected")
  }
  
  // Thêm một association mới
  add(event) {
    event.preventDefault()
    
    // Tạo ID duy nhất dựa trên timestamp
    const timestamp = new Date().getTime()
    
    // Lấy template và thay thế NEW_RECORD với timestamp
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, timestamp)
    
    // Thêm vào container
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    
    // Initialize TinyMCE for new fields
    if (typeof tinyMCE !== 'undefined') {
      // Find the new textarea with tinymce class
      const newTextareas = this.containerTarget.querySelectorAll('textarea.tinymce:not(.tinymce-active)');
      
      if (newTextareas.length > 0) {
        newTextareas.forEach(textarea => {
          textarea.classList.add('tinymce-active');
          tinyMCE.execCommand('mceAddEditor', false, textarea.id || 'mce_' + timestamp);
        });
      }
    }
  }
  
  // Xóa một association
  remove(event) {
    event.preventDefault()
    
    const item = event.target.closest(".nested-fields")
    
    // Check if there's a hidden input for _destroy
    const hiddenField = item.querySelector('input[name*="_destroy"]')
    
    if (hiddenField) {
      // If it exists, set its value to '1' (mark for deletion)
      hiddenField.value = "1"
      item.style.display = 'none'
    } else {
      // If no hidden field (likely a new record), just remove from DOM
      item.remove()
    }
  }
}
