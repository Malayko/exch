module DepositsHelper
  def color_for(deposit)
    deposit.amount > 0 ? (deposit.confirmed? ? "green" : "unconfirmed") : "red"
  end

  def confirmation_tooltip_for(deposit)
    unless deposit.confirmed?
      t :confirmations_left, :count => (Transfer::MIN_BTC_CONFIRMATIONS - deposit.bt_tx_confirmations)
    end
  end
  
  def deposit_details(deposit)
    link_to(image_tag("details.png", :alt => t(".details"), :title => t(".details")), account_deposit_path(deposit))
  end
  
  def deposit_state(state, options = {})   
    content_tag :span,
      :class => ["deposit-state", color_for_deposit_state(state)] do
      "#{options[:icon] ? image_tag("#{state}.png", :class => "state-icon") : ""} #{options[:message]}".strip.html_safe
    end
  end
  
  def color_for_deposit_state(state)
    case state 
    when "pending"
      "orange"
    when "processed"
      "green"
    end
  end
  
  def get_deposit_account
    bank_account = YAML::load(File.open(File.join(Rails.root, "config", "banks.yml")))
    
    if bank_account
      bank_account = bank_account[Rails.env]
      @ag = bank_account["ag"]
      @cc = bank_account["cc"]
      @cnpj = bank_account["cnpj"]
      @bic = bank_account["bic"]
      @iban = bank_account["iban"]
      @bank = bank_account["bank"]
      @bank_address = bank_account["bank_address"]
      @account_holder = bank_account["account_holder"]
      @account_holder_address = bank_account["account_holder_address"]
    end
    
    #@user = current_user
    
  end
end
