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
          // Ensure the textarea has an ID
          if (!textarea.id) {
            textarea.id = 'tinymce_' + timestamp + '_' + Math.floor(Math.random() * 1000);
          }
          
          textarea.classList.add('tinymce-active');
          
          // Initialize TinyMCE on this specific textarea
          tinyMCE.init({
            selector: '#' + textarea.id,
            plugins: 'advlist autolink lists link image charmap preview anchor searchreplace visualblocks code fullscreen insertdatetime media table paste code help wordcount emoticons hr pagebreak quickbars print template toc directionality visualchars nonbreaking save codesample importcss',
            toolbar: 'undo redo | bold italic underline strikethrough | fontfamily fontsize blocks | alignleft aligncenter alignright alignjustify | outdent indent | numlist bullist | forecolor backcolor removeformat | pagebreak | charmap emoticons | fullscreen preview save print | insertfile image media template link anchor codesample | ltr rtl | code',
            toolbar_mode: 'sliding',
            menubar: 'file edit view insert format tools table help',
            height: 400,
            entity_encoding: 'raw',
            convert_urls: false,
            relative_urls: false,
            branding: false,
            promotion: false,
            paste_data_images: true,
            image_advtab: true,
            quickbars_selection_toolbar: 'bold italic | quicklink h2 h3 blockquote',
            quickbars_insert_toolbar: 'image media table hr'
          });
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
