require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper')) unless defined?(Twibot)
require 'fileutils'

class TestBot < Test::Unit::TestCase
  test "should not raise errors when initialized" do
    assert_nothing_raised do
      Twibot::Bot.new Twibot::Config.new
    end
  end

  test "should raise errors when initialized without config file" do
    assert_raise SystemExit do
      Twibot::Bot.new
    end
  end

  test "should not raise error on initialize when config file exists" do
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

  test "should provide configuration settings as methods" do
    bot = Twibot::Bot.new Twibot::Config.new(:max_interval => 3)
    assert_equal 3, bot.max_interval
  end

  test "log should return logger instance" do
    bot = Twibot::Bot.new(Twibot::Config.default << Twibot::Config.new)
    assert bot.log.is_a?(Logger)
  end

  test "logger should respect configured level" do
    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "info"))
    assert_equal Logger::INFO, bot.log.level

    bot = Twibot::Bot.new(Twibot::Config.new(:log_level => "warn"))
    assert_equal Logger::WARN, bot.log.level
  end

  test "receive should return false without handlers" do
    bot = Twibot::Bot.new(Twibot::Config.new)
    assert !bot.receive(:messages)
    assert !bot.receive(:message)
    assert !bot.receive(:replies)
    assert !bot.receive(:reply)
    assert !bot.receive(:tweets)
    assert !bot.receive(:tweet)
  end

  test "should receive message" do
    bot = Twibot::Bot.new(Twibot::Config.new)
    bot.add_handler(:message, Twibot::Handler.new)
    bot.any_instance.expects(:messages).with(:received, nil).returns(message("cjno", "Hei der!"))
  end
end

class TestBotMacros < Test::Unit::TestCase
  test "should provide configure macro" do
    bot = Twibot::Bot.new Twibot::Config.new
    assert bot.respond_to?(:configure)
  end

  test "configure should yield configuration" do
    bot = Twibot::Bot.new Twibot::Config.new
    conf = nil
    bot.configure { |c| conf = c }
    assert conf.is_a?(Twibot::Config)
  end
end

class TestBotHandlers < Test::Unit::TestCase

  test "should include handlers" do
    bot = Twibot::Bot.new(Twibot::Config.new)

    assert_not_nil bot.handlers
    assert_not_nil bot.handlers[:message]
    assert_not_nil bot.handlers[:reply]
    assert_not_nil bot.handlers[:tweet]
  end

  test "should add handler" do
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
