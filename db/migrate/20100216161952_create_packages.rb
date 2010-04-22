class CreatePackages < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :p_vote, :integer
    add_column :base_packages, :p_old, :integer
    add_column :base_packages, :p_recent, :integer
    add_column :base_packages, :p_nofiles, :integer
    
  end

  def self.down
    remove_column :base_packages, :p_vote
    remove_column :base_packages, :p_old
    remove_column :base_packages, :p_recent
    remove_column :base_packages, :p_nofiles
  end
end
