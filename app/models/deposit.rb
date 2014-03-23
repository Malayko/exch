class Deposit < AccountOperation 
  include ActionView::Helpers::NumberHelper
  include ActiveRecord::Transitions
  
  DEPOSIT_COMMISSION_RATE = BigDecimal("0.01")
  
  attr_accessible :bank_account_id, :bank_account_attributes

  belongs_to :account
  
  #accepts_nested_attributes_for :bank_account
  
  #before_validation :check_bank_account_id

  validates :currency,
    :inclusion => { :in => ["BRL"] }
  
  validates :amount,
    :numericality => true,
    :minimal_amount => true
    #:negative => false

=begin  
  state_machine do
    state :pending
    state :processed
    state :cancelled
    
    event :process do
      transitions :to => :processed,
        :from => :pending
    end
    
    event :cancel do
      transitions :to => :cancelled,
        :from => :pending
    end
    
  end
=end

  def self.from_params(params)
    deposit = class_for_transfer(params[:currency]).new(params)
   
    if deposit.amount
      deposit.amount = deposit.amount.abs 
    end
    
    deposit
  end
  
  def self.class_for_transfer(currency)
    currency = currency.to_s.downcase.to_sym
    self
  end
  
  def execute
    
    raise 'executing'
    
  end

  def check_bank_account_id
    if bank_account_id && account.bank_accounts.find(bank_account_id).blank?
      raise "Someone is trying to pull something fishy off"
    end
  end
  
  
  
end
