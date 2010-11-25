class CreateQuotes < ActiveRecord::Migration
  def self.up
    create_table :quotes do |t|
      t.integer :security_id
      t.date :date
      t.decimal :open
      t.decimal :close
      t.decimal :low
      t.decimal :high
      t.integer :volume

      t.timestamps
    end
  end

  def self.down
    drop_table :quotes
  end
end
