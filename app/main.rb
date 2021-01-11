require 'active_record'
require 'activerecord-import'
require 'json'
require 'pry'
require 'colorize'
require 'rpcjson'
require 'net/http'
require 'uri'
require_relative './models/transaction'
require_relative './helpers/classify'

clear_line = "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"

def db_configuration
  db_configuration_file = File.join(File.expand_path('..', __FILE__), '..', 'db', 'config.yml')
  YAML.load(File.read(db_configuration_file))
end

# Establish connection to Zcash RPC server and database
zc = RPC::JSON::Client.new 'http://samwellhouston:silversandyblocks@192.168.1.158:8232', 1.1
ActiveRecord::Base.establish_connection(db_configuration['development'])

zc_network = zc.getinfo
final_block = zc_network["blocks"] - 100 # 100 most recent blocks may not be finalized
latest_transactions = []

# Main loop: get each block in Zcash blockchain

(1026297..final_block).each do |i|
  current_block = zc.getblock(i.to_s, 1)
  num_transactions = current_block['tx'].length - 1
  # Inner loop: get each transaction in this block
  (0..num_transactions).each do |j|
    tx_hash = current_block['tx'][j]
    begin
      current_transaction = zc.getrawtransaction(tx_hash.to_s, 1)
      t = Transaction.new(
        zhash: current_transaction['txid'],
        mainChain: nil,
        fee: nil,
        ttype: nil,
        shielded: nil,
        index: nil,
        blockHash: current_block['hash'],
        blockHeight: i,
        version: current_transaction['version'],
        lockTime: current_transaction['locktime'],
        timestamp: current_transaction['time'],
        time: nil,
        vin: current_transaction['vin'],
        vout: current_transaction['vout'],
        vjoinsplit: current_transaction['vjoinsplit'],
        vShieldedOutput: nil,
        vShieldedSpend: nil,
        valueBalance: nil,
        value: nil,
        outputValue: nil,
        shieldedValue: nil,
        overwintered: nil
      )

      t.category = Classify.classify_transaction(t)  
      latest_transactions << t

    rescue => e
      print "For block #{i} / transaction #{j} transaction #{tx_hash} not found.\n".colorize(:red)
    end
    if (i % 1000).zero?
      Transaction.import latest_transactions
      print "Finished block #{i} of #{final_block} (#{((i.to_f / final_block) * 100).round(2)}%). Imported #{latest_transactions.length} transactions.\n"
      latest_transactions = []
    end
  end
end