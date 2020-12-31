require 'active_record'
require 'json'
require 'pry'
require 'colorize'
require 'rpcjson'
require 'net/http'
require 'uri'
require_relative './models/transaction'
require_relative './helpers/classify'

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end

# Establish connection to Zcash RPC server and database
zc = RPC::JSON::Client.new 'http://samwellhouston:silversandyblocks@192.168.1.158:8232', 1.1
ActiveRecord::Base.establish_connection(db_configuration['development'])

puts "Server info is: #{zc.getinfo}"
block_id = "00000000febc373a1da2bd9f887b105ad79ddc26ac26c2b28652d64e5207c5b5"
res = zc.getblock(block_id, 1)
tx_hash = res['tx'][0]
puts "Sample transaction via getblock: #{tx_hash}"
res = zc.getrawtransaction(tx_hash,1,block_id)
tx_id = res['txid']
puts "Sample transaction via getrawtransaction: #{tx_id}"

binding.pry
