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
      @handler = nil
      @handler = block_given? ? blk : nil
      self.pattern = pattern
    end

    #
    # Parse pattern string and set options
    #
    def pattern=(pattern)
      return if pattern.nil? || pattern == ""

      words = pattern.split.collect { |s| s.strip }          # Get all words in pattern
      @options[:tokens] = words.inject([]) do |sum, token|   # Find all tokens, ie :symbol :like :names
        next sum unless token =~ /^:.*/                      # Don't process regular words
        sym = token.sub(":", "").to_sym                      # Turn token string into symbol, ie ":token" => :token
        regex = @options[sym] || '[^\s]+'                    # Fetch regex if configured, else use any character but space matching
        pattern.sub!(/(^|\s)#{token}(\s|$)/, '\1(' + regex.to_s + ')\2') # Make sure regex captures named switch
        sum << sym
      end

      @options[:pattern] = /#{pattern}(\s.+)?/
    end

    #
    # Determines if this handler is suited to handle an incoming message
    #
    def recognize?(message)
      return false if @options[:pattern] && message.text !~ @options[:pattern] # Pattern check

      users = @options[:from] ? @options[:from] : nil
      users = [users] if users.is_a?(String)
      return false if users && !users.include?(message.sender) # Check allowed senders
      true
    end

    #
    # Process message to build params hash and pass message along with params of
    # to +handle+
    #
    def dispatch(message)
      @params = {}

      matches = message.match(@options[:pattern])
      @options[:tokens].each_with_index { |token, i| @params[token] = matches[i+1] }
      @params[:text] = (matches[tokens.length+1] || "").strip

      handle(message, @params) if recognize?(message)
    end

    #
    # Handle a message. Calls the internal Proc with the message and the params
    # hash as parameters.
    #
    def handle(message, params)
      @handler.call(message, params) if @handler
    end
  end
end
