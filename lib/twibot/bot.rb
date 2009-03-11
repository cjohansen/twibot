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
        interval = min_interval - step if receive_messages
        interval = min_interval - step if receive_replies
        interval = min_interval - step if receive_tweets

        log.debug "Sleeping for #{interval}s"
        sleep interval
        interval = interval + step < max ? interval + step : max
      end
    end

    #
    # Receive direct messages
    #
    def receive_messages
      type = :message
      return false unless handlers[type].length > 0

      options = { :since_id => @processed[type] } if @processed[type]
      dispatch_messages(type, @twitter.messages(:received, options), %w{message messages})
    end

    #
    # Receive tweets
    #
    def receive_tweets
      type = :tweet
      return false unless handlers[type].length > 0

      options = { :id => @processed[type] } if @processed[type]
      dispatch_messages(type, @twitter.timeline_for(:me, options), %w{tweet tweets})
    end

    #
    # Receive tweets that start with @<login>
    #
    def receive_replies
      type = :reply
      return false unless handlers[type].length > 0

      options = { :id => @processed[type] } if @processed[type]
      messages = @twitter.timeline_for(:me, options)

      # Pick only messages that start with our name
      num = dispatch_messages(type, messages.find_all { |t| t.text =~ /^@#{@twitter.send :login}/ }, %w{reply replies})

      # Avoid picking up messages over again
      @processed[type] = messages.last.id if messages.length > 0

      num
    end

    #
    # Dispatch a collection of messages
    #
    def dispatch_messages(type, messages, labels)
      messages.each do |message|
        dispatch(type, message)
        @processed[type] = message.id
      end

      num = messages.length
      log.info "Received #{num} #{num == 1 ? labels[0] : labels[1]}"
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
