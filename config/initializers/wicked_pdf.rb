require 'wicked_pdf'
WickedPdf.configure do |config|
  config.exe_path = "C:\\Program Files\\wkhtmltopdf\\bin\\wkhtmltopdf.exe"

  config.layout = 'pdf'
  config.orientation = 'Portrait'
  config.lowquality = true
  config.zoom = 1
  config.dpi = 75
end
