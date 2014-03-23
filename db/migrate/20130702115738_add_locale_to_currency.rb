class AddLocaleToCurrency < ActiveRecord::Migration
  def change
    add_column :currencies, :pt, :string
    add_column :currencies, :en, :string
    
    # update any existing currencies
    Currency.where(:code => 'BTC').update_all(:pt => 'Bitcoins', :en => 'Bitcoins')
    Currency.where(:code => 'BRL').update_all(:pt => 'Reais', :en => 'Brazilian Real')
    Currency.where(:code => 'USD').update_all(:pt => 'Dollars', :en => 'Dollars')
  end
end
