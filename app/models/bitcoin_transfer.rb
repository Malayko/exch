class BitcoinTransfer < Transfer
  WITHDRAW_COMMISSION_RATE = BigDecimal("0.01")
  
  attr_accessible :address

  validates :address,
    :bitcoin_address => true,
    :not_mine => true,
    :presence => true

  validates :currency,
    :inclusion => { :in => ["BTC"] }

  def address=(a)
    self[:address] = a.strip
  end

  def execute
    # TODO : Implement instant internal transfer
    
    # If admin has confirmed & coins available in wallet
    #debugger
    if bt_tx_id.blank? && processed? && (Bitcoin::Client.instance.get_balance >= amount.abs)
      update_attribute(:bt_tx_id, Bitcoin::Client.instance.send_to_address(address, amount.abs))
      process!
    end    
    
  end
  
  def withdrawal_after_fee
    
    self.amount
    
  end
  
  def deposit_after_fee
    
    self.amount
    
  end
end

