class DeviseDbReconciliation < ActiveRecord::Migration
  
  # This file is a product of a reconciliation completed on 30-May-2013 between production/development database and the devise migration generated 12th May.
  
  # Missing columns were added in this migration and removed from devise migration
  
  def up
    
    change_table(:accounts) do |t|
      
      ## Recoverable
      t.datetime :reset_password_sent_at
      
    end
    
  end

  def down
    
    raise ActiveRecord::IrreversibleMigration
    
  end
end
