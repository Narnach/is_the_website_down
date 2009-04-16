root_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(root_dir, 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'rubygems'
require 'sinatra'
require 'is_the_website_down/service'

set :environment, :production
set :root,    root_dir
set :app_file,  File.join(root_dir, 'lib','is_the_website_down','service.rb')
disable :run

set :views, File.join(root_dir, 'views')
set :static, true
set :public, File.join(root_dir, 'public')

FileUtils.mkdir_p 'logs' unless File.exists?('logs')
log = File.new("logs/sinatra.log", "a")
$stdout.reopen(log)
$stderr.reopen(log)

run Sinatra::Application