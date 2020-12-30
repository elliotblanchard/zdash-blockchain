require 'active_record'
require 'pry'

require 'colorize'
#require 'bitcoind'
require 'net/http'
require 'uri'
require 'json'
#require 'curl'

=begin
uri = URI.parse("http://192.168.1.158:8232/")
request = Net::HTTP::Post.new(uri)
request.basic_auth("samwellhouston", "silversandyblocks")
request.content_type = "text/plain"
request.body = JSON.dump({
  "jsonrpc" => "1.0",
  "method" => "getinfo",
  "params" => "[]",
})

req_options = {
  use_ssl: uri.scheme == "https",
}

response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
  http.request(request)
end

# curl -u samwellhouston:silversandyblocks silversandyblocks --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getinfo", "params": [] }' -H 'content-type: text/plain;' 192.168.1.158:8232/
# response.code
# response.body

curl = CURL.new
#page = curl.get("http://google.com")


client = CoinRPC::Client.new("http://samwellhouston:silversandyblocks@192.168.1.158:8232")
puts client.getblockchaininfo
=end

#output = `curl -u samwellhouston:silversandyblocks silversandyblocks --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getinfo", "params": [] }' -H 'content-type: text/plain;' 192.168.1.158:8232/`
output = `curl -u samwellhouston:silversandyblocks silversandyblocks --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getblock", "params": ["00000000febc373a1da2bd9f887b105ad79ddc26ac26c2b28652d64e5207c5b5"] }' -H 'content-type: text/plain;' 192.168.1.158:8232/`
#output = `curl -u samwellhouston:silversandyblocks silversandyblocks --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getrawtransaction", "params": ["d1510ab0f419a44e8b807eff96fd8a4c0115a46071ab19133b5f1e8bd2263244"] }' -H 'content-type: text/plain;' 192.168.1.158:8232/`
parsed = JSON.parse(output)
puts parsed

#binding.pry
