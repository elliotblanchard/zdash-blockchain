require 'active_record'
require 'pry'

require 'colorize'

require 'net/http'
require 'uri'
require 'json'

uri = URI.parse("http://127.0.0.1:8232/")
request = Net::HTTP::Post.new(uri)
request.content_type = "text/plain;"
request.body = JSON.dump({
  "jsonrpc" => "1.0",
  "id" => "curltest",
  "method" => "getblockcount",
  "params" => "",
})

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

# response.code
# response.body

binding.pry
