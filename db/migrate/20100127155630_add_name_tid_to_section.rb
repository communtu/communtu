class AddNameTidToSection < ActiveRecord::Migration
  def self.up
    add_column :sections, :name_tid, :integer
  end

  def self.down
    remove_column :sections, :name_tid
  end
end
