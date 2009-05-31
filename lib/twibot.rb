require 'time'
require 'twitter'
require 'twitter/client'
require 'yaml'
require File.join(File.dirname(__FILE__), 'hash')

module Twibot

  # :stopdoc:
  VERSION = '0.1.7'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end

  # Utility method used to require all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= File.basename(fname, '.*')
    search_me = File.expand_path(File.join(File.dirname(fname), dir, '**', '*.rb'))
    Dir.glob(search_me).sort.each {|rb| require rb }
  end

  @@app_file = lambda do
    ignore = [
      /lib\/twibot.*\.rb/, # Library
      /\(.*\)/,            # Generated code
      /custom_require\.rb/ # RubyGems require
    ]

    path = caller.map { |line| line.split(/:\d/, 2).first }.find do |file|
      next if ignore.any? { |pattern| file =~ pattern }
      file
    end

    path || $0
  end.call

  #
  # File name of the application file. Inspired by Sinatra
  #
  def self.app_file
    @@app_file
  end

  #
  # Runs application if application file is the script being executed
  #
  def self.run?
    self.app_file == $0
  end

end  # module Twibot

Twitter::Client.configure do |config|
  config.application_name = 'Twibot'
  config.application_version = Twibot.version
  config.application_url = 'http://github.com/cjohansen/twibot'
end

Twibot.require_all_libs_relative_to(__FILE__)

# EOF
