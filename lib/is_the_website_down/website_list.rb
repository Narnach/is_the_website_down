require 'is_the_website_down/website'
module IsTheWebsiteDown
  class WebsiteList
    attr_accessor :auto_updater, :websites, :last_updated

    def initialize(urls = [])
      @websites = urls.map {|site| Website.new(site)}.sort_by {|site| site.name}
      @last_updated = Time.now
    end

    def auto_update
      return if @auto_updater
      @auto_updater = Thread.new(websites) do |sites|
        loop do
          sites.each {|site| site.update_status}
          @last_updated = Time.now
          sleep 1
        end
      end
    end

    def each(&block)
      websites.each(&block)
    end

    def self.load_file(file)
      urls = File.readlines(file)
      new(urls)
    end
  end
end