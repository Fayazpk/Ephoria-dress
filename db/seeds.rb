sizes = ['S', 'M', 'L', 'XL']
sizes.each do |size_name|
  Size.find_or_create_by!(size: size_name)
end
