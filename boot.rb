lib = File.expand_path('../lib', __FILE__)

$LOAD_PATH.unshift(lib)
ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', __FILE__)

require 'bundler/setup'
require 'bundler'
Bundler.require

require 'scarabee'
