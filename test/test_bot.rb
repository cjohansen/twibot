require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper')) unless defined?(Twibot)
require 'fileutils'

class TestBot < Test::Unit::TestCase
  should "not raise errors when initialized" do
    assert_nothing_raised do
      Twibot::Bot.new Twibot::Config.new
    end
  end

  should "raise errors when initialized without config file" do
    assert_raise SystemExit do
      Twibot::Bot.new
    end
  end

  should "not raise error on initialize when config file exists" do
    if File.exists?("config")
      FileUtils.rm("config/bot.yml")
    else
      FileUtils.mkdir("config")
    end

    File.open("config/bot.yml", "w") { |f| f.puts "" }

    assert_nothing_raised do
      Twibot::Bot.new
    end

    FileUtils.rm_rf("config")
  end

  should "provide configuration settings as methods" do
    bot = Twibot::Bot.new Twibot::Config.new(:max_interval => 3)
    assert_equal 3, bot.max_interval
  end

  should "return logger instance" do
    bot = Twibot::Bot.new(Twibot::Config.default << Twibot::Config.new)
    assert bot.log.is_a?(Logger)
  end

  should "respect configured log level" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "info"))
    assert_equal Logger::INFO, bot.log.level

    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "warn"))
    assert_equal Logger::WARN, bot.log.level
  end

  should "should return false from receive without handlers" do
    bot = Twibot::Bot.new(Twibot::Config.new)
    assert !bot.receive_messages
    assert !bot.receive_replies
    assert !bot.receive_tweets
  end

  context "with the process option specified" do
    setup do
      @bot = Twibot::Bot.new(@config = Twibot::Config.default)
      @bot.stubs(:prompt?).returns(false)
      @bot.stubs(:twitter).returns(stub)
      @bot.stubs(:processed).returns(stub)

      # stop Bot actually starting during tests
      @bot.stubs(:poll)
    end

    should "not process tweets prior to bot launch if :process option is set to :new" do
      @bot.stubs(:handlers).returns({:tweet => [stub], :reply => []})

      # Should fetch the latest ID for both messages and tweets
      @bot.twitter.expects(:messages).with(:received, { :count => 1 }).
        returns([stub(:id => (message_id = stub))]).once
      @bot.twitter.expects(:timeline_for).with(:public, { :count => 1 }).
        returns([stub(:id => (tweet_id = stub))]).once

      # And set them to the since_id value to be used for future polling
      @bot.processed.expects(:[]=).with(:message, message_id)
      @bot.processed.expects(:[]=).with(:tweet,   tweet_id)
      @bot.processed.expects(:[]=).with(:reply,   tweet_id)

      @bot.configure { |c| c.process = :new }
      @bot.run!
    end

    [:all, nil].each do |value|
      should "process all tweets if :process option is set to #{value.inspect}" do
        @bot.twitter.expects(:messages).never
        @bot.twitter.expects(:timeline_for).never

        # Shout not set the any value for the since_id tweets
        @bot.processed.expects(:[]=).never

        @bot.configure { |c| c.process = value }
        @bot.run!
      end
    end

    should "process all tweets after the ID specified in the :process option" do
      tweet_id = 12345

      @bot.processed.expects(:[]=).with(anything, 12345).times(3)

      @bot.configure { |c| c.process = tweet_id }
      @bot.run!
    end

    should "raise exit when the :process option is not recognized" do
      @bot.configure { |c| c.process = "something random" }
      assert_raise(SystemExit) { @bot.run! }
    end

  end

  should "receive message" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error"))
    bot.add_handler(:message, Twibot::Handler.new)
    bot.twitter.expects(:messages).with(:received, {}).returns([twitter_message("cjno", "Hei der!")])

    assert bot.receive_messages
  end

  should "remember last received message" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error"))
    bot.add_handler(:message, Twibot::Handler.new)
    bot.twitter.expects(:messages).with(:received, {}).returns([twitter_message("cjno", "Hei der!")])
    assert_equal 1, bot.receive_messages

    bot.twitter.expects(:messages).with(:received, { :since_id => 1 }).returns([])
    assert_equal 0, bot.receive_messages
  end

  should "receive tweet" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error"))
    bot.add_handler(:tweet, Twibot::Handler.new)
    bot.twitter.expects(:timeline_for).with(:public, {}).returns([tweet("cjno", "Hei der!")])

    assert_equal 1, bot.receive_tweets
  end

  should "receive friend tweets if configured" do
    bot = Twibot::Bot.new(Twibot::Config.new({:log_level => "error", :timeline_for => :friends}))
    bot.add_handler(:tweet, Twibot::Handler.new)
    bot.twitter.expects(:timeline_for).with(:friends, {}).returns([tweet("cjno", "Hei der!")])

    assert_equal 1, bot.receive_tweets
  end

  should "remember received tweets" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error"))
    bot.add_handler(:tweet, Twibot::Handler.new)
    bot.twitter.expects(:timeline_for).with(:public, {}).returns([tweet("cjno", "Hei der!")])
    assert_equal 1, bot.receive_tweets

    bot.twitter.expects(:timeline_for).with(:public, { :since_id => 1 }).returns([])
    assert_equal 0, bot.receive_tweets
  end

  should "receive reply when tweet starts with login" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error", :login => "irbno"))
    bot.add_handler(:reply, Twibot::Handler.new)
    bot.twitter.expects(:status).with(:replies, {}).returns([tweet("cjno", "@irbno Hei der!")])

    assert_equal 1, bot.receive_replies
  end

  should "remember received replies" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error", :login => "irbno"))
    bot.add_handler(:reply, Twibot::Handler.new)
    bot.twitter.expects(:status).with(:replies, {}).returns([tweet("cjno", "@irbno Hei der!")])
    assert_equal 1, bot.receive_replies

    bot.twitter.expects(:status).with(:replies, { :since_id => 1 }).returns([])
    assert_equal 0, bot.receive_replies
  end

  should "use public as default timeline method for tweet 'verb'" do
    bot = Twibot::Bot.new(Twibot::Config.default)
    assert_equal :public, bot.instance_eval { @config.to_hash[:timeline_for] }
  end
