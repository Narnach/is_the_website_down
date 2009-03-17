require 'sinatra'

module IsTheWebsiteDown
  class Website
    attr_reader :url, :status
    def initialize(url)
      @url=url
      @status=:unknown
    end
  end
end
