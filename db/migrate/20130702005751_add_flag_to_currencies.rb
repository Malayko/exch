class AddFlagToCurrencies < ActiveRecord::Migration
  def change
    add_column :currencies, :flag, :string
    
    # update any existing currencies
    Currency.where(:code => 'BTC').update_all(:flag => '')
    Currency.where(:code => 'BRL').update_all(:flag => 'pt')
    Currency.where(:code => 'USD').update_all(:flag => 'en')
  end
end
