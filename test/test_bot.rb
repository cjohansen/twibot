require 'fileutils'
require File.join(File.dirname(__FILE__), 'test_helper')

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
