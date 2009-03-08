module Twibot
  module Handlers
    #
    # Sets up handler arrays
    #
    def includled
      @handlers = {
        :message => [],
        :reply => [],
        :tweet => []
      }
    end

    #
    # Add a handler for this bot
    #
    def add_handler(type, handler)
      @handlers[type] << handler
    end

    def dispatch(type, message)
      @handlers[type].each { |handler| handler.dispatch(message) }
    end
  end

  #
  # A Handler object is an object which can handle a direct message, tweet or
  # at reply.
  #
  class Handler
    def initialize(pattern = nil, options = {}, &blk)
      @options = options
      @handler = block_given? ? &blk : nil
      @params = {}
      self.pattern = pattern
    end

    #
    # Parse pattern string and set options
    #
    def pattern=(pattern)
      return if pattern.nil? || pattern == ""

      words = pattern.split.collect { |s| s.strip }         # Get all words in pattern
      @options[:tokens] = words.inject([]) do |token, sum|  # Find all tokens, ie :symbol :like :names
        break sum unless token =~ /^:.*/                    # Don't process regular words
        pattern.sub!(/\b#{token}\b/, '([^\s])')             # Make sure regex captures named switch
        sum << token.sub(":", "").to_sym
      end

      @options[:pattern] = pattern
    end

    def recognize?(message)
      return false if @options[:pattern] && message !~ @options[:pattern] # Pattern check

      users = @options[:from] ? @options[:from] : nil
      users = [users] if users.is_a?(String)
      return false if users && users.include?(mesage.from)                # Check allowed senders

      matches = message.match(@options[:pattern])
      @options[:tokens].each_with_index { |token, i| @params[token] = matches[i] }
    end

    def dispatch(message)
      @params = {}
      handle(message) if recognize?(message)
    end

    def handle(message)
      @handler.call(message) if @handler
    end
  end
end
