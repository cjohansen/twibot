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

  should "receive message" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error"))
    bot.add_handler(:message, Twibot::Handler.new)
    Twitter::Client.any_instance.expects(:messages).with(:received, {}).returns([twitter_message("cjno", "Hei der!")])

    assert bot.receive_messages
  end

  should "remember last received message" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error"))
    bot.add_handler(:message, Twibot::Handler.new)
    Twitter::Client.any_instance.expects(:messages).with(:received, {}).returns([twitter_message("cjno", "Hei der!")])
    assert_equal 1, bot.receive_messages

    Twitter::Client.any_instance.expects(:messages).with(:received, { :since_id => 1 }).returns([])
    assert_equal 0, bot.receive_messages
  end

  should "receive tweet" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error"))
    bot.add_handler(:tweet, Twibot::Handler.new)
    Twitter::Client.any_instance.expects(:timeline_for).with(:me, {}).returns([tweet("cjno", "Hei der!")])

    assert_equal 1, bot.receive_tweets
  end

  should "receive friend tweets if configured" do
    bot = Twibot::Bot.new(Twibot::Config.new({:log_level => "error", :include_friends => true}))
    bot.add_handler(:tweet, Twibot::Handler.new)
    Twitter::Client.any_instance.expects(:timeline_for).with(:friends, {}).returns([tweet("cjno", "Hei der!")])

    assert_equal 1, bot.receive_tweets
  end

  should "remember received tweets" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error"))
    bot.add_handler(:tweet, Twibot::Handler.new)
    Twitter::Client.any_instance.expects(:timeline_for).with(:me, {}).returns([tweet("cjno", "Hei der!")])
    assert_equal 1, bot.receive_tweets

    Twitter::Client.any_instance.expects(:timeline_for).with(:me, { :since_id => 1 }).returns([])
    assert_equal 0, bot.receive_tweets
  end

  should "receive reply when tweet starts with login" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error", :login => "irbno"))
    bot.add_handler(:reply, Twibot::Handler.new)
    Twitter::Client.any_instance.expects(:status).with(:replies, {}).returns([tweet("cjno", "@irbno Hei der!")])

    assert_equal 1, bot.receive_replies
  end

  should "remember received replies" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "error", :login => "irbno"))
    bot.add_handler(:reply, Twibot::Handler.new)
    Twitter::Client.any_instance.expects(:status).with(:replies, {}).returns([tweet("cjno", "@irbno Hei der!")])
    assert_equal 1, bot.receive_replies

    Twitter::Client.any_instance.expects(:status).with(:replies, { :since_id => 1 }).returns([])
    assert_equal 0, bot.receive_replies
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
