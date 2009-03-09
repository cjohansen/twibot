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
      if pattern.is_a?(Hash)
        options = pattern
        pattern = nil
      end

      bot.add_handler(type, Twibot::Handler.new(pattern, options, &blk))
    end

    def bot
      @@bot ||= Twibot::Bot.new
    end
  end
end
