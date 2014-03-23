class AccountsController < ApplicationController
  respond_to :html, :json
  
  def show
    @balances = Currency.all.map(&:code).inject({}) do |acc, code|
      acc[code] = current_user.balance(code.downcase.to_sym)
      acc
    end
    
    @balances["ADDRESS"] = current_user.bitcoin_address
    @balances["UNCONFIRMED_BTC"] = current_user.balance(:btc, :unconfirmed => true) - current_user.balance(:btc)
    
    respond_with @balances
  end
  
  def balance
    @balance = {
      :balance => @current_user.balance(params[:currency]),
      :currency => params[:currency].upcase
    }
    
    if params[:currency] == 'btc'
      @balance[:unconfirmed] = current_user.balance(:btc, :unconfirmed => true) - current_user.balance(:btc)
    end
    
    respond_with @balance
  end
  
  def deposit
  end
  
#  def pecunix_deposit_form
#    @amount = params[:amount]
#    @payment_id = current_user.id
#    @config = YAML::load(File.read(File.join(Rails.root, "config", "pecunix.yml")))[Rails.env]
#    @hash = Digest::SHA1.hexdigest("#{@config['account']}:#{@amount}:GAU:#{@payment_id}:PAYEE:#{@config['secret']}").upcase
#  end
end
