module Twibot
  module Handlers
    #
    # Add a handler for this bot
    #
    def add_handler(type, handler)
      handlers[type] << handler
      handler
    end

    def dispatch(type, message)
      handlers[type].each { |handler| handler.dispatch(message) }
    end

    def handlers
      @handlers ||= {
        :message => [],
        :reply => [],
        :tweet => []
      }
    end

    def handlers=(hash)
      @handlers = hash
    end
  end

  #
  # A Handler object is an object which can handle a direct message, tweet or
  # at reply.
  #
  class Handler
    def initialize(pattern = nil, options = {}, &blk)
      if pattern.is_a?(Hash)
        options = pattern
        pattern = nil
      end

      @options = options
      @options[:from].collect! { |s| s.to_s } if @options[:from] && @options[:from].is_a?(Array)
      @options[:from] = [@options[:from].to_s] if @options[:from] && @options[:from].is_a?(String)
      @handler = nil
      @handler = block_given? ? blk : nil
      self.pattern = pattern
    end

    #
    # Parse pattern string and set options
    #
    def pattern=(pattern)
      return if pattern.nil? || pattern == ""

      if pattern.is_a?(Regexp)
        @options[:pattern] = pattern
        return
      end

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
      sender = message.respond_to?(:sender) ? message.sender : message.user
      return false if users && !users.include?(sender.screen_name.downcase) # Check allowed senders
      true
    end

    #
    # Process message to build params hash and pass message along with params of
    # to +handle+
    #
    def dispatch(message)
      return unless recognize?(message)
      @params = {}

      if @options[:pattern] && @options[:tokens]
        matches = message.text.match(@options[:pattern])
        @options[:tokens].each_with_index { |token, i| @params[token] = matches[i+1] }
        @params[:text] = (matches[@options[:tokens].length+1] || "").strip
      elsif @options[:pattern] && !@options[:tokens]
        @params = message.text.match(@options[:pattern]).to_a[1..-1] || []
      else
        @params[:text] = message.text
      end

      handle(message, @params)
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
