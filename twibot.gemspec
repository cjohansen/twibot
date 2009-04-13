# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{twibot}
  s.version = "0.1.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christian Johansen"]
  s.date = %q{2009-04-13}
  s.description = %q{Twibot (pronounced like "Abbot"), is a Ruby microframework for creating Twitter bots, heavily inspired by Sinatra.}
  s.email = %q{christian@cjohansen.no}
  s.extra_rdoc_files = ["History.txt", "Readme.rdoc"]
  s.files = ["History.txt", "Rakefile", "Readme.rdoc", "lib/hash.rb", "lib/twibot.rb", "lib/twibot/bot.rb", "lib/twibot/config.rb", "lib/twibot/handlers.rb", "lib/twibot/macros.rb", "lib/twibot/tweets.rb", "test/test_bot.rb", "test/test_config.rb", "test/test_handler.rb", "test/test_hash.rb", "test/test_helper.rb", "test/test_twibot.rb", "twibot.gemspec"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/bjeanes/twibot/}
  s.rdoc_options = ["--main", "Readme.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{twibot}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Twibot (pronounced like "Abbot"), is a Ruby microframework for creating Twitter bots, heavily inspired by Sinatra}
  s.test_files = ["test/test_bot.rb", "test/test_config.rb", "test/test_handler.rb", "test/test_hash.rb", "test/test_helper.rb", "test/test_twibot.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<mbbx6spp-twitter4r>, [">= 0.3.1"])
      s.add_development_dependency(%q<bones>, [">= 2.5.0"])
    else
      s.add_dependency(%q<mbbx6spp-twitter4r>, [">= 0.3.1"])
      s.add_dependency(%q<bones>, [">= 2.5.0"])
    end
  else
    s.add_dependency(%q<mbbx6spp-twitter4r>, [">= 0.3.1"])
    s.add_dependency(%q<bones>, [">= 2.5.0"])
  end
end
