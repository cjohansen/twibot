require File.join(File.dirname(__FILE__), 'test_helper')

class TestHandler < Test::Unit::TestCase
  test "pattern writer should abort on empty values" do
    handler = Twibot::Handler.new

    handler.pattern = nil
    assert_nil handler.instance_eval { @options[:pattern] }
    assert_nil handler.instance_eval { @options[:tokens] }

    handler.pattern = ""
    assert_nil handler.instance_eval { @options[:pattern] }
    assert_nil handler.instance_eval { @options[:tokens] }
  end

  test "pattern writer should turn regular pattern into regex" do
    handler = Twibot::Handler.new
    handler.pattern = "command"

    assert_equal(/command(\s.+)?/, handler.instance_eval { @options[:pattern] })
    assert_equal 0, handler.instance_eval { @options[:tokens] }.length
  end

  test "pattern writer should convert single named switch to regex" do
    handler = Twibot::Handler.new
    handler.pattern = ":command"

    assert_equal(/([^\s]+)(\s.+)?/, handler.instance_eval { @options[:pattern] })
    assert_equal 1, handler.instance_eval { @options[:tokens] }.length
    assert_equal :command, handler.instance_eval { @options[:tokens].first }
  end

  test "pattern writer should convert several named switches to regexen" do
    handler = Twibot::Handler.new
    handler.pattern = ":command fixed_word :subcommand"

    assert_equal(/([^\s]+) fixed_word ([^\s]+)(\s.+)?/, handler.instance_eval { @options[:pattern] })
    assert_equal 2, handler.instance_eval { @options[:tokens] }.length
    assert_equal :command, handler.instance_eval { @options[:tokens].first }
    assert_equal :subcommand, handler.instance_eval { @options[:tokens][1] }
  end

  test "pattern writer should convert several named switches to regexen specified by options" do
    handler = Twibot::Handler.new(":time :hour", :hour => /\d\d/)

    assert_equal(/([^\s]+) ((?-mix:\d\d))(\s.+)?/, handler.instance_eval { @options[:pattern] })
    assert_equal 2, handler.instance_eval { @options[:tokens] }.length
    assert_equal :time, handler.instance_eval { @options[:tokens].first }
    assert_equal :hour, handler.instance_eval { @options[:tokens][1] }
  end
end
