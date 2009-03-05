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
    attr_reader :login

    def initialize
      @log = Logger.new $stdout
      conf = { :bot => {} }.merge(config)

      @config = {
        :min_interval => 5,
        :max_interval => 300,
        :interval_step => 5
      }.merge(conf[:bot])

      @twitter = Twitter::Client.new(conf[:twitter])
      @login = conf[:twitter][:login]
    end

    #
    # Get configuration hash
    #
    def config
      return @config if @config

      begin
        config = YAML.load(File.read(File.expand_path("config/bot.yml")))
      rescue Exception => err
        puts err.message
        puts "Unable to load configuration, aborting"
        exit
      end

      config.symbolize_keys!
    end

    #
    # Run bot
    #
    def run
      min_interval = interval = @config[:min_interval]
      max_interval = @config[:max_interval]
      step = @config[:interval_step]

      loop do
        # TODO: Poll twitter service
        sleep interval
        interval = interval + step < max_interval ? interval + step : max_interval
      end
    end

    #
    # Run application
    #
    def self.run!
      bot = Twibot::Bot.new
      puts "Twibot assuming the role of @#{bot.login}"

      trap(:INT) do
        puts "\nAnd it's a wrap. See ya soon!"
        exit
      end

      bot.run
    end
  end
end

#
# Sinatra inspired code to fire off application
#
at_exit do
  raise $! if $!
  Twibot::Bot.run! if Twibot.run?
end
