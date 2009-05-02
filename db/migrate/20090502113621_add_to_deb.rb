class AddToDeb < ActiveRecord::Migration
  def self.up
    add_column :debs, :log, :text
  end

  def self.down
    remove_column :debs, :log
  end
end