end

class TestBotMacros < Test::Unit::TestCase
  should "provide configure macro" do
    assert respond_to?(:configure)
  end

  should "yield configuration" do
    Twibot::Macros.bot = Twibot::Bot.new Twibot::Config.default
    bot.prompt = false

    conf = nil
    assert_nothing_raised { configure { |c| conf = c } }
    assert conf.is_a?(Twibot::Config)
  end

   should "add handler" do
     Twibot::Macros.bot = Twibot::Bot.new Twibot::Config.default
     bot.prompt = false

     handler = add_handler(:message, ":command", :from => :cjno)
     assert handler.is_a?(Twibot::Handler), handler.class
   end

  should "provide twitter macro" do
    assert respond_to?(:twitter)
    assert respond_to?(:client)
  end
end

class TestBotHandlers < Test::Unit::TestCase

  should "include handlers" do
    bot = Twibot::Bot.new(Twibot::Config.new)

    assert_not_nil bot.handlers
    assert_not_nil bot.handlers[:message]
    assert_not_nil bot.handlers[:reply]
    assert_not_nil bot.handlers[:tweet]
  end

  should "add handler" do
    bot = Twibot::Bot.new(Twibot::Config.new)
    bot.add_handler :message, Twibot::Handler.new
    assert_equal 1, bot.handlers[:message].length

    bot.add_handler :message, Twibot::Handler.new
    assert_equal 2, bot.handlers[:message].length

    bot.add_handler :reply, Twibot::Handler.new
    assert_equal 1, bot.handlers[:reply].length

    bot.add_handler :reply, Twibot::Handler.new
    assert_equal 2, bot.handlers[:reply].length

    bot.add_handler :tweet, Twibot::Handler.new
    assert_equal 1, bot.handlers[:tweet].length

    bot.add_handler :tweet, Twibot::Handler.new
    assert_equal 2, bot.handlers[:tweet].length
  end
end
