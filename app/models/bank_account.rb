class BankAccount < ActiveRecord::Base
  include ActiveRecord::Transitions

  attr_accessible :ag, :cc, :cnpj, :account_holder, :bank_name

  belongs_to :user

  has_many :wire_transfers
  has_many :account_operations

  #validates :bic,
  #  :presence => true,
  #  :format => { :with => /[A-Z]{6}[A-Z0-9]{2}[A-Z0-9]{0,3}/ }

  #validates :iban,
  #  :presence => true,
  #  :iban => true
  
  validates :bank_name,
    :presence => true

  validates :ag,
    :presence => true
    
  validates :cc,
    :presence => true
  
  validates :account_holder,
    :presence => true

  state_machine do
    state :unverified
    state :verified

    event :verify do
      transitions :to => :verified, :from => :unverified
    end
  end

  #def iban
  #  IBANTools::IBAN.new(super).prettify
  #end

  def to_label
    iban
  end
end
