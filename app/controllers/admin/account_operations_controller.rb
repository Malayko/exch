class Admin::AccountOperationsController < Admin::AdminController
  DEPOSIT_COMMISSION_RATE = BigDecimal("0.01")
  
  before_filter :set_label
  
  active_scaffold :account_operation do |config|
    config.actions.exclude :update, :delete
    
    config.columns = [:account, :amount, :currency, :bt_tx_confirmations, :type, :created_at]
    
    config.list.columns = [:created_at, :amount, :currency]
    config.show.columns = [:amount, :currency, :bt_tx_confirmations, :type, :created_at]
    
    config.create.columns = [:amount, :currency]
    
    config.columns[:account].form_ui = :select
  end
    
  def create
    @record = AccountOperation.new
    
    deposit_fee = BigDecimal(params[:record][:amount]) * DEPOSIT_COMMISSION_RATE
    
    if current_user.allowed_currencies.include?(params[:record][:currency].downcase.to_sym)
      Operation.transaction do
        o = Operation.create
      
        @record = AccountOperation.new do |a|
          a.amount = BigDecimal(params[:record][:amount])-deposit_fee
          a.currency = params[:record][:currency]
          a.account_id = params[:user_id]
        end
      
        o.account_operations << @record
      
        o.account_operations << AccountOperation.new do |a|
          a.amount = -BigDecimal(params[:record][:amount])
          a.currency = params[:record][:currency]
          a.account = Account.storage_account_for(params[:record][:currency])
        end
        
        # Charge a fee for deposits
        o.account_operations << AccountOperation.new do |fee|
          fee.currency = params[:record][:currency]
          fee.amount = deposit_fee
          fee.account = Account.storage_account_for(:fees)
        end
        
        o.save!
        
      end
    else
      @record.errors[:base] << t("errors.messages.insufficient_privileges")
      self.successful = false
    end
    
    respond_to_action(:create)
  end
  
  def conditions_for_collection
    ["account_id = ?", params[:user_id]]
  end
  
  def set_label
    account = Account.find(params[:user_id])
    active_scaffold_config.label = "#{account.name} (#{account.email})"
  end
end
