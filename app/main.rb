require 'active_record'
require 'activerecord-import'
require 'json'
require 'pry'
require 'colorize'
require 'rpcjson'
require 'net/http'
require 'uri'
require_relative './models/transaction'
require_relative './models/pool'
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

start_block = 1172000
final_block = zc_network["blocks"] - 100 # 100 most recent blocks may not be finalized
latest_transactions = []
latest_pools = []

# Shielded pool counters
sapling = 0
sapling_hidden = 0
sapling_revealed = 0
sapling_pool = 0
sprout = 0
sprout_hidden = 0
sprout_revealed = 0
sprout_pool = 0

# If run starts AFTER block 0, first load the last sapling and sprout values so calculations continue correctly
if start_block > 0
  max_timestamp = Pool.maximum('timestamp')
  p = Pool.where("timestamp = #{max_timestamp}").first
  sapling = p.sapling
  sapling_hidden = p.saplingHidden
  sapling_revealed = p.saplingRevealed
  sapling_pool = p.saplingPool
  sprout = p.sprout
  sprout_hidden = p.sproutHidden
  sprout_revealed = p.sproutRevealed
  sprout_pool = p.sproutPool
end

# Main loop: get each block in Zcash blockchain

# Running ALL vjoinsplit containing transactions give 95,871 for the pool size,
# Which is about twice what this would show for 4/2017: 
# https://aws1.discourse-cdn.com/zcash/original/3X/5/8/58509d75f84b9e1c6da53101c3ad113925b1994b.png

# current final count of sprout pool: 1,907,547
# final count of sprout pool after double counting fix: 733,216

(start_block..final_block).each do |i|
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

      result = Classify.classify_transaction(
        t,
        sapling,
        sapling_hidden,
        sapling_revealed,
        sprout,
        sprout_hidden,
        sprout_revealed
      )
      t.category = result[:category]
      sapling = result[:sapling]
      sapling_hidden = result[:sapling_hidden]
      sapling_revealed = result[:sapling_revealed]
      sprout = result[:sprout]
      sprout_hidden = result[:sprout_hidden]
      sprout_revealed = result[:sprout_revealed]

      binding.pry if t.category.nil?

      latest_transactions << t
      #if ( (i > 435) && (i < 445) )
      #  print "#{t.vjoinsplit}\n\n".colorize(:blue)
      #end
      #if (latest_transactions.length % 1000).zero?
      #  print "Adding transaction #{latest_transactions.length} to latest_transactions.\n"
      #end

    rescue => e
      binding.pry
      print "ERROR: #{e}.\n".colorize(:red)
    end
    if (latest_transactions.length % 4000).zero?
      print "At block: #{i} Importing transactions at #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}.\n"
      Transaction.import latest_transactions
      print "Finished importing transactions. At block #{i} of #{final_block} (#{((i.to_f / final_block) * 100).round(2)}%) at #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}. Imported #{latest_transactions.length} transactions.\n"
      #print "TEST RUN, not importing to DB.\n"
      latest_transactions = []
    end
  end
  sprout_pool = (sprout_hidden - sprout_revealed) / 100000000
  sapling_pool = sapling_hidden - sapling_revealed
  if latest_transactions.last
    timestamp = latest_transactions.last.timestamp
  else
    timestamp = 0
  end
  p = Pool.new(
    blockHeight: i,
    timestamp: timestamp,
    sprout: 0,
    sproutHidden: 0.0,
    sproutRevealed: 0.0,
    sproutPool: current_block['valuePools'][0]['chainValue'],
    sapling: 0,
    saplingHidden: 0.0,
    saplingRevealed: 0.0,
    saplingPool: current_block['valuePools'][1]['chainValue']
  )
  latest_pools << p
  #print "At block: #{i} Sprout pool: #{sprout_pool} sapling pool: #{sapling_pool}.\n".colorize(:green)
  if (latest_pools.length % 4000).zero?
    print "At block: #{i} Importing pools. sprout pool: #{current_block['valuePools'][0]['chainValue']} sapling pool: #{current_block['valuePools'][1]['chainValue']}.\n"
    Pool.import latest_pools
    latest_pools = []
  end
end
# Save final group of transacations in the array
print "Importing blocks at #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}.\n"
Transaction.import latest_transactions
#print "TEST RUN, not importing to DB.\n"
#print "Finished block #{i} of #{final_block} (#{((i.to_f / final_block) * 100).round(2)}%) at #{DateTime.now.strftime('%I:%M%p %a %m/%d/%y')}. Imported #{latest_transactions.length} transactions.\n"
latest_transactions = []
latest_pools = []