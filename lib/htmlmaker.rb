# Converts the iso19139.xml files into geoblacklight.html files.
# Looks for the files in tmp/opengeometadata/edu.virginia/


gem 'geo_combine'
require 'geo_combine'
gem 'json'
require 'json'
gem 'nokogiri'
require 'nokogiri'

Dir.glob("../tmp/opengeometadata/edu.virginia/**/*iso19139.xml") do |file|
  abs_path = File.absolute_path(file)
  path = File.dirname(abs_path)
  iso_metadata = GeoCombine::Iso19139.new(file)
  html = iso_metadata.to_html
  html_file = File.open("#{path}/geoblacklight.html", "w")
  html_file.write(html)
  html_file.close
end



