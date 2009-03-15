# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'twibot'

task :default => 'test:run'

PROJ.name = 'twibot'
PROJ.authors = 'Christian Johansen'
PROJ.email = 'christian@cjohansen.no'
PROJ.url = 'http://github.com/cjohansen/twibot/'
PROJ.version = Twibot::VERSION
PROJ.rubyforge.name = 'twibot'
PROJ.readme_file = 'Readme.rdoc'
PROJ.rdoc.remote_dir = 'twibot'

depend_on "mbbx6spp-twitter4r", "0.3.1"
