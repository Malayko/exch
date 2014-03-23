class Transfer < AccountOperation
  include ActiveRecord::Transitions
  
  DEPOSIT_WITHDRAW_COMMISSION_RATE = BigDecimal("0.01")
  
  before_validation :round_amount,
    :on => :create  
  
  after_create :execute

  validates :amount,
    :numericality => true,
    :user_balance => true,
    :minimal_amount => true,
    :maximal_amount => true,
    :negative => true

  validates :currency,
    :inclusion => { :in => ["BRL", "BTC"] }

  def type_name
    type.gsub(/Transfer$/, "").underscore.gsub(/\_/, " ").titleize
  end

=begin
  state_machine do
    state :pending
    state :processed

    event :process do
      transitions :to => :processed,
        :from => :pending
    end
  end
=end

  # all transfers are withdrawals
  def self.from_params(params)
    transfer = class_for_transfer(params[:currency]).new(params)
   
    if transfer.amount
      transfer.amount = -transfer.amount.abs 
    end
    
    transfer
  end

  def round_amount
    unless amount.nil? || amount.zero?
      self.amount = self.class.round_amount(amount, currency)
    end
  end

  def self.minimal_amount_for(currency, display)
    currency = currency.to_s.downcase.to_sym

    #if [:u, :lreur].include?(currency)
    #  BigDecimal("0.02")
    #if currency == :usd
    #  BigDecimal("100.0")
    
    if currency == :brl
      if display==true
        BigDecimal("100.0")
      else
        BigDecimal("100.0")*(1-DEPOSIT_WITHDRAW_COMMISSION_RATE)
      end
    elsif currency == :btc
      BigDecimal("0.01")
    else
      raise RuntimeError.new("Invalid currency")
    end
  end  

  def self.round_amount(amount, currency)
    currency = currency.to_s.downcase.to_sym
    amount = amount.to_f if amount.is_a?(Fixnum)
    amount.to_d.round(8, BigDecimal::ROUND_DOWN)
  end
  
  def self.class_for_transfer(currency)
    
    puts currency
    
    currency = currency.to_s.downcase.to_sym

    #if [:usd, :brl].include?(currency)
    if [:brl].include?(currency)
      WireTransfer
    #elsif [:lrusd, :lreur].include?(currency)
    #  LibertyReserveTransfer
    elsif currency == :btc
      BitcoinTransfer
    else
      raise RuntimeError.new("Invalid currency")
    end
  end
end