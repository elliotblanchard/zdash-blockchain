require 'active_record'
require 'pry'

require 'colorize'
#require 'bitcoin'
require 'net/http'
require 'uri'
require 'json'
#require 'curl'

=begin
uri = URI.parse("http://127.0.0.1:8232/")
request = Net::HTTP::Post.new(uri)
request.basic_auth("samwellhouston", "silversandyblocks")
request.content_type = "text/plain"
request.body = JSON.dump({
  "jsonrpc" => "1.0",
  "id" => "curltest",
  "method" => "getinfo",
  "params" => "[]",
})

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

# response.code
# response.body

#client = Bitcoin::Client.new('samwellhouston', 'silversandyblocks', :host => '127.0.0.1')
#client.port = 8232
=end

=begin
curl = CURL.new
#page = curl.get("http://google.com")
=end

binding.pry
