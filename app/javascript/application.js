  // Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "jquery"
import "bootstrap"
import "trix"
import "@rails/actiontext"

// Ensure Bootstrap JS is properly imported
import 'bootstrap'

// Initialize Bootstrap components
document.addEventListener('turbo:load', function() {
  // Initialize all accordions
  const accordions = document.querySelectorAll('.accordion')
  accordions.forEach(accordion => {
    new bootstrap.Collapse(accordion.querySelector('.accordion-collapse'), {
      toggle: false
    })
  })
})

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

// Initialize TinyMCE for existing textareas
document.addEventListener("turbo:load", function() {
  if (typeof tinyMCE !== 'undefined') {
    tinyMCE.remove();
    
    const textareas = document.querySelectorAll('textarea.tinymce:not(.tinymce-active)')
    textareas.forEach(textarea => {
      const uniqueId = `tinymce_${new Date().getTime()}_${Math.random().toString(36).substr(2, 9)}`
      textarea.id = uniqueId
      textarea.classList.add('tinymce-active')
      
      tinyMCE.init({
        selector: `#${uniqueId}`,
        plugins: [
          'advlist', 'autolink', 'lists', 'link', 'image', 'charmap', 'preview',
          'anchor', 'searchreplace', 'visualblocks', 'code', 'fullscreen',
          'insertdatetime', 'media', 'table', 'help', 'wordcount', 'emoticons',
          'paste', 'save', 'autosave', 'pagebreak', 'nonbreaking', 'template',
          'codesample', 'directionality', 'visualchars', 'quickbars'
        ],
        toolbar1: 'undo redo | styles fontfamily fontsize | bold italic underline strikethrough subscript superscript | forecolor backcolor | alignleft aligncenter alignright alignjustify | bullist numlist | outdent indent',
        toolbar2: 'image media link | table | charmap emoticons codesample | pagebreak nonbreaking | searchreplace code fullscreen | visualblocks visualchars | help',
        
        // Cấu hình menu (hiển thị đầy đủ menu)
        menubar: 'file edit view insert format tools table help',
        menu: {
          file: { title: 'File', items: 'newdocument restoredraft | preview | print' },
          edit: { title: 'Edit', items: 'undo redo | cut copy paste pastetext | selectall | searchreplace' },
          view: { title: 'View', items: 'code | visualaid visualchars visualblocks | spellchecker | preview fullscreen' },
          insert: { title: 'Insert', items: 'image link media template codesample inserttable | charmap emoticons hr | pagebreak nonbreaking anchor | insertdatetime' },
          format: { title: 'Format', items: 'bold italic underline strikethrough superscript subscript codeformat | formats blockformats fontformats fontsizes align lineheight | forecolor backcolor | removeformat' },
          tools: { title: 'Tools', items: 'spellchecker spellcheckerlanguage | code wordcount' },
          table: { title: 'Table', items: 'inserttable | cell row column | advtablesort | tableprops deletetable' }
        },
        
        // Cấu hình font và kích thước
        font_family_formats: 'Arial=arial,helvetica,sans-serif; Arial Black=arial black,avant garde; Book Antiqua=book antiqua,palatino; Comic Sans MS=comic sans ms,sans-serif; Courier New=courier new,courier; Georgia=georgia,palatino; Helvetica=helvetica; Impact=impact,chicago; Symbol=symbol; Tahoma=tahoma,arial,helvetica,sans-serif; Terminal=terminal,monaco; Times New Roman=times new roman,times; Trebuchet MS=trebuchet ms,geneva; Verdana=verdana,geneva; Webdings=webdings; Wingdings=wingdings,zapf dingbats',
        font_size_formats: '8pt 9pt 10pt 11pt 12pt 14pt 16pt 18pt 20pt 22pt 24pt 26pt 28pt 36pt 48pt 72pt',
        
        // Cấu hình styles
        style_formats: [
          { title: 'Headers', items: [
            { title: 'Header 1', format: 'h1' },
            { title: 'Header 2', format: 'h2' },
            { title: 'Header 3', format: 'h3' },
            { title: 'Header 4', format: 'h4' },
            { title: 'Header 5', format: 'h5' },
            { title: 'Header 6', format: 'h6' }
          ]},
          { title: 'Inline', items: [
            { title: 'Bold', format: 'bold' },
            { title: 'Italic', format: 'italic' },
            { title: 'Underline', format: 'underline' },
            { title: 'Strikethrough', format: 'strikethrough' },
            { title: 'Superscript', format: 'superscript' },
            { title: 'Subscript', format: 'subscript' },
            { title: 'Code', format: 'code' }
          ]},
          { title: 'Blocks', items: [
            { title: 'Paragraph', format: 'p' },
            { title: 'Blockquote', format: 'blockquote' },
            { title: 'Div', format: 'div' },
            { title: 'Pre', format: 'pre' }
          ]}
        ],
        
        // Cấu hình hình ảnh
        image_advtab: true,
        image_caption: true,
        image_dimensions: true,
        paste_data_images: true,
        automatic_uploads: true,
        file_picker_types: 'image',
        
        // Cấu hình bảng
        table_default_attributes: {
          border: '1'
        },
        table_default_styles: {
          'border-collapse': 'collapse',
          'width': '100%'
        },
        table_responsive_width: true,
        
        // Cấu hình khác
        height: 500,
        min_height: 300,
        max_height: 800,
        autoresize_bottom_margin: 50,
        statusbar: true,
        branding: false,
        promotion: false,
        browser_spellcheck: true,
        contextmenu: 'link image table',
        
        // Style mặc định
        content_style: `
          body {
            font-family: Arial, sans-serif;
            font-size: 14pt;
            line-height: 1.6;
            margin: 15px;
          }
          table {
            border-collapse: collapse;
            width: 100%;
            margin: 15px 0;
          }
          table td, table th {
            border: 1px solid #ddd;
            padding: 8px;
          }
          img {
            max-width: 100%;
            height: auto;
          }
          blockquote {
            border-left: 3px solid #ccc;
            margin-left: 20px;
            padding-left: 20px;
            color: #666;
          }
          pre {
            background: #f4f4f4;
            padding: 15px;
            border-radius: 4px;
          }
        `
      });
    });
  }
});
