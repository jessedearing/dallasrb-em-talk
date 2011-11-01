class HttpServer < EM::Connection
  include EM::HttpServer

  attr_accessor :post_callback

  def initialize(block)
    self.post_callback = block
  end

  def post_init
    super
    no_environment_strings
  end

  def process_http_request
    puts "HTTP call received calling post_callback"
    if @http_request_uri =~ /back/
      post_callback.call(-1)
    else
      post_callback.call(1)
    end
    puts "sending response"
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = ''
    response.send_response
  end
end
