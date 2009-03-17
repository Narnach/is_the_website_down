require 'net/http'
require 'timeout'
require 'future' # http://github.com/Narnach/future

module IsTheWebsiteDown
  class Website
    attr_reader :url, :status, :time, :message, :public_url, :code, :uri
    def initialize(url)
      @url=url
      @uri = URI.parse(@url)
      @uri.path='/' if @uri.path==''
      @status=:unknown
      @time=Time.now
      @seconds_between_polls=5
      @timeout = 1
      @message = "The website has not yet been checked"
      safe_uri = uri.clone
      safe_uri.user=safe_uri.password = nil
      @public_url = safe_uri.to_s
      @code = nil
    end
    
    def name
      uri = URI.parse(@url)
      uri.host +
        (uri.port != 80 ? ":#{uri.port}" : "") +
        (uri.path.to_s != "/" ? uri.path.to_s : "")
    end
    
    def poll
      return @status unless seconds_since_poll > @seconds_between_polls or @status == :unknown
      @time = Time.now
      @status = Future.new do
        response = nil
        timeout @timeout * 2, :connection_timeout do
          Net::HTTP.start(uri.host,uri.port) do |http|
            req = Net::HTTP::Head.new(uri.path)
            timeout @timeout, :request_timeout do
              req.basic_auth(uri.user, uri.password) if uri.user && uri.password
              response = http.request(req)
            end
          end
        end
        @message = nil
        next @status unless response
        @code = response.code
        case response
        when Net::HTTPSuccess      # 2xx
          @status = :up
        when Net::HTTPNotFound     # 404
          @status = :down
        when Net::HTTPUnauthorized # 401
          @status = :unauthorized
          @message = "Authentication incorrect or missing"
        when Net::HTTPRedirection  # 3xx
          @status = :redirect
          @message = "Redirects to #{response['Location']}"
        else
          @status = :down
          @message = "Response code #{response.code}, class #{response.class.name}"
        end
        @status
      end
    end
    
    def seconds_since_poll
      Time.now - @time
    end
    
    def timeout(duration, fail_status=:timeout, &block)
      Timeout::timeout(duration, &block)
      true
    rescue Timeout::Error
      @status = fail_status
      false
    end
    
    def up?
      @status == :up
    end
    
    def to_s
      res = case @status
        when :up
          "Server is up"
        when :down
          "Site is down"
        when :connection_timeout
          "Connection timeout"
        when :request_timeout
          "Request timeout"
        when :redirect
          "Redirected"
        when :unauthorized
          "Unauthorized"
        when :unknown
          "Status unknown"
        else
          @status.to_s
        end
      if @message
        res += ". #{@message}"
      end
      res
    end
  end
end
