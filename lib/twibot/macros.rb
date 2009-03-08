module Twibot
  module Macros
    def self.included(mod)
      @@bot = nil
    end

    def configure(&blk)
      bot.configure(&blk)
    end

    def message(pattern = nil, options = {}, &blk)
      bot.add_handler(:message, Twibot::Handler.new(pattern, options, &blk))
    end

    def reply(pattern = nil, options = {}, &blk)
      bot.add_handler(:reply, Twibot::Handler.new(pattern, options, &blk))
    end

    def tweet(pattern = nil, options = {}, &blk)
      bot.add_handler(:tweet, Twibot::Handler.new(pattern, options, &blk))
    end

    def run?
      !@@bot.nil?
    end

   private
    def bot
      @@bot ||= Twibot::Bot.new
    end
  end
end
