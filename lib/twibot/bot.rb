gem 'twitter4r'
require 'twitter'
require 'twitter/console'
require 'yaml'
require 'logger'
require File.join(File.dirname(__FILE__), 'macros')

module Twibot
  #
  # Main bot "controller" class
  #
  class Bot
    def initialize(options = nil)
      @config = options || Twibot::Config.default << Twibot::FileConfig.new << Twibot::CliConfig.new
      @twitter = Twitter::Client.new :login => config[:login], :password => config[:password]
      @log = nil
    rescue Exception => krash
      raise SystemExit.new krash.message
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

    #
    # Return logger instance
    #
    def log
      return @log if @log
      os = config[:log_file] ? File.open(config[:log_file], "r") : $stdout
      @log = Logger.new(os)
      @log.level = Logger.const_get(config[:log_level] ? config[:log_level].upcase : "INFO")
      @log
    end

    #
    # Configure bot
    #
    def configure
      yield @config
    end

   private
    #
    # Map configuration settings
    #
    def method_missing(name, *args, &block)
      return super unless config.key?(name)
      self.class.send(:define_method, name) { config[name] }
      config[name]
    end

    #
    # Return configuration
    #
    def config
      @config.to_hash
    end
  end
end

# Expose DSL
include Twibot::Macros

# Run bot if macros has been used
at_exit do
  raise $! if $!
  @@bot.run! if run?
end
