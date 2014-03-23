class AddStats < ActiveRecord::Migration
  def change
    create_table :stats do |t|
      t.integer :volume
      t.decimal :phigh, :precision => 9, :scale => 5
      t.decimal :plow, :precision => 9, :scale => 5
      t.decimal :pwavg, :precision => 9, :scale => 5
    end
  end
end
