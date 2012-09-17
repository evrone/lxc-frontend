require 'rubygems'
require 'bundler'

Bundler.require

use Rack::Auth::Basic, "LXC Frontend" do |username, password|
  [username, password] == ['user', 'password']
end

require './frontend'
run LXCFrontend
