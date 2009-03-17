Gem::Specification.new do |s|
  # Project
  s.name         = 'is_the_website_down'
  s.summary      = "Display an overview of websites that are down."
  s.description  = s.summary
  s.version      = '0.0.2'
  s.date         = '2009-3-17'
  s.platform     = Gem::Platform::RUBY
  s.authors      = ["Wes Oldenbeuving"]
  s.email        = "narnach@gmail.com"
  s.homepage     = "http://www.github.com/Narnach/is_the_website_down"

  # Files
  root_files     = %w[MIT-LICENSE README.rdoc Rakefile is_the_website_down.gemspec]
  bin_files      = %w[is_the_website_down]
  lib_files      = %w[is_the_website_down]
  test_files     = %w[]
  spec_files     = %w[is_the_website_down]
  view_files     = %w[index]
  s.bindir       = "bin"
  s.require_path = "lib"
  s.executables  = bin_files
  s.test_files   = test_files.map {|f| 'test/%s_test.rb' % f} + spec_files.map {|f| 'spec/%s_spec.rb' % f}
  s.files        = root_files + bin_files.map {|f| 'bin/%s' % f} + lib_files.map {|f| 'lib/%s.rb' % f} + s.test_files + view_files.map {|f| 'views/%s.haml' % f}

  # rdoc
  s.has_rdoc         = true
  s.extra_rdoc_files = %w[ README.rdoc MIT-LICENSE]
  s.rdoc_options << '--inline-source' << '--line-numbers' << '--main' << 'README.rdoc'

  # Requirements
  s.required_ruby_version = ">= 1.8.0"
  s.add_dependency "sinatra", ">= 0.9.1.1"
end
