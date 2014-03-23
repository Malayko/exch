require 'digest'

class PendingTransfer < ActiveRecord::Base
  CURRENCIES = %w{ BTC BRL }
  
  attr_accessible :account, :currency, :type, :state, :op_btc, :op_brl, :op_fees
   
  validates :currency,
    :presence => true,
    :inclusion => { :in => CURRENCIES}

  validates :account,
    :presence => true

end
