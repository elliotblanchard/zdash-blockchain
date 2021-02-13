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

# Shielded pool counters
sapling = 0
sapling_hidden = 0
sapling_revealed = 0
sprout = 0
sprout_hidden = 0
sprout_revealed = 0

# Main loop: get each block in Zcash blockchain
# Starting run to end at block 650000 (12/5/2019)

#(0..final_block).each do |i|
(0..50000).each do |i|
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
        vShieldedOutput: current_transaction['vShieldedOutput'],
        vShieldedSpend: current_transaction['vShieldedSpend'],
        valueBalance: current_transaction['valueBalance'],
        value: nil,
        outputValue: nil,
        shieldedValue: nil,
        overwintered: current_transaction['overwintered']
      )

      result = Classify.classify_transaction(t, sapling, sapling_hidden, sapling_revealed, sprout, sprout_hidden, sprout_revealed)
      t.category = result[:category]
      sapling = result[:sapling]
      sapling_hidden = result[:sapling_hidden]
      sapling_revealed = result[:sapling_revealed]
      sprout = result[:sprout]
      sprout_hidden = result[:sprout_hidden]
      sprout_revealed = result[:sprout_revealed]
      binding.pry if t.category.nil?

      latest_transactions << t
      if (latest_transactions.length % 1000).zero?
        print "Adding transaction #{latest_transactions.length} to latest_transactions.\n"
      end

    rescue => e
      binding.pry
      print "ERROR: #{e}.\n".colorize(:red)
    end
    if (latest_transactions.length % 4000).zero?
      print "Importing transactions at #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}.\n"
      #Transaction.import latest_transactions
      #print "Finished importing transactions. At block #{i} of #{final_block} (#{((i.to_f / final_block) * 100).round(2)}%) at #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}. Imported #{latest_transactions.length} transactions.\n"
      print "TEST RUN, not importing to DB.\n"
      latest_transactions = []
    end
  end
end
# Save final group of transacations in the array
print "Importing blocks at #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}.\n"
#Transaction.import latest_transactions
print "TEST RUN, not importing to DB.\n"
binding.pry
#print "Finished block #{i} of #{final_block} (#{((i.to_f / final_block) * 100).round(2)}%) at #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}. Imported #{latest_transactions.length} transactions.\n"
latest_transactions = []