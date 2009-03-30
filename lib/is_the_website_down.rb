# Ruby core
require 'net/http'
require 'timeout'
require 'monitor'

# Rubygems
require 'future' # http://github.com/Narnach/future

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

  class Website < Monitor
    attr_reader :url, :status, :time, :message, :public_url, :code, :uri
    attr_accessor :min_seconds_between_polls, :max_seconds_between_polls, :seconds_between_polls

    def initialize(url)
      @url=url
      @uri = URI.parse(@url)
      @uri.path='/' if @uri.path==''
      @status=:unknown
      @time=Time.now
      @max_seconds_between_polls = 60
      @min_seconds_between_polls = 10
      @seconds_between_polls = 60
      @timeout = 5
      @message = "The website has not yet been checked"
      safe_uri = uri.clone
      safe_uri.user=safe_uri.password = nil
      @public_url = safe_uri.to_s
      @code = nil
    end

    def name
      uri.host
    end

    def update_status
      return status unless update_needed?
      @time = Time.now
      @status = Future.new do
        response = nil
        @message = nil
        @code = nil
        timeout @timeout * 2, :connection_timeout do
          begin
            Net::HTTP.start(uri.host,uri.port) do |http|
              req = Net::HTTP::Head.new(uri.path)
              timeout @timeout, :request_timeout do
                req.basic_auth(uri.user, uri.password) if uri.user && uri.password
                response = http.request(req)
              end
            end
          rescue SystemCallError => e
            @status = :down
            @message = e.message
            @seconds_between_polls /= 2
            @seconds_between_polls = @min_seconds_between_polls if @seconds_between_polls < @min_seconds_between_polls
          rescue SocketError => e
            @status = :down
            @message = e.message
            @seconds_between_polls /= 2
            @seconds_between_polls = @min_seconds_between_polls if @seconds_between_polls < @min_seconds_between_polls
          end
        end
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
        @seconds_between_polls = @max_seconds_between_polls unless status == :down
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

    def update_needed?
      seconds_since_poll > seconds_between_polls or status == :unknown
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
