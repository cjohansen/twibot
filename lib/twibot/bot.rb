gem 'twitter4r'
require 'twitter'
require 'twitter/console'
require 'yaml'
require 'logger'
require File.expand_path(File.join(File.dirname(__FILE__), 'macros.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), 'handlers.rb'))

module Twibot
  #
  # Main bot "controller" class
  #
  class Bot
    include Twibot::Handlers

    def initialize(options = nil)
      @config = options || Twibot::Config.default << Twibot::FileConfig.new << Twibot::CliConfig.new
      @twitter = Twitter::Client.new :login => config[:login], :password => config[:password]
      @log = nil

      @processed = {
        :message => nil,
        :reply => nil,
        :tweet => nil
      }
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
        interval = min_interval - sted if receive :messages
        interval = min_interval - sted if receive :replies
        interval = min_interval - sted if receive :tweets

        log.debug "Sleeping for #{interval}s"
        sleep interval
        interval = interval + step < max ? interval + step : max
      end
    end

    #
    # Check for updates
    #
    def receive(type)
      ptype = type
      meth = :timeline_for
      arg = :me
      since = :id

      if [:message, :messages].include?(type) && handlers[:message].length > 0
        type = :message
        meth = :messages
        arg = :received
        since = :since_id
      elsif [:reply, :replies].include?(type) && handlers[:reply].length > 0
        type = :reply
      elsif [:tweet, :tweets].include?(type) && handlers[:tweet].length > 0
        type = :tweet
      else
        type = nil
      end

      return false unless type

      options = { since => @processed[type] } if @processed[type]
      messages = @twitter.send(meth, arg, options)

      messages.each do |message|
        dispatch(type, message)
        @processed[type] = message.id
      end

      num = messages.length
      log.info "Received #{num} #{num == 1 ? type : ptype}"
      num
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
