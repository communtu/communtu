class AddPopcon < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :popcon, :integer
end
    
  def self.down
    remove_column :base_packages, :popcon
  end
end
