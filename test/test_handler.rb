require File.expand_path(File.join(File.dirname(__FILE__), 'test_helper')) unless defined?(Twibot)

class TestHandler < Test::Unit::TestCase
  context "pattern writer" do
    should "abort on empty values" do
      handler = Twibot::Handler.new

      handler.pattern = nil
      assert_nil handler.instance_eval { @options[:pattern] }
      assert_nil handler.instance_eval { @options[:tokens] }

      handler.pattern = ""
      assert_nil handler.instance_eval { @options[:pattern] }
      assert_nil handler.instance_eval { @options[:tokens] }
    end

    should "turn regular pattern into regex" do
      handler = Twibot::Handler.new
      handler.pattern = "command"

      assert_equal(/command(\s.+)?/, handler.instance_eval { @options[:pattern] })
      assert_equal 0, handler.instance_eval { @options[:tokens] }.length
    end

    should "convert single named switch to regex" do
      handler = Twibot::Handler.new
      handler.pattern = ":command"

      assert_equal(/([^\s]+)(\s.+)?/, handler.instance_eval { @options[:pattern] })
      assert_equal 1, handler.instance_eval { @options[:tokens] }.length
      assert_equal :command, handler.instance_eval { @options[:tokens].first }
    end

    should "convert several named switches to regexen" do
      handler = Twibot::Handler.new
      handler.pattern = ":command fixed_word :subcommand"

      assert_equal(/([^\s]+) fixed_word ([^\s]+)(\s.+)?/, handler.instance_eval { @options[:pattern] })
      assert_equal 2, handler.instance_eval { @options[:tokens] }.length
      assert_equal :command, handler.instance_eval { @options[:tokens].first }
      assert_equal :subcommand, handler.instance_eval { @options[:tokens][1] }
    end

    should "convert several named switches to regexen specified by options" do
      handler = Twibot::Handler.new(":time :hour", :hour => /\d\d/)

      assert_equal(/([^\s]+) ((?-mix:\d\d))(\s.+)?/, handler.instance_eval { @options[:pattern] })
      assert_equal 2, handler.instance_eval { @options[:tokens] }.length
      assert_equal :time, handler.instance_eval { @options[:tokens].first }
      assert_equal :hour, handler.instance_eval { @options[:tokens][1] }
    end
  end

  should "recognize empty pattern" do
    handler = Twibot::Handler.new
    message = twitter_message "cjno", "A twitter direct message"

    assert handler.recognize?(message)
  end

  should "recognize empty pattern and allowed user" do
    handler = Twibot::Handler.new "", :from => "cjno"
    message = twitter_message "cjno", "A twitter direct message"
    assert handler.recognize?(message)

    handler = Twibot::Handler.new "", :from => ["cjno", "irbno"]
    assert handler.recognize?(message)
  end

  should "not recognize empty pattern and disallowed user" do
    handler = Twibot::Handler.new "", :from => "irbno"
    message = twitter_message "cjno", "A twitter direct message"
    assert !handler.recognize?(message)

    handler = Twibot::Handler.new "", :from => ["irbno", "satan"]
    assert !handler.recognize?(message)
  end

  should "recognize fixed pattern and no user" do
    handler = Twibot::Handler.new "time"
    message = twitter_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  should "recognize dynamic pattern and no user" do
    handler = Twibot::Handler.new "time :city :country"
    message = twitter_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  should "not recognize dynamic pattern and no user" do
    handler = Twibot::Handler.new "time :city :country"
    message = twitter_message "cjno", "oslo norway what is the time?"
    assert !handler.recognize?(message)
  end

  should "recognize fixed pattern and user" do
    handler = Twibot::Handler.new "time", :from => ["cjno", "irbno"]
    message = twitter_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  should "recognize dynamic pattern and user" do
    handler = Twibot::Handler.new "time :city :country", :from => ["cjno", "irbno"]
    message = twitter_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  should "not recognize dynamic pattern and user" do
    handler = Twibot::Handler.new "time :city :country", :from => ["cjno", "irbno"]
    message = twitter_message "dude", "time oslo norway"
    assert !handler.recognize?(message)
  end

  should "recognize symbol users" do
    handler = Twibot::Handler.new "time :city :country", :from => [:cjno, :irbno]
    message = twitter_message "dude", "time oslo norway"
    assert !handler.recognize?(message)

    message = twitter_message("cjno", "time oslo norway")
    assert handler.recognize?(message)
  end

  should "recognize tweets from allowed users" do
    handler = Twibot::Handler.new :from => [:cjno, :irbno]
    message = tweet "cjno", "time oslo norway"
    assert handler.recognize?(message)
  end
  
  should "recognize tweets from allowed users with capital screen names" do
    handler = Twibot::Handler.new :from => [:cjno, :irbno]
    message = tweet "Cjno", "time oslo norway"
    assert handler.recognize?(message)
  end

  should "accept options as only argument" do
    handler = Twibot::Handler.new :from => :cjno
    assert_equal(:cjno, handler.instance_eval { @options[:from] })
    assert_nil handler.instance_eval { @options[:pattern] }
  end

  should "provide parameters in params hash" do
    handler = Twibot::Handler.new("time :city :country", :from => ["cjno", "irbno"]) do |message, params|
      assert_equal "oslo", params[:city]
      assert_equal "norway", params[:country]
    end

    message = twitter_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
    handler.dispatch(message)
  end

  should "call constructor block from handle" do
    handler = Twibot::Handler.new("time :city :country", :from => ["cjno", "irbno"]) do |message, params|
      raise "Boom!"
    end

    assert_raise(RuntimeError) do
      handler.handle(nil, nil)
    end
  end

  should "recognize regular expressions" do
    handler = Twibot::Handler.new /(?:what|where) is (.*)/i
    message = twitter_message "dude", "Where is this shit?"
    assert handler.recognize?(message)

    message = twitter_message "dude", "How is this shit?"
    assert !handler.recognize?(message)
  end

  should "recognize regular expressions from specific users" do
    handler = Twibot::Handler.new /(?:what|where) is (.*)/i, :from => "cjno"
    message = twitter_message "dude", "Where is this shit?"
    assert !handler.recognize?(message)

    message = twitter_message "cjno", "Where is this shit?"
    assert handler.recognize?(message)
  end

  should "provide parameters as arrays when matching regular expressions" do
    handler = Twibot::Handler.new(/time ([^\s]*) ([^\s]*)/) do |message, params|
      assert_equal "oslo", params[0]
      assert_equal "norway", params[1]
    end

    message = twitter_message "cjno", "time oslo norway"
    assert handler.recognize?(message)
    handler.dispatch(message)
  end
end
