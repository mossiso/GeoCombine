require 'nokogiri'

module GeoCombine

  ##
  # TODO: Create a parse method that can interpret the type of metadata being
  # passed in.
  #
  # def self.parse metadata
  # end

  ##
  # Abstract class for GeoCombine objects
  class Metadata
    attr_reader :metadata

    ##
    # Creates a new GeoCombine::Metadata object, where metadata parameter is can
    # be a File path or String of XML
    # @param [String] metadata can be a File path 
    # "./tmp/edu.stanford.purl/bb/338/jh/0716/iso19139.xml" or a String of XML
    # metadata
    def initialize metadata
      metadata = File.read metadata if File.readable? metadata
      metadata = Nokogiri::XML(metadata) if metadata.instance_of? String
      @metadata = metadata
    end

    ##
    # Perform an XSLT tranformation on metadata using an object's XSL
    # @return [GeoCombine::Geoblacklight] the data transformed into geoblacklight schema, returned as a GeoCombine::Geoblacklight
    def to_geoblacklight
      GeoCombine::Geoblacklight.new(xsl_geoblacklight.transform(@metadata))
    end

    ##
    # Perform an XSLT transformation to HTML using an object's XSL
    # @return [String] the xml transformed to an HTML String
    def to_html
      xsl_html.transform(@metadata).to_html
    end
  end
end

require 'geo_combine/fgdc'
require 'geo_combine/geoblacklight'
require 'geo_combine/iso19139'
require 'geo_combine/version'
