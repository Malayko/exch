class Operation < ActiveRecord::Base
  has_many :account_operations, :dependent => :destroy

  validate :check_debit_credit_equality
  
  #before_destroy { self.account_operations.destroy_all }
  
  def check_debit_credit_equality
    # Debit and credit amounts should be equal for *each* currency
    account_operations.map(&:currency).uniq.each do |currency|
      unless account_operations.select{ |ao| ao.currency = currency }.map(&:amount).compact.sum.zero?
        errors[:base] << I18n.t("errors.debit_not_equal_to_credit", :currency => currency)
      end
    end
  end
  
  # for testing
  def sum_currency(currency)
    #account_operations.map(&:currency).uniq.each do |currency|
      puts account_operations.select{ |ao| ao.currency = currency }.map(&:amount).compact.sum
      
      puts account_operations.select{ |ao| ao.currency = currency }.map(&:amount).compact.sum.zero?
    #end
  end
  
  # set all related operations to `cancel` state
  def cancel
    account_operations.each do |op|
      op.cancel
      op.save
    end
  end
  
end
