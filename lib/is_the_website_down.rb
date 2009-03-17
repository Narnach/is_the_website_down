module IsTheWebsiteDown
  class Website
    attr_reader :url, :status, :time
    def initialize(url)
      @url=url
      @status=:unknown
      @time=Time.now
    end
  end
end
