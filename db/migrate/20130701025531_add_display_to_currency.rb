class AddDisplayToCurrency < ActiveRecord::Migration
  def change
    add_column :currencies, :display, :string
    
    # update any existing currencies
    Currency.where(:code => 'BTC').update_all(:display => 'BTC$')
    Currency.where(:code => 'BRL').update_all(:display => 'R$')
    Currency.where(:code => 'USD').update_all(:display => '$')
  end
end
