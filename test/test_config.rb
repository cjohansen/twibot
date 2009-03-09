require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper')) unless defined?(Twibot)
require 'stringio'

class TestConfig < Test::Unit::TestCase
  test "default configuration should be a hash" do
    assert_not_nil Twibot::Config::DEFAULT
    assert Twibot::Config::DEFAULT.is_a?(Hash)
  end

  test "should initialize with no options" do
    assert_hashes_equal({}, Twibot::Config.new.settings)
  end

  test "add config should return config" do
    config = Twibot::Config.new
    assert_equal config, config.add(Twibot::Config.new)
  end

  test "add config should be aliased to <<" do
    config = Twibot::Config.new
    assert config.respond_to?(:<<)
    assert config << Twibot::Config.new
  end

  test "missing methods should act as config getters" do
    config = Twibot::Config.default << Twibot::Config.new
    assert_equal Twibot::Config::DEFAULT[:min_interval], config.min_interval
    assert_equal Twibot::Config::DEFAULT[:login], config.login
  end

  test "missing methods should act as config setters" do
    config = Twibot::Config.default << Twibot::Config.new
    assert_equal Twibot::Config::DEFAULT[:min_interval], config.min_interval

    val = config.min_interval
    config.min_interval = val + 5
    assert_not_equal Twibot::Config::DEFAULT[:min_interval], config.min_interval
    assert_equal val + 5, config.min_interval
  end

  test "default configuration should not override default hash" do
    config = Twibot::Config.default
    hash = Twibot::Config::DEFAULT

    config.min_interval = 0
    config.max_interval = 0

    assert_hashes_not_equal Twibot::Config::DEFAULT, config.to_hash
    assert_hashes_equal hash, Twibot::Config::DEFAULT
  end

  test "to_hash should return merged configuration" do
    config = Twibot::Config.new
    config.min_interval = 10
    config.max_interval = 10

    config2 = Twibot::Config.new({})
    config2.min_interval = 1
    config << config2
    options = config.to_hash

    assert_equal 10, options[:max_interval]
    assert_equal 1, options[:min_interval]
  end
end

class TestCliConfig < Test::Unit::TestCase
  test "should configure from options" do
    config = Twibot::CliConfig.new %w{--min-interval 10 --max-interval 15}
    assert_equal 10, config.min_interval
    assert_equal 15, config.max_interval
  end
end

class TestFileConfig < Test::Unit::TestCase
  test "file config should subclass config" do
    assert Twibot::FileConfig.new(StringIO.new).is_a?(Twibot::Config)
  end

  test "should read settings from stream" do
    config = Twibot::FileConfig.new(StringIO.new <<-YAML)
min_interval: 10
max_interval: 20
    YAML

    assert_equal 10, config.min_interval
    assert_equal 20, config.max_interval
  end
end
