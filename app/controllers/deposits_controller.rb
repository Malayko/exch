class DepositsController < ApplicationController
  include DepositsHelper
  
  DEPOSIT_COMMISSION_RATE = BigDecimal("0.01")
  
  respond_to :html, :json
  
  def new
    
    @bank_account = BankAccount.new
    
    #debugger
    
    @currencies_deposit = Currency.where('code != ?', "btc")
    
    @deposit_rate = DEPOSIT_COMMISSION_RATE
    
    @pending_deposits = Deposit.where(:account_id => current_user.id, :state => "pending")
    
    #default currency
    if params[:currency].nil?
      currency = "BRL"
    else
      currency = params[:currency]
    end
    
    if ["BRL"].include? currency
      @deposit = Deposit.new(:currency => params[:currency])
    end
    
    get_deposit_account
    
  end
  
  def create
    
    @bank_account = BankAccount.new
    
    @currencies_deposit = Currency.where('code != ?', "btc")
    
    @deposit_rate = DEPOSIT_COMMISSION_RATE
    
    @pending_deposits = Deposit.where(:account_id => current_user.id, :state => "pending")
    
    @deposit = Deposit.from_params(params[:deposit])
    
    @deposit.account = current_user
    
    @account_id = current_user.name
    
    # Calculate fee for deposits
    deposit_fee = @deposit.amount * DEPOSIT_COMMISSION_RATE
      
    storage_amount = @deposit.amount
    
    @deposit.amount = @deposit.amount - deposit_fee
    
    Operation.transaction do

      o = Operation.create!
      o.account_operations << @deposit
      
      o.account_operations << AccountOperation.new do |ao|
        ao.amount = (storage_amount * -1)
        ao.currency = @deposit.currency
        ao.account = Account.storage_account_for(@deposit.currency)
      end
      
      # Charge a fee for depoists
      o.account_operations << AccountOperation.new do |fee|
        fee.currency = @deposit.currency
        fee.amount = deposit_fee
        fee.account = Account.storage_account_for(:fees)
      end
           
      raise(ActiveRecord::Rollback) unless o.save
    end
    
    unless @deposit.new_record?
      
      get_deposit_account
      
      calc_before_after_fee(@deposit)
      
      @user = current_user
      
      # dispatch email to user
      UserMailer.deposit_request_notification(@deposit).deliver
      
      respond_with do |format|
        format.html { render :action => "show" }
        format.json { render :json => @deposit }
      end
    else
      render :action => :new
    end
  end
  
  def show
    
    @deposit = Deposit.find(params[:id])
    
    calc_before_after_fee(@deposit)
    
    get_deposit_account
    
    @user = current_user
    
  end
  
  def destroy
    
    Deposit.where(:id => params[:id], :account_id => current_user.id).first.destroy

    redirect_to new_account_deposit_path,
      :notice => t(".deposits.destroy.deposit_deleted")
  end
  
  def update
    deposit = Deposit.where(:id => params[:id], :account_id => current_user.id).first
    
    deposit.attachment = params[:deposit][:attachment]
    
    if deposit.save
      redirect_to account_deposit_path,
      :notice => t(".deposits.update.deposit_file_added")
    else
      redirect_to account_deposit_path,
      :notice => t(".deposits.update.error")
    end
    
  end
  
  protected
  
  def fetch_bank_accounts
    @bank_accounts = current_user.bank_accounts.map { |ba| [ba.bank_name + " : " + ba.ag + " / " + ba.cc, ba.id] }
  end
  
  def calc_before_after_fee(deposit)
    
    @deposit_beforefee = '%.0f' % (deposit.amount * (1 + DEPOSIT_COMMISSION_RATE)) 
    
    @deposit_afterfee =  '%.0f' % deposit.amount
    
  end
  
end
