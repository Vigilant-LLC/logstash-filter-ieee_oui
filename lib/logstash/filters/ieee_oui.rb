# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require 'digest'

java_import 'java.util.concurrent.locks.ReentrantReadWriteLock'

# The ieee_oui filter allows you to match mac addresses to vendor names.
# It accepts source mac addresses delimited by a colon(:), a dash(-) or no delimiter.
# The filter requires a specially formatted oui-logstash.txt file for the ouifile.
# See https://github.com/figure-of-late/logstash-oui-scraper
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
  # Indicates how frequently (in seconds) to check the oui text file for updates
  config :refresh_interval, :validate => :number, :default => 300
  # Tag if lookup failure occurs
  config :tag_on_failure, :validate => :array, :default => ["_ouilookupfailure"]

  public
  def register
    rw_lock = java.util.concurrent.locks.ReentrantReadWriteLock.new
    @read_lock = rw_lock.readLock
    @write_lock = rw_lock.writeLock

    if @ouifile.nil?
      @ouihash = nil
      raise LogStash::ConfigurationError, I18n.t(
        "logstash.agent.configuration.invalid_plugin_register",
        :plugin => "filter",
        :type => "ieee_oui",
        :error => "You must specifiy 'ouifile => path_to_file' in your ieee_oui filter"
      )
    else
      @logger.info("Using OUI file", :path => @ouifile)
      @logger.info("OUI file refresh check seconds", :number => @refresh_interval)
      @md5 = nil
      @newmd5 = nil
      @ouihash = nil
      @next_refresh = Time.now + @refresh_interval
      lock_for_write { refreshfile(@ouifile) }
    end
  end # def register

  private
  def lock_for_write
    @write_lock.lock
    begin
      yield
    ensure
      @write_lock.unlock
    end
  end # def lock_for_write

  private
  def lock_for_read # ensuring only one thread updates the OUI hash
    @read_lock.lock
    begin
      yield
    ensure
      @read_lock.unlock
    end
  end #def lock_for_read

  private
  def md5file(file)
    return Digest::MD5.file(file).hexdigest
  end

  private
  def hashfile(file)
    return Hash[*File.read(file).split(/\t|\n/)]
  end

  private
  def refreshfile(file)
    @newmd5 = md5file(file)
    if @newmd5 != @md5
      @md5 = md5file(file)
      @ouihash = hashfile(file)
      @next_refresh = Time.now + @refresh_interval
      @logger.info("Refreshing OUI file", :path => file)
    else
      @logger.debug("OUI file unchanged", :path => file)
    end
    @logger.debug("OUI file MD5", :string => @md5)
  end

  private
  def needs_refresh?
    @next_refresh < Time.now
  end

  public
  def filter(event)
    matched = false

    if ! @ouihash.nil?
      if needs_refresh?
        lock_for_write do
          if needs_refresh?
            refreshfile(@ouifile)
          end
        end
      end

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
        vendor = nil
        lock_for_read do
          vendor = @ouihash[mfrid]
        end
        if vendor.nil?
          vendor = 'unknown'
        else
          vendor = vendor.gsub(/\r/,"")
        end
        matched = true
        event.set("#{@target}", vendor)
      end
    end

    @logger.debug("Invalid MAC address in source", :string => @source) if not validhex
    @tag_on_failure.each{|tag| event.tag(tag)} if not matched
    filter_matched(event) if matched
  end # def filter

end # class LogStash::Filters::IeeeOui
