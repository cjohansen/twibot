module Twibot
  #
  # Main bot "controller" class
  #
  class Bot
    #
    # Run application
    #
    def self.run!
      bot = Twibot::Bot.new
      puts "Twibot clearing throat... Ready to tweet at your command!"
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
