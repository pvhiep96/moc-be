import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]
  
  connect() {
    console.log("Nested form controller connected")
  }
  
  add(event) {
    event.preventDefault()
    const timestamp = new Date().getTime()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, timestamp)
    this.containerTarget.insertAdjacentHTML("beforeend", content)
    
    const newTextareas = this.containerTarget.querySelectorAll('textarea.tinymce:not(.tinymce-active)')
    
    if (newTextareas.length > 0) {
      newTextareas.forEach(textarea => {
        const uniqueId = `tinymce_${timestamp}_${Math.random().toString(36).substr(2, 9)}`
        textarea.id = uniqueId
        textarea.classList.add('tinymce-active')
        
        if (typeof tinyMCE !== 'undefined') {
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

            font_family_formats: 'Arial=arial,helvetica,sans-serif; Arial Black=arial black,avant garde; Book Antiqua=book antiqua,palatino; Comic Sans MS=comic sans ms,sans-serif; Courier New=courier new,courier; Georgia=georgia,palatino; Helvetica=helvetica; Impact=impact,chicago; Symbol=symbol; Tahoma=tahoma,arial,helvetica,sans-serif; Terminal=terminal,monaco; Times New Roman=times new roman,times; Trebuchet MS=trebuchet ms,geneva; Verdana=verdana,geneva; Webdings=webdings; Wingdings=wingdings,zapf dingbats',
            font_size_formats: '8pt 9pt 10pt 11pt 12pt 14pt 16pt 18pt 20pt 22pt 24pt 26pt 28pt 36pt 48pt 72pt',

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

            image_advtab: true,
            image_caption: true,
            image_dimensions: true,
            paste_data_images: true,
            automatic_uploads: true,
            file_picker_types: 'image',

            table_default_attributes: {
              border: '1'
            },
            table_default_styles: {
              'border-collapse': 'collapse',
              'width': '100%'
            },
            table_responsive_width: true,

            height: 500,
            min_height: 300,
            max_height: 800,
            autoresize_bottom_margin: 50,
            statusbar: true,
            branding: false,
            promotion: false,
            browser_spellcheck: true,
            contextmenu: 'link image table',

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
          })
        }
      })
    }
  }
  
  remove(event) {
    event.preventDefault()
    const item = event.target.closest(".nested-fields")
    const hiddenField = item.querySelector('input[name*="_destroy"]')
    
    if (hiddenField) {
      hiddenField.value = "1"
      item.style.display = 'none'
    } else {
      item.remove()
    }
  }
}
