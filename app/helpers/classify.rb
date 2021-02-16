module Classify
    def Classify.classify_transaction(transaction, sapling, sapling_hidden, sapling_revealed, sprout, sprout_hidden, sprout_revealed)
      # Some example transaction hashes:
      # d456a889ddc87ad41e379de5bb245781333fd883b67bf34eebabd1a6fb7e144a
      # d2ebc0cfd864027eb0887e1dcb772b4d1ca7bc016504889a6843583c2ca73bb4
      # f0d27409c193fef51b66a922794583f08c880ab220229c813995143e1cd244d5
      # c13632d045a685dfead48b62ceb8d0adb188fef9e3f902c65112a88a4dbed4fe
      
      if transaction
        # Shielded pool size detection
        if transaction.vjoinsplit.length > 2
          # vpubold + vpubnew seem to both be inside vjoinsplit
          # Python classification is:
          # sprout += 1
          # sprout_hidden += tx.sum_vpubold
          # sprout_revealed += tx.sum_vpubnew
          # sprout_balance = (sprout_hidden - sprout_revealed) / 100000000
          #print("Before add sprout_hidden is: #{sprout_hidden}, and sprout_revealed is: #{sprout_revealed}\n")
          fields = transaction.vjoinsplit.split(' ')
          vpub_old = fields[0].split('=>')[1].gsub('"', '').gsub(',', '').to_f
          vpub_new = fields[2].split('=>')[1].gsub('"', '').gsub(',', '').to_f
          #print("Transaction hash: #{transaction.zhash}, vpub_old: #{fields[0]}, vpub_new: #{fields[2]}\n")
          sprout += 1
          sprout_hidden += vpub_old
          sprout_revealed += vpub_new
          #print("After add sprout_hidden is: #{sprout_hidden}, and sprout_revealed is: #{sprout_revealed}\n")
        end
        
        # Transaction classification
        if transaction.vin.length > 2
          parsed = transaction.vin.split(',')
          if ( (parsed[0].length > 18) && (parsed[0].include? 'coinbase'))
            # vin arr contains coinbase field w/address
            # This next if / else is custom to the blockchain
            # due to differences in way zcash-cli (blockchain)
            # and zcha.in API (ongoing) report vShieldedOutput
            if transaction.vShieldedOutput
              if transaction.vShieldedOutput.length > 2
                print("Shielded coinbase: #{transaction.zhash}")
                {category: 'shielded_coinbase', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
              else
                {category: 'transparent_coinbase', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
              end
            else
              {category: 'transparent_coinbase', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
            end
          else
            if transaction.vout.length > 2
              {category: 'transparent', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
            else
              if transaction.vjoinsplit.length > 2
                {category: 'sprout_shielding', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
              else
                {category: 'sapling_shielding', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
              end
            end
          end
        else
          if transaction.vout.length > 2
            if transaction.vjoinsplit.length > 2
              {category: 'sprout_deshielding', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
            else
              {category: 'sapling_deshielding', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
            end
          else
            if transaction.vjoinsplit.length > 2
              if ( transaction.vShieldedOutput && (transaction.vShieldedOutput.length > 2) )
                {category: 'migration', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
              else
                { category: 'sprout_shielded', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed }
              end
            else
              # Pool size detection goes here
              # Python classification is:
              # sapling += 1
              # if tx.value_balance < 0:
              #  sapling_hidden += abs(tx.value_balance)
              # else:
              #  sapling_revealed += tx.value_balance
              # sapling_balance = (sapling_hidden - sapling_revealed) / 100000000
              sapling += 1
              if transaction.valueBalance.negative?
                sapling_hidden += transaction.valueBalance.to_f.abs
              else
                sapling_revealed += transaction.valueBalance.to_f
              end
              { category: 'sapling_shielded', sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed } 
            end
          end
        end
      else
        binding.pry
        return {category: nil, sapling: sapling, sapling_hidden: sapling_hidden, sapling_revealed: sapling_revealed, sprout: sprout, sprout_hidden: sprout_hidden, sprout_revealed: sprout_revealed}
      end
    end
  end