require 'test/unit'
require 'shoulda'
require 'mocha'
require File.join(File.dirname(__FILE__), '../lib/twibot')

module Test::Unit::Assertions
  def assert_hashes_equal(expected, actual, message = nil)
    full_message = build_message(message, <<EOT, expected.inspect, actual.inspect)
<?> expected but was
<?>.
EOT
    assert_block(full_message) do
      break false if expected.keys.length != actual.keys.length
      expected.keys.all? { |k| expected[k] == actual[k] }
    end
  end

  def assert_hashes_not_equal(expected, actual, message = nil)
    full_message = build_message(message, <<EOT, expected.inspect, actual.inspect)
<?> expected but was
<?>.
EOT
    assert_block(full_message) do
      break false if expected.keys.length != actual.keys.length
      expected.keys.any? { |k| expected[k] != actual[k] }
    end
  end
end

def twitter_message(from, text)
  Twitter::Message.new(:id => 1,
                       :sender => Twitter::User.new(:screen_name => from),
                       :text => text,
                       :recipient => "twibot",
                       :created_at => Time.now)
end

def tweet(from, text)
  Twitter::Status.new(:id => 1,
                      :text => text,
                      :user => Twitter::User.new(:screen_name => from),
                      :created_at => Time.now)
end
