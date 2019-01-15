# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# The ieee_oui filter allows you to match mac addresses to vendor names.
# It accepts source mac addresses delimited by a colon(:), a dash(-) or no delimiter.
# The filter requires a specially formatted oui-logstash.txt file for the ouifile.
# See https://github.com/Vigilant-LLC/logstash-oui-scraper
class LogStash::Filters::IeeeOui < LogStash::Filters::Base

  config_name "ieee_oui"

  # Example:
  # [source,ruby]
  # 	filter {
  # 	  ieee_oui {
  # 	    source => 'macaddress'
  # 	    target => 'oui_vendor'
  # 	    ouifile => '/path_to/oui-logstash.txt'
  #	  }
  #	}

  # Path to the oui text file
  config :ouifile, :validate => :path, :required => true
  # The field containing the mac address
  config :source, :validate => :string, :default => 'mac'
  # Target field for manufacture
  config :target, :validate => :string, :default => 'mac_mfr'
  # Tag if lookup failure occurs
  config :tag_on_failure, :validate => :array, :default => ["_ouilookupfailure"]

  public
  def register
    if @ouifile.nil?
      @logger.debug("You must specifiy 'ouifile => path_to_file' in your ieee_oui filter")
      @ouihash = nil
    else
      @logger.info("Using oui file", :path => @ouifile)
      @ouihash = Hash[*File.read(ouifile).split(/\t|\n/)]
    end
  end # def register

  public
  def filter(event)
    matched = false
    if ! @ouihash.nil?
      validhex = false
      mac = event.get(@source)
      delimiter = mac[2]
      if delimiter[/\H/]
         mfrid = mac.split("#{delimiter}")[0..2].join.upcase
      else
        mfrid = mac[0,6].upcase
      end
      if !mfrid[/\H/]
        validhex = true
        vendor = @ouihash[mfrid]
        if vendor
          matched = true
          event.set("#{@target}", vendor)
        end
      end
      # filter_matched should go in the last line of our successful code
      @logger.debug("Invalid Hex in source", :string => @source) if not validhex
      @tag_on_failure.each{|tag| event.tag(tag)} if not matched
    end
    filter_matched(event) if matched
  end # def filter
end # class LogStash::Filters::IeeeOui
