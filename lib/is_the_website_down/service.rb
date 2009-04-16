require 'is_the_website_down'
require 'haml'

root_dir = File.expand_path(File.join(File.dirname(__FILE__),'..','..'))

sites_file = File.join(root_dir,'config','sites.txt')
unless File.exist? sites_file
  STDERR.puts "config/sites.txt is missing. Please create it. See config/sites.txt.example for examples"
  exit 1
end

websites = IsTheWebsiteDown::WebsiteList.load_file(sites_file)
websites.auto_update

locals = {
  :title => "Is the website down?",
  :websites => websites
}

get '/' do
  haml :index, :locals => locals
end

get '/style.css' do
  content_type 'text/css'
  sass :style
end