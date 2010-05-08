class RemoveDist < ActiveRecord::Migration
  def self.up
#    remove_column :base_packages, :distribution_id
  drop_table :temp_metacontents
  drop_table :temp_metapackages
  remove_column :comments, :temp_metapackage_id
  add_column :base_packages, :default_install, :boolean
  add_column :package_distrs, :version, :string
end
    
  def self.down
  end
end
