class AddBrazBankDetailToBankAccounts < ActiveRecord::Migration
  def up
    add_column :bank_accounts, :ag, :string, :null => false
    add_column :bank_accounts, :cc, :string, :null => false
    add_column :bank_accounts, :cnpj, :string, :null => true
    
    change_column :bank_accounts, :bic, :string, :null => true
    change_column :bank_accounts, :iban, :string, :null => true
    change_column :bank_accounts, :account_holder, :string, :null => false
  end
  
  def down
    remove_column :bank_accounts, :ag, :string
    remove_column :bank_accounts, :cc, :string
    remove_column :bank_accounts, :cnpj, :string
    
    change_column :bank_accounts, :bic, :string, :null => false
    change_column :bank_accounts, :iban, :string, :null => false
    change_column :bank_accounts, :account_holder, :string, :null => true
    
  end
end
