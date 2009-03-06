require File.join(File.dirname(__FILE__), 'test_helper')

class TestHash < Test::Unit::TestCase
  test "should convert string keys to symbols" do
    hash = { "one" => 1, "two" => 2 }
    hash.symbolize_keys!

    assert_equal 1, hash[:one]
    assert_equal 2, hash[:two]
    assert_nil hash["one"]
    assert_nil hash["two"]
  end

  test "should convert string keys and preserve symbol keys" do
    hash = { "one" => 1, :two => 2 }
    hash.symbolize_keys!

    assert_equal 1, hash[:one]
    assert_equal 2, hash[:two]
    assert_nil hash["one"]
    assert_nil hash["two"]
  end

  test "should convert hashes recursively" do
    hash = { "one" => 1, :two => { "three" => 3, "four" => 4 } }
    hash.symbolize_keys!

    assert_equal 1, hash[:one]
    assert_equal 3, hash[:two][:three]
    assert_equal 4, hash[:two][:four]
    assert_nil hash["one"]
    assert_nil hash["two"]
  end
end
