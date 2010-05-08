class AddNameTidToSection < ActiveRecord::Migration
  def self.up
    add_column :sections, :name_tid, :integer
    remove_column :base_packages, :fullsection_tid
    remove_column :base_packages, :section_tid

  end

  def self.down
    remove_column :sections, :name_tid
  end
end
