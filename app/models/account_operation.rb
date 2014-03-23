require 'digest'

class AccountOperation < ActiveRecord::Base
  include ActiveRecord::Transitions
  include ActionView::Helpers::NumberHelper
  
  CURRENCIES = %w{ BTC BRL }
  MIN_BTC_CONFIRMATIONS = 3
  
  WITHDRAWAL_COMMISSION_RATE = BigDecimal("0.01")
  DEPOSIT_COMMISSION_RATE = BigDecimal("0.01")
  
  default_scope order('`account_operations`.`created_at` DESC')
  
  #for attachments
  has_attached_file :attachment, :styles => {:original => "75x75#"}
  validates_attachment_content_type :attachment, :content_type => ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'application/pdf']

  belongs_to :operation
  
  belongs_to :account
  
  after_create :refresh_orders,
    :refresh_account_address
  
  attr_accessible :amount, :currency
   
  validates :amount,
    :presence => true,
    :user_balance => true
  
  validates :currency,
    :presence => true,
    :inclusion => { :in => CURRENCIES}

  validates :account,
    :presence => true

  validates :operation, 
    :presence => true
  
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
    
  scope :with_processed_active_deposits_only, where("((type IS NULL) OR (type='Deposit' AND state<>'pending' AND state<>'cancelled') OR (type<>'Deposit'))")
    
  scope :with_currency, lambda { |currency|
    where("account_operations.currency = ?", currency.to_s.upcase)
  }

  scope :with_confirmations, lambda { |unconfirmed|
    unless unconfirmed
      where("currency <> 'BTC' OR bt_tx_confirmations >= ? OR amount <= 0 OR bt_tx_id IS NULL", MIN_BTC_CONFIRMATIONS)
    end
  }
  
  #after_destroy :destroy_fellow_account_operations
  
  #def destroy_fellow_account_operations
    # our destroy operation, is to destroy the operation for this account_operation
    # that will in turn destroy this AO, with all the other AO's as well
    #operation.account_operations.delete_all
  #end
  
  def to_label
    "#{I18n.t("activerecord.models.account_operation.one")} no #{id}"
  end
  
  def refresh_orders
    if account.is_a?(User)
      account.reload.trade_orders.each { |t|
        if t.is_a?(LimitOrder)
          t.inactivate_if_needed!
        else
          if ((t.selling? and currency == "BTC") or (t.buying? and t.currency == currency)) and t.is_a?(MarketOrder) and amount > 0
            t.execute!
          end
        end
      }
    end
  end

  def confirmed?
    bt_tx_id.nil? or (amount < 0) or (bt_tx_confirmations >= MIN_BTC_CONFIRMATIONS)
  end

  def refresh_account_address
    account.generate_new_address if bt_tx_id
  end

  def self.synchronize_transactions!
    Account.all.each do |a|
      transactions = Bitcoin::Client.instance.list_transactions(a.id.to_s)

      transactions = transactions.select do |tx|
        ["receive", "generated"].include? tx["category"]
      end

      transactions.each do |tx|
        t = AccountOperation.find(
          :first,
          :conditions => ['bt_tx_id = ? AND account_id = ?', tx["txid"], a.id]
        )

        if t
          t.update_attribute(:bt_tx_confirmations, tx["confirmations"])
        else
          Operation.transaction do
            o = Operation.create!

            o.account_operations << AccountOperation.new do |bt|
              bt.account_id = a.id
              bt.amount = tx["amount"]
              bt.bt_tx_id = tx["txid"]
              bt.bt_tx_confirmations = tx["confirmations"]
              bt.currency = "BTC"
            end

            o.account_operations << AccountOperation.new do |ao|
              ao.account = Account.storage_account_for(:btc)
              ao.amount = -tx["amount"].abs
              ao.currency = "BTC"
            end

            o.save!

            a.generate_new_address
          end
        end
      end
    end
  end
  
  # Should the transaction be highlighted in some way ?
  def unread
    account && (id > account.max_read_tx_id)
  end
  
  # Extra confirmations this account operation requires to be considered confirmed
  def required_confirmations
    (MIN_BTC_CONFIRMATIONS - bt_tx_confirmations) unless confirmed?
  end
  
  # withdrawal & deposit operations
  def deposit_after_fee
    if (type=='Deposit')
      if self.amount > 0
        # fee already deducted
        number_to_currency(self.amount , unit: "", separator: ".", delimiter: ',', precision: 3)
      end
    end
  end
  
  def deposit_before_fee
    rounded = '%.0f' % (amount * (1 + DEPOSIT_COMMISSION_RATE))
    number_to_currency(rounded , unit: "", separator: ".", delimiter: ',', precision: 3)
  end
  
  def admincp_deposit_before_fee
    if (type=='Deposit')
      deposit_before_fee
    end
  end
  
  def admincp_withdrawal_after_fee
    if (type=='Withdrawal' || type=='WireTransfer' || type=='BitcoinTransfer')
      if type=='BitcoinTransfer'
        return self.amount
      elsif self.amount < 0
        # deduct fee
        number_to_currency((1-WITHDRAWAL_COMMISSION_RATE)*self.amount, unit: "", separator: ".", delimiter: ',', precision: 3)
      else
        number_to_currency(self.amount, unit: "", separator: ".", delimiter: ',', precision: 3)
      end
    end
  end
  
  def as_json(options={})    
    super(options.merge(
        :only => [
          :id, :address, :email, :amount, :currency, :bt_tx_confirmations, :bt_tx_id, :comment, :created_at
        ],
        :methods => [
          :unread,
          :confirmed?,
          :required_confirmations
        ]
      )
    )
  end
end
