class AddIndexForImportTables < ActiveRecord::Migration
  def self.up
    add_index :import_tables, [:portfolio_id]
  end

  def self.down
    remove_index :import_tables, :column => [:portfolio_id]
  end
end
