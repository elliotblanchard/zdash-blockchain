module Classify
    def Classify.classify_transaction(transaction)
      # Some example transaction hashes:
      # d456a889ddc87ad41e379de5bb245781333fd883b67bf34eebabd1a6fb7e144a
      # d2ebc0cfd864027eb0887e1dcb772b4d1ca7bc016504889a6843583c2ca73bb4
      # f0d27409c193fef51b66a922794583f08c880ab220229c813995143e1cd244d5
      # c13632d045a685dfead48b62ceb8d0adb188fef9e3f902c65112a88a4dbed4fe
      
      if transaction
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
                'shielded_coinbase'
              else
                'transparent_coinbase'
              end
            else
              'transparent_coinbase'
            end
          else
            if transaction.vout.length > 2
              'transparent'
            else
              if transaction.vjoinsplit.length > 2
                'sprout_shielding'
              else
                'sapling_shielding'
              end
            end
          end
        else
          if transaction.vout.length > 2
            if transaction.vjoinsplit.length > 2
              'sprout_deshielding'
            else
              'sapling_deshielding'
            end
          else
            if transaction.vjoinsplit.length > 2
              if ( transaction.vShieldedOutput && (transaction.vShieldedOutput.length > 2) )
                'migration'
              else
                'sprout_shielded'
              end
            else
              'sapling_shielded'
            end
          end
        end
      else
        binding.pry
        nil
      end
    end
  end