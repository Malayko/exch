class AddAttachmentColumnsToDeposits < ActiveRecord::Migration
  def self.up
    add_attachment :account_operations, :attachment
  end

  def self.down
    remove_attachment :account_operations, :attachment
  end
end
