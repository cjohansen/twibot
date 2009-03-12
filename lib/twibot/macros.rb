module Twibot
  module Macros
    def self.included(mod)
      @@bot = nil
    end

    def configure(&blk)
      bot.configure(&blk)
    end

    def message(pattern = nil, options = {}, &blk)
      add_handler(:message, pattern, options, &blk)
    end

    def reply(pattern = nil, options = {}, &blk)
      add_handler(:reply, pattern, options, &blk)
    end

    def tweet(pattern = nil, options = {}, &blk)
      add_handler(:tweet, pattern, options, &blk)
    end

    def run?
      !@@bot.nil?
    end

   private
    def add_handler(type, pattern, options, &blk)
      bot.add_handler(type, Twibot::Handler.new(pattern, options, &blk))
    end

    def bot
      return @@bot unless @@bot.nil?

      begin
        @@bot = Twibot::Bot.new
      rescue Exception
        @@bot = Twibot::Bot.new(Twibot::Config.default << Twibot::CliConfig.new)
      end
    end
  end
end
