gem 'twitter4r'
require 'twitter'
require 'twitter/console'
require 'yaml'
require 'logger'

module Twibot
  #
  # Main bot "controller" class
  #
  class Bot
    def initialize(options = nil)
      @config = (options || Twibot::FileConfig.new << Twibot::CliConfig.new).to_hash
      @twitter = Twitter::Client.new :login => @config[:login], :password => @config[:password]
    rescue Exception => krash
      puts krash.message
      exit
    end

    #
    # Run application
    #
    def run!
      puts "Twibot #{Twibot::VERSION} imposing as @#{login}"

      trap(:INT) do
        puts "\nAnd it's a wrap. See ya soon!"
        exit
      end

      poll
    end

    #
    # Poll Twitter API in a loop and pass on messages and tweets when they appear
    #
    def poll
      interval = min_interval
      max = max_interval
      step = interval_step

      loop do
        # TODO: Poll twitter service
        log.debug "Sleeping for #{interval}s"
        sleep interval
        interval = interval + step < max ? interval + step : max
      end
    end

   private
    def method_missing(name, *args, &block)
      return super unless @config.key?(name)
      self.class.send(:define_method, name) { @config[name] }
      @config[name]
    end

    def log
      return @log if @log
      os = @config[:log_file] ? File.open(@config[:log_file], "r") : $stdio
      @log = Logger.new(os)
      @log.level = Logger.const_get(@config[:log_level] ? @config[:log_level].upcase : "INFO")
      @log
    end
  end
end
