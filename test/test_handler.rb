require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper')) unless defined?(Twibot)

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

  test "should recognize empty pattern" do
    handler = Twibot::Handler.new
    message = message "cjno", "A twitter direct message"

    assert handler.recognize?(message)
  end

  test "should recognize empty pattern and allowed user" do
    handler = Twibot::Handler.new "", :from => "cjno"
    message = message "cjno", "A twitter direct message"
    assert handler.recognize?(message)

    handler = Twibot::Handler.new "", :from => ["cjno", "irbno"]
    assert handler.recognize?(message)
  end

  test "should not recognize empty pattern and disallowed user" do
    handler = Twibot::Handler.new "", :from => "irbno"
    message = message "cjno", "A twitter direct message"
    assert !handler.recognize?(message)

    handler = Twibot::Handler.new "", :from => ["irbno", "satan"]
    assert !handler.recognize?(message)
  end

  test "should recognize fixed pattern and no user" do
    handler = Twibot::Handler.new "time"
    message = message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "should recognize dynamic pattern and no user" do
    handler = Twibot::Handler.new "time :city :country"
    message = message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "should not recognize dynamic pattern and no user" do
    handler = Twibot::Handler.new "time :city :country"
    message = message "cjno", "oslo norway what is the time?"
    assert !handler.recognize?(message)
  end

  test "should recognize fixed pattern and user" do
    handler = Twibot::Handler.new "time", :from => ["cjno", "irbno"]
    message = message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "should recognize dynamic pattern and user" do
    handler = Twibot::Handler.new "time :city :country", :from => ["cjno", "irbno"]
    message = message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  test "should not recognize dynamic pattern and user" do
    handler = Twibot::Handler.new "time :city :country", :from => ["cjno", "irbno"]
    message = message "dude", "time oslo norway"
    assert !handler.recognize?(message)
  end

  test "should recognize symbol users" do
    handler = Twibot::Handler.new "time :city :country", :from => [:cjno, :irbno]
    message = message "dude", "time oslo norway"
    assert !handler.recognize?(message)

    message = message(:dude, "time oslo norway")
    assert !handler.recognize?(message)

    message = message("cjno", "time oslo norway")
    assert handler.recognize?(message)

    message = message(:cjno, "time oslo norway")
    assert handler.recognize?(message)
  end

  test "should provide parameters in params hash" do
    handler = Twibot::Handler.new("time :city :country", :from => ["cjno", "irbno"]) do |message, params|
      assert_equal "oslo", params[:city]
      assert_equal "norway", params[:country]
    end

    message = message "cjno", "time oslo norway"
    assert handler.recognize?(message)
    handler.dispatch(message)
  end

  test "handle should call constructor block" do
    handler = Twibot::Handler.new("time :city :country", :from => ["cjno", "irbno"]) do |message, params|
      raise "Boom!"
    end

    assert_raise(RuntimeError) do
      handler.handle(nil, nil)
    end
  end
end

def message(from, text)
  Twitter::Message.new(:id => 1,
                       :sender => from,
                       :text => text,
                       :recipient => "twibot",
                       :created_at => Time.now)
end
