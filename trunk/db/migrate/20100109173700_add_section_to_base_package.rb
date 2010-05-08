class AddSectionToBasePackage < ActiveRecord::Migration
  def self.up
     add_column :base_packages, :section_id, :integer 
  end

  def self.down
    remove_column :base_packages, :section_id
  end
end
