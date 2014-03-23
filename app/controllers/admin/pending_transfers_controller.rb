class Admin::PendingTransfersController < Admin::AdminController
  
  active_scaffold :account_operation do |config|
    config.actions = [:list, :show, :nested]
    
    config.columns = [
      :id,
      :account,
      :amount,
      :currency,
      :type,
      :created_at,
      :address,
      :attachment
    ]
    
    config.columns << [:admincp_withdrawal_after_fee, :admincp_deposit_before_fee]
    config.columns[:admincp_withdrawal_after_fee].label = 'Withdrawal After Fee'
    config.columns[:admincp_deposit_before_fee].label = 'Deposit Before Fee'
    
    config.action_links.add 'process_tx', 
      :label => 'Mark processed', 
      :type => :member, 
      :method => :post,
      :position => false
      
    config.action_links.add 'cancel_tx', 
      :label => 'Cancel', 
      :type => :member, 
      :method => :post,
      :position => false,
      :confirm => "Are you sure?"
      #:dhtml_confirm => DHTMLConfirm.new
        #ModalboxConfirm.new
    
    #config.nested.add_link(:bank_account, :label => "Bank Account", :page => true) 
    
    #config.list.hide_nested_column = true
    
  end
  
  
  def conditions_for_collection
    # only show deposits & withdrawals
    ["state = 'pending' AND currency IN (#{current_user.allowed_currencies.map { |c| "'#{c.to_s.upcase}'" }.join(",")},'BTC') AND type IN ('Deposit', 'WireTransfer', 'BitcoinTransfer')"]
  end
  
  def process_tx
    Deposit;Transfer;WireTransfer;BitcoinTransfer
    
    @record = AccountOperation.where("currency IN (#{current_user.allowed_currencies.map { |c| "'#{c.to_s.upcase}'" }.join(",")},'BTC')").
      find(params[:id])
    
    @record.process!
    
    if @record.type == "BitcoinTransfer"
      @record.execute
    end
    
    if @record.type == "Transfer" || @record.type == "WireTransfer" 
      UserMailer.withdrawal_processed_notification(@record).deliver
    end
    
    if @record.type == "Deposit"
      UserMailer.deposit_processed_notification(@record).deliver
    end
      
    render :template => 'admin/pending_transfers/process_tx'
  end
  
  def cancel_tx
    @record = AccountOperation.where("currency IN (#{current_user.allowed_currencies.map { |c| "'#{c.to_s.upcase}'" }.join(",")},'BTC')").
      find(params[:id])
    
    # time-saving advice: already tried putting this in the various models.. it didn't work
    #@record.operation.account_operations.destroy_all
    
    # don't delete -> just set all account_operations to cancel
    #@record.operation.account_operations.
    
    # cancel each account operation
    #@record.operation.account_operations.each do |op|
    #  debugger
    #  op.cancel
    #end
    @record.operation.cancel
    
    render :template => 'admin/pending_transfers/process_tx'
  end
end
