require 'optparse'

module Twibot
  #
  # Twibot configuration. Use either Twibot::CliConfig.new or
  # TwibotFileConfig.new setup a new bot from either command line or file
  # (respectively). Configurations can be chained so they override each other:
  #
  #   config = Twibot::FileConfig.new
  #   config << Twibot::CliConfig.new
  #   config.to_hash
  #
  # The preceding example will create a configuration which is based on a
  # configuration file but have certain values overridden from the command line.
  # This can be used for instance to store everything but the Twitter account
  # password in your configuration file. Then you can just provide the password
  # when running the bot.
  #
  class Config
    attr_reader :settings

    DEFAULT = {
      :host => "twitter.com",
      :min_interval => 30,
      :max_interval => 300,
      :interval_step => 10,
      :log_level => "info",
      :log_file => nil,
      :login => nil,
      :password => nil,
      :process => :new,
      :prompt => false,
      :daemonize => false,
      :include_friends => false,
      :timeline_for => :public
    }

    def initialize(settings = {})
      @configs = []
      @settings = settings
    end

    #
    # Add a configuration object to override given settings
    #
    def add(config)
      @configs << config
      self
    end

    alias_method :<<, :add

    #
    # Makes it possible to access configuration settings as attributes
    #
    def method_missing(name, *args, &block)
      regex = /=$/
      attr_name = name.to_s.sub(regex, '').to_sym
      return super if name == attr_name && !@settings.key?(attr_name)

      if name != attr_name
        @settings[attr_name] = args.first
      end

      @settings[attr_name]
    end

    #
    # Merges configurations and returns a hash with all options
    #
    def to_hash
      hash = {}.merge(@settings)
      @configs.each { |conf| hash.merge!(conf.to_hash) }
      hash
    end

    def self.default
      Config.new({}.merge(DEFAULT))
    end
  end

  #
  # Configuration from command line
  #
  class CliConfig < Config

    def initialize(args = $*)
      super()

      @parser = OptionParser.new do |opts|
        opts.banner += "Usage: #{File.basename(Twibot.app_file)} [options]"

        opts.on("-m", "--min-interval SECS", Integer, "Minimum poll interval in seconds") { |i| @settings[:min_interval] = i }
        opts.on("-x", "--max-interval SECS", Integer, "Maximum poll interval in seconds") { |i| @settings[:max_interval] =  i }
        opts.on("-s", "--interval-step SECS", Integer, "Poll interval step in seconds") { |i| @settings[:interval_step] =  i }
        opts.on("-f", "--log-file FILE", "Log file") { |f| @settings[:log_file] =  f }
        opts.on("-l", "--log-level LEVEL", "Log level (err, warn, info, debug), default id info") { |l| @settings[:log_level] =  l }
        opts.on("-u", "--login LOGIN", "Twitter login") { |l| @settings[:login] =  l }
        opts.on("-p", "--password PASSWORD", "Twitter password") { |p| @settings[:password] =  p }
        opts.on("-h", "--help", "Show this message") { puts opts; exit }

        begin
          require 'daemons'
          opts.on("-d", "--daemonize", "Run as background process (Not implemented)") { |t| @settings[:daemonize] = true }
        rescue LoadError
        end

      end.parse!(args)
    end
  end

  #
  # Configuration from files
  #
  class FileConfig < Config

    #
    # Accepts a stream or a file to read configuration from
    # Default is to read configuration from ./config/bot.yml
    #
    # If a stream is passed it is not closed from within the method
    #
    def initialize(fos = File.expand_path("config/bot.yml"))
      stream = fos.is_a?(String) ? File.open(fos, "r") : fos

      begin
        config = YAML.load(stream.read)
        config.symbolize_keys! if config
      rescue Exception => err
        puts err.message
        puts "Unable to load configuration, aborting"
        exit
      ensure
        stream.close if fos.is_a?(String)
      end

      super config.is_a?(Hash) ? config : {}
    end
  end
end
