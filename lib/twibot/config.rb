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
    DEFAULT = {
      :min_interval => 5,
      :max_interval => 300,
      :interval_step => 5,
      :log_level => "info",
      :log_file => nil,
      :login => nil,
      :password => nil
    }

    def initialize
      @configs = []
      @settings = {}.merge(Config::DEFAULT)
    end

    def add(config)
      @configs << config
      self
    end

    alias_method :<<, :add

    def method_missing(name, *args, &block)
      return super unless @settings.key?(name)
      @settings[name] = args.first
    end

    def to_hash
      hash = {}.merge(@settings)
      @configs.each { |conf| hash.merge!(conf.to_hash) }
      hash
    end
  end

  #
  # Configuration from command line
  #
  class CliConfig < Config

    def initialize
      super

      @parser = OptionParser.new do |opts|
        opts.banner += "Usage: #{File.basename(Twibot.app_file)} [options]"

        opts.on("-m", "--min-interval SECS", Integer, "Minimum poll interval in seconds") { |i| min_interval i }
        opts.on("-x", "--max-interval SECS", Integer, "Maximum poll interval in seconds") { |i| max_interval i }
        opts.on("-s", "--interval-step SECS", Integer, "Poll interval step in seconds") { |i| interval_step i }
        opts.on("-f", "--log-file FILE", "Log file") { |f| log_file f }
        opts.on("-l", "--log-level LEVEL", "Log level (err, warn, info, debug), default id info") { |l| log_level l }
        opts.on("-u", "--login LOGIN", "Twitter login") { |l| login l }
        opts.on("-p", "--password PASSWORD", "Twitter password") { |p| password p }
        opts.on("-h", "--help", "Show this message") { puts opts; exit }
      end
    end

    def to_hash
      @parser.parse!
      super
    end
  end

  #
  # Configuration from files
  #
  class FileConfig < Config

    def initialize
      super

      begin
        config = YAML.load(File.read(File.expand_path("config/bot.yml")))
      rescue Exception => err
        puts err.message
        puts "Unable to load configuration, aborting"
        exit
      end

      @settings.merge!(config.symbolize_keys!)
    end
  end
end
