require 'logger'
require File.join(File.expand_path(File.dirname(__FILE__)), 'macros')
require File.join(File.expand_path(File.dirname(__FILE__)), 'handlers')

module Twibot
  #
  # Main bot "controller" class
  #
  class Bot
    include Twibot::Handlers
    attr_reader :twitter
    attr_writer :prompt

    def initialize(options = nil, prompt = false)
      @prompt = prompt
      @conf = nil
      @config = options || Twibot::Config.default << Twibot::FileConfig.new << Twibot::CliConfig.new
      @log = nil
      @abort = false
    rescue Exception => krash
      raise SystemExit.new(krash.message)
    end

    def prompt?
      @prompt
    end

    def processed
      @processed ||= {
        :message => nil,
        :reply => nil,
        :tweet => nil,
        :search => {}
      }
    end

    def twitter
      @twitter ||= Twitter::Client.new(:login => config[:login],
                                       :password => config[:password],
                                       :host => config[:host])
    end

    #
    # Run application
    #
    def run!
      puts "Twibot #{Twibot::VERSION} imposing as @#{login} on #{config[:host]}"

      trap(:INT) do
        puts "\nAnd it's a wrap. See ya soon!"
        exit
      end

      case config[:process]
      when :all, nil
        # do nothing so it will fetch ALL
      when :new
        # Make sure we don't process messages and tweets received prior to bot launch
        messages = twitter.messages(:received, { :count => 1 })
        processed[:message] = messages.first.id if messages.length > 0

        handle_tweets = !handlers.nil? && handlers_for_type(:tweet).length + handlers_for_type(:reply).length + handlers_for_type(:search).keys.length > 0
        # handle_tweets ||= handlers_for_type(:search).keys.length > 0
        tweets = []

        sandbox do
          tweets = handle_tweets ? twitter.timeline_for(config[:timeline_for], { :count => 1 }) : []
        end

        processed[:tweet] = tweets.first.id if tweets.length > 0
        processed[:reply] = tweets.first.id if tweets.length > 0

        # for searches, use latest tweet on public timeline
        #
        if handle_tweets && config[:timeline_for].to_s != "public"
          sandbox { tweets = twitter.timeline_for(:public, { :count => 1 }) }
        end
        if tweets.length > 0
          handlers_for_type(:search).each_key {|q| processed[:search][q] = tweets.first.id }
        end

        load_followers

      when Numeric, /\d+/ # a tweet ID to start from
        processed[:tweet] = processed[:reply] = processed[:message] = config[:process]
        handlers[:search].each_key {|q| processed[:search][q] = config[:process] }
      else abort "Unknown process option #{config[:process]}, aborting..."
      end

      load_friends unless handlers_for_type(:follower).empty?

      poll
    end

    #
    # Poll Twitter API in a loop and pass on messages and tweets when they appear
    #
    def poll
      max = max_interval
      step = interval_step
      interval = min_interval

      while !@abort do
        run_hook :before_all
        message_count = 0
        message_count += receive_messages || 0
        message_count += receive_replies || 0
        message_count += receive_tweets || 0
        message_count += receive_searches || 0

        receive_followers

        run_hook :after_all, message_count

        interval = message_count > 0 ? min_interval : [interval + step, max].min

        log.debug "#{config[:host]} sleeping for #{interval}s"
        sleep interval
      end
    end


    def friend_ids
      @friend_ids ||= {}
    end

    def add_friend!(user_or_id, only_local=false)
      id = id_for_user_or_id(user_or_id)
      sandbox(0) { twitter.friend(:add, id) } unless only_local
      friend_ids[id] = true
    end

    def remove_friend!(user_or_id, only_local=false)
      id = id_for_user_or_id(user_or_id)
      sandbox(0) { twitter.friend(:remove, id) } unless only_local
      friend_ids[id] = false
    end

    def is_friend?(user_or_id)
      !!friend_ids[id_for_user_or_id(user_or_id)]
    end

    def follower_ids
      @follower_ids ||= {}
    end

    def add_follower!(user_or_id)
      follower_ids[id_for_user_or_id(user_or_id)] = true
    end

    def remove_follower!(user_or_id)
      follower_ids[id_for_user_or_id(user_or_id)] = false
    end

    def is_follower?(user_or_id)
      !!follower_ids[id_for_user_or_id(user_or_id)]
    end

    def id_for_user_or_id(user_or_id)
      (user_or_id.respond_to?(:screen_name) ? user_or_id.id : user_or_id).to_i
    end


    #
    # retrieve a list of friend ids and store it as a Hash
    #
    def load_friends
      sandbox(0) do
        twitter.graph(:friends, config[:login]).each {|id| add_friend!(id, true) }
      end
    end

    #
    # retrieve a list of friend ids and store it as a Hash
    #
    def load_followers
      sandbox(0) do
        twitter.graph(:followers, config[:login]).each {|id| add_follower!(id) }
      end
    end


    #
    # returns a Hash of all registered hooks
    #
    def hooks
      @hooks ||= {}
    end

    #
    # registers a block to be called at the given +event+
    #
    def add_hook(event, &blk)
      hooks[event.to_sym] = blk
    end

    #
    # calls the hook method for the +event+ if one has
    # been defined
    #
    def run_hook(event, *args)
      hooks[event.to_sym].call(*args) if hooks[event.to_sym].respond_to? :call
    end

    #
    # Receive direct messages
    #
    def receive_messages
      type = :message
      return false unless handlers_for_type(type).length > 0
      options = {}
      options[:since_id] = processed[type] if processed[type]

      sandbox(0) do
        dispatch_messages(type, twitter.messages(:received, options), %w{message messages})
      end
    end

    #
    # Receive tweets
    #
    def receive_tweets
      type = :tweet
      return false unless handlers_for_type(type).length > 0
      options = {}
      options[:since_id] = processed[type] if processed[type]

      sandbox(0) do
        dispatch_messages(type, twitter.timeline_for(config.to_hash[:timeline_for] || :public, options), %w{tweet tweets})
      end
    end

    #
    # Receive tweets that start with @<login>
    #
    def receive_replies
      type = :reply
      return false unless handlers_for_type(type).length > 0
      options = {}
      options[:since_id] = processed[type] if processed[type]

      sandbox(0) do
        dispatch_messages(type, twitter.status(:replies, options), %w{reply replies})
      end
    end

    #
    # Receive tweets that match the query parameters
    #
    def receive_searches
      result_count = 0

      handlers_for_type(:search).each_pair do |query, search_handlers|
        options = { :q => query, :rpp => 100 }
        [:lang, :geocode].each do |param|
          options[param] = search_handlers.first.options[param] if search_handlers.first.options[param]
        end
        options[:since_id] = processed[:search][query] if processed[:search][query]

        result_count += sandbox(0) do
          dispatch_messages([:search, query], twitter.search(options.merge(options)), %w{tweet tweets}.map {|l| "#{l} for \"#{query}\""})
        end
      end

      result_count
    end

    #
    # Receive any new followers
    #
    def receive_followers
      newbies = []
      sandbox(0) do
        twitter.graph(:followers, config[:login]).each {|id| newbies << id unless is_friend?(id) or is_follower?(id) }
        newbies.each do |id|
          add_follower!(id)
          with_hooks(:follower) { handlers_for_type(:follower).each {|h| h.handle(id, {}) } }
        end
      end
      log.info "#{config[:host]}: Received #{newbies.size} new #{newbies.size == 1 ? 'follower' : 'followers'}"
    end

    #
    # Dispatch a collection of messages
    #
    def dispatch_messages(type, messages, labels)
      messages.each {|message| with_hooks(type) { dispatch(type, message) } }
      # Avoid picking up messages over again
      if type.is_a? Array            # [TODO] (mikedemers) this is an ugly hack
        processed[type.first][type.last] = messages.first.id if messages.length > 0
      else
        processed[type] = messages.first.id if messages.length > 0
      end

      num = messages.length
      log.info "#{config[:host]}: Received #{num} #{num == 1 ? labels[0] : labels[1]}"
      num
    end

    #
    # invokes the given block, running the before and
    # after hooks for the given type
    #
    def with_hooks(type, &blk)
      event = type.is_a?(Array) ? type.first : type
      run_hook :"before_#{event}"
      value = yield
      run_hook :"after_#{event}"
      value
    end

    #
    # Return logger instance
    #
    def log
      return @log if @log
      os = config[:log_file] ? File.open(config[:log_file], "a") : $stdout
      os.sync = !!config[:log_flush]
      @log = Logger.new(os)
      @log.level = Logger.const_get(config[:log_level] ? config[:log_level].upcase : "INFO")
      @log
    end

    #
    # Configure bot
    #
    def configure
      yield @config
      @conf = nil
      @twitter = nil
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
      return @conf if @conf
      @conf = @config.to_hash

      if prompt? && (!@conf[:login] || !@conf[:password])
        # No need to rescue LoadError - if the gem is missing then config will
        # be incomplete, something which will be detected elsewhere
        begin
          require 'highline'
          hl = HighLine.new

          @config.login = hl.ask("Twitter login: ") unless @conf[:login]
          @config.password = hl.ask("Twitter password: ") { |q| q.echo = '*' } unless @conf[:password]
          @conf = @config.to_hash
        rescue LoadError
          raise SystemExit.new( <<-HELP
Unable to continue without login and password. Do one of the following:
  1) Install the HighLine gem (gem install highline) to be prompted for credentials
  2) Create a config/bot.yml with login: and password:
  3) Put a configure { |conf| conf.login = "..." } block in your bot application
  4) Run bot with --login and --password options
          HELP
          )
        end
      end

      @conf
    end

    #
    # Takes a block and executes it in a sandboxed network environment. It
    # catches and logs most common network connectivity and timeout errors.
    #
    # The method takes an optional parameter. If set, this value will be
    # returned in case an error was raised.
    #
    def sandbox(return_value = nil)
      begin
        return_value = yield
      rescue Twitter::RESTError => e
        log.error("Failed to connect to Twitter. It's likely down for a bit:")
        log.error(e.to_s)
      rescue Errno::ECONNRESET => e
        log.error("Connection was reset")
        log.error(e.to_s)
      rescue Timeout::Error => e
        log.error("Timeout")
        log.error(e.to_s)
      rescue EOFError => e
        log.error(e.to_s)
      rescue Errno::ETIMEDOUT => e
        log.error("Timeout")
        log.error(e.to_s)
      rescue JSON::ParserError => e
        log.error("JSON Parsing error")
        log.error(e.to_s)
      rescue OpenSSL::SSL::SSLError => e
        log.error("SSL error")
        log.error(e.to_s)
      rescue SystemStackError => e
        log.error(e.to_s)
      end

      return return_value
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
