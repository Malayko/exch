class ChangeStatToDecimal < ActiveRecord::Migration
  def up
    change_column :stats, :volume, :decimal, :precision => 9, :scale => 5
  end

  def down
    change_column :stats, :volume, :integer
  end
end
