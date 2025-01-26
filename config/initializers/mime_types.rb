# Be sure these lines are in your mime_types.rb

Mime::Type.register "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", :xlsx
Mime::Type.register "application/pdf", :pdf unless Mime::Type.lookup_by_extension(:pdf)