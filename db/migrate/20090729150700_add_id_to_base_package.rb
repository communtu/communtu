class AddIdToBasePackage < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :description_tid, :integer
    add_column :base_packages, :url_tid, :integer
    add_column :base_packages, :fullsection_tid, :integer
    add_column :base_packages, :section_tid, :integer 
  end

  def self.down
    remove_column :base_packages, :description_tid
    remove_column :base_packages, :url_tid
    remove_column :base_packages, :fullsection_tid
    remove_column :base_packages, :section_tid
  end
end
