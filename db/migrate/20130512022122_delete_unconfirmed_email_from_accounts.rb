class DeleteUnconfirmedEmailFromAccounts < ActiveRecord::Migration
  def up
    #remove_column :accounts, :unconfirmed_email
  end

  def down
    #add_column :accounts, :unconfirmed_email, :string
  end
end
