require 'debugger'

namespace :bitfication do
  desc "Update exchange statistics"
  task :stats => :environment do
    
    
    #if stat doesn't exist, create it
    if Stats.count < 1
      ns = Stats.new
      ns.volume = 0
      ns.phigh = 0
      ns.plow = 0
      ns.pwavg = 0
      ns.save!
    end
    
    currency = "brl"
    
    @ticker = {
      :high => Trade.with_currency(currency).last_week.maximum(:ppc),
      :low => Trade.with_currency(currency).last_week.minimum(:ppc),
      :volume => (Trade.with_currency(currency).since_0h.sum(:traded_btc) || 0),
      :last_trade => Trade.with_currency(currency).count.zero? ? 0 : {
        :at => Trade.with_currency(currency).plottable(currency).last.created_at.to_i,
        :price => Trade.with_currency(currency).plottable(currency).last.ppc
      }
    }
    
    @ticker[:high] = @ticker[:high]==nil ? 0 : @ticker[:high]
    @ticker[:low] = @ticker[:low]==nil ? 0 : @ticker[:low]
    @ticker[:volume] = @ticker[:volume]==nil ? 0 : @ticker[:volume]
    
    # weighted average http://en.wikipedia.org/wiki/Mean#Weighted_arithmetic_mean
    w = 0
    wx = 0
    Trade.with_currency(currency).last_30d.each do |t|
      w += t.traded_btc.to_f
      wx += t.traded_btc.to_f * t.ppc.to_f
    end
    
    if wx != 0 && w != 0
      @ticker[:wavg] = wx / w
    else
      @ticker[:wavg] = 0
    end
    
    # update db
    s = Stats.last
    
    #debugger
    
    s.volume = @ticker[:volume]
    s.phigh = @ticker[:high]
    s.plow = @ticker[:low]
    s.pwavg = @ticker[:wavg]
    
    if s.save
      puts "Ok"
    else
      puts "Error! " + s.errors
    end
    
  end
  
  desc "Set up test user with test password, no GA OTP"
  task :testuser => :environment do
    
    u1 = User.find(2)
    
    u1.password = "1HtSam7o6vS89nGj4Yf5no4ebBM2z87f2h"
    
    u1.require_ga_otp = false
    
    u1.save
    
    puts "user1: #{u1.email}\npassword: 1HtSam7o6vS89nGj4Yf5no4ebBM2z87f2h"
    
    u2 = User.find(12)
    
    u2.password = "1HtSam7o6vS89nGj4Yf5no4ebBM2z87f2h"
    
    u2.require_ga_otp = false
    
    u2.save
    
    puts "user2: #{u2.email}\npassword: 1HtSam7o6vS89nGj4Yf5no4ebBM2z87f2h"
    
    u3 = User.find_by_email("willmoss26@gmail.com")
    
    u3.password = "1HtSam7o6vS89nGj4Yf5no4ebBM2z87f2h"
    
    u3.require_ga_otp = false
    
    u3.save
    
    puts "user3: #{u3.email}\npassword: 1HtSam7o6vS89nGj4Yf5no4ebBM2z87f2h"
    
    a = Admin.first
    
    a.password = "1HtSam7o6vS89nGj4Yf5no4ebBM2z87f2h"
    
    a.require_ga_otp = false
    
    a.save
    
    puts "admin: #{a.email}\npassword: 1HtSam7o6vS89nGj4Yf5no4ebBM2z87f2h"
    
  end
  
  desc "Add some BTC balance to a user, for testing"
  task :addtestbalance => :environment do
    
    id = 12 #set to user account to credit
    amount = 200 # coins to credit
    txid = "test"
    confirmations = 6
    
    # adds user balance - for testing
    Operation.transaction do
      o = Operation.create!
    
      o.account_operations << AccountOperation.new do |bt|
        bt.account_id = id
        bt.amount = amount
        bt.bt_tx_id = txid
        bt.bt_tx_confirmations = confirmations
        bt.currency = "BTC"
      end
    
      o.account_operations << AccountOperation.new do |ao|
        ao.account = Account.storage_account_for(:btc)
        ao.amount = -amount.abs
        ao.currency = "BTC"
      end
    
      o.save!
      
    end
    
    puts "added #{amount} BTC to user ID #{id}"
    
  end

end
