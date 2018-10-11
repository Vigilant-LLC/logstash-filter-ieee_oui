# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This  filter will replace the contents of the default
# message field with whatever you specify in the configuration.
#
# It is only intended to be used as an .
class LogStash::Filters::IeeeOui < LogStash::Filters::Base

  # Setting the config_name here is required. This is how you
  # configure this filter from your Logstash config.
  #
  # filter {
  #    {
  #     message => "My message..."
  #   }
  # }
  #
  config_name "ieee_oui"

  # Path to the oui text file
  config :ouifile, :validate => :path, :required => true
  # The field containing the mac address
  config :source, :validate => :string, :default => 'mac'
  # Target field for manufacture
  config :target, :validate => :string, :default => 'mac_mfr'
  # Cache size
  config :cache_size, :validate => :number, :default => 1000
  # Tag if lookup failure occurs
  config :tag_on_failure, :validate => :array, :default => ["_ouilookupfailure"]

  public
  def register
    if @ouifile.nil?
      @logger.debug("You must specifiy 'ouifile => path_to_file' in your ieee_oui filter")
    end
    @logger.info("Using oui file", :path => @ouifile)
  end # def register

  public
  def filter(event)
    mac = event.get(@source) 
    if mac =~ /:/
      mfrid = mac.split(':')[0..2].join.upcase
    elsif mac =~ /-/
      mfrid = mac.split('-')[0..2].join.upcase
    else
      mfrid = mac[0,6].upcase
    end
    if !mfrid[/\H/]
      File.foreach(ouifile) do |x|
        if x =~ /^#{mfrid}/
          vendor = x.split("\t")[1].strip
          if vendor
            event.set("#{@target}", vendor)
          end
        else
          event.tag(@tag_on_failure)
        end
      end
    else
      @logger.debug("Invalid Hex in source", :string => @source)
      event.tag(@tag_on_failure)
    end
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::IeeeOui
