// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "jquery"
import "bootstrap"
import "trix"
import "@rails/actiontext"

// Hàm xử lý nút thêm fields
function handleAddFields(event) {
  if (event.target.classList.contains('add_fields')) {
    event.preventDefault();
    const time = new Date().getTime();
    const regexp = new RegExp(event.target.dataset.id, 'g');
    const template = event.target.dataset.fields.replace(regexp, time);
    
    // Lấy node dựa trên data-association-insertion-node attribute
    const targetNodeSelector = event.target.getAttribute('data-association-insertion-node');
    const targetNode = document.querySelector(targetNodeSelector);
    
    if (targetNode) {
      // Lấy phương thức chèn từ data-association-insertion-method attribute
      const insertionMethod = event.target.getAttribute('data-association-insertion-method');
      
      if (insertionMethod === 'append') {
        targetNode.insertAdjacentHTML('beforeend', template);
      } else {
        targetNode.insertAdjacentHTML('afterbegin', template);
      }
    }
  }
}

// Hàm xử lý nút xóa fields
function handleRemoveFields(event) {
  if (event.target.classList.contains('remove_fields')) {
    event.preventDefault();
    const wrapper = event.target.closest('.nested-fields');
    if (wrapper) {
      const hiddenField = wrapper.querySelector('input[type=hidden][name*="_destroy"]');
      if (hiddenField) {
        hiddenField.value = '1';
      }
      wrapper.style.display = 'none';
    }
  }
}

// Gắn sự kiện vào document để chúng có thể hoạt động với các phần tử được thêm vào sau
function setupEventHandlers() {
  document.removeEventListener('click', handleAddFields);
  document.removeEventListener('click', handleRemoveFields);
  document.addEventListener('click', handleAddFields);
  document.addEventListener('click', handleRemoveFields);
}

// Khởi tạo các sự kiện
function initializeEvents() {
  setupEventHandlers();
  
  // Enable Bootstrap tooltips
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
  if (tooltipTriggerList.length > 0) {
    [...tooltipTriggerList].map(tooltipTriggerEl => new bootstrap.Tooltip(tooltipTriggerEl));
  }

  // Enable Bootstrap popovers
  const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
  if (popoverTriggerList.length > 0) {
    [...popoverTriggerList].map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl));
  }
}

// Khởi tạo khi load trang với Turbo
document.addEventListener("turbo:load", initializeEvents);
// Khởi tạo khi trang sẵn sàng (cho trường hợp không dùng Turbo)
document.addEventListener("DOMContentLoaded", initializeEvents);

// Initialize TinyMCE
document.addEventListener("turbo:load", function() {
  initTinyMCE();
});

// Also initialize on DOMContentLoaded
document.addEventListener("DOMContentLoaded", function() {
  initTinyMCE();
});

function initTinyMCE() {
  if (typeof tinyMCE !== 'undefined') {
    tinyMCE.remove();
    tinyMCE.init({
      selector: 'textarea.tinymce',
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
      quickbars_insert_toolbar: 'image media table hr',
      content_style: 'body { font-family: Roboto, Arial, sans-serif; font-size: 14px; }',
      contextmenu: 'link image table paste',
      style_formats: [
        { title: 'Headings', items: [
          { title: 'Heading 1', format: 'h1' },
          { title: 'Heading 2', format: 'h2' },
          { title: 'Heading 3', format: 'h3' },
          { title: 'Heading 4', format: 'h4' },
          { title: 'Heading 5', format: 'h5' },
          { title: 'Heading 6', format: 'h6' }
        ]},
        { title: 'Inline', items: [
          { title: 'Bold', format: 'bold' },
          { title: 'Italic', format: 'italic' },
          { title: 'Underline', format: 'underline' },
          { title: 'Strikethrough', format: 'strikethrough' },
          { title: 'Superscript', format: 'superscript' },
          { title: 'Subscript', format: 'subscript' },
          { title: 'Code', format: 'code' }
        ]}
      ]
    });
  }
}
