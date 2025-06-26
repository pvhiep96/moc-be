import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea"]

  connect() {
    console.log("TinyMCE controller connected")
    console.log("Textarea targets found:", this.textareaTargets.length)
    this.initializeTinyMCE()
  }

  disconnect() {
    // Clean up TinyMCE instances when controller disconnects
    if (this.textareaTargets.length > 0) {
      this.textareaTargets.forEach(textarea => {
        if (textarea.id && typeof tinyMCE !== 'undefined' && tinyMCE.get(textarea.id)) {
          tinyMCE.remove(textarea.id)
        }
      })
    }
  }

  initializeTinyMCE() {
    // Wait for TinyMCE to be available
    if (typeof tinyMCE === 'undefined') {
      console.log("TinyMCE not loaded yet, retrying in 100ms")
      setTimeout(() => this.initializeTinyMCE(), 100)
      return
    }

    console.log("TinyMCE is available, initializing editors")
    this.textareaTargets.forEach(textarea => {
      if (!textarea.classList.contains('tinymce-active')) {
        this.setupTinyMCE(textarea)
      }
    })
  }

  setupTinyMCE(textarea) {
    // Generate unique ID if not present
    if (!textarea.id) {
      textarea.id = `tinymce_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    }

    textarea.classList.add('tinymce-active')

    const config = {
      selector: `#${textarea.id}`,
      plugins: [
        'advlist', 'autolink', 'lists', 'link', 'image', 'charmap', 'preview',
        'anchor', 'searchreplace', 'visualblocks', 'code', 'fullscreen',
        'insertdatetime', 'media', 'table', 'help', 'wordcount', 'emoticons',
        'paste', 'save', 'autosave', 'pagebreak', 'nonbreaking', 'template',
        'codesample', 'directionality', 'visualchars', 'quickbars'
      ],
      toolbar: 'undo redo | formatselect | bold italic underline strikethrough | alignleft aligncenter alignright | bullist numlist outdent indent | link image | removeformat',
      
      height: 400,
      min_height: 300,
      max_height: 800,
      statusbar: true,
      branding: false,
      promotion: false,
      browser_spellcheck: true,

      // Custom font support
      font_family_formats: 'Arial=arial,helvetica,sans-serif; Arial Black=arial black,avant garde; Book Antiqua=book antiqua,palatino; Comic Sans MS=comic sans ms,sans-serif; Courier New=courier new,courier; Georgia=georgia,palatino; Helvetica=helvetica; Impact=impact,chicago; Symbol=symbol; Tahoma=tahoma,arial,helvetica,sans-serif; Terminal=terminal,monaco; Times New Roman=times new roman,times; Trebuchet MS=trebuchet ms,geneva; Verdana=verdana,geneva; Webdings=webdings; Wingdings=wingdings,zapf dingbats; DFVN TAN - MON CHERI="DFVN TAN - MON CHERI",sans-serif',
      font_size_formats: '8pt 9pt 10pt 11pt 12pt 14pt 16pt 18pt 20pt 22pt 24pt 26pt 28pt 36pt 48pt 72pt',

      content_style: `
        @font-face {
          font-family: 'DFVN TAN - MON CHERI';
          src: url('/DFVN TAN - MON CHERI.ttf') format('truetype');
          font-weight: normal;
          font-style: normal;
          font-display: swap;
        }
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
        .mon-cheri-font {
          font-family: 'DFVN TAN - MON CHERI', sans-serif;
        }
      `,

      setup: (editor) => {
        console.log(`TinyMCE editor setup for ${textarea.id}`)
        // Sync content back to textarea on change
        editor.on('change', () => {
          editor.save()
        })
      },

      init_instance_callback: (editor) => {
        console.log(`TinyMCE editor initialized for ${textarea.id}`)
      }
    }

    try {
      tinyMCE.init(config)
      console.log(`TinyMCE initialization started for ${textarea.id}`)
    } catch (error) {
      console.error('Error initializing TinyMCE:', error)
    }
  }

  // Method to initialize TinyMCE for dynamically added textareas
  initializeNew(textarea) {
    console.log("Initializing new TinyMCE textarea:", textarea)
    if (typeof tinyMCE !== 'undefined') {
      this.setupTinyMCE(textarea)
    } else {
      // Wait for TinyMCE to load
      console.log("TinyMCE not available, retrying...")
      setTimeout(() => this.initializeNew(textarea), 100)
    }
  }
} 