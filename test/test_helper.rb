require 'test/unit'
require 'context'
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
end
